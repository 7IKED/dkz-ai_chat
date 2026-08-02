#!/usr/bin/env python3
"""Scan Claude Code session logs and correlate them with git history.

Reads the JSONL transcripts Claude Code writes under ~/.claude/projects/<slug>/<sessionId>.jsonl
and emits a data file consumed by session-monitor/index.html.

Output is written as JavaScript (window.DKZ_SESSIONS = {...}) rather than plain JSON so the
viewer also works when opened directly via file:// — a fetch() of a local .json is blocked by
the browser's same-origin policy, a <script src> is not.

Usage:
    python3 scripts/scan-claude-sessions.py [--claude-root ~/.claude] [--out session-monitor/sessions-data.js]
"""

import argparse
import json
import os
import subprocess
import sys
from collections import Counter
from datetime import datetime
from pathlib import Path

# Token fields Claude Code records per assistant message. Only flat integers are summed;
# `usage` also carries nested objects (cache_creation) and strings (service_tier) that are not counts.
TOKEN_FIELDS = (
    "input_tokens",
    "output_tokens",
    "cache_read_input_tokens",
    "cache_creation_input_tokens",
)


def parse_ts(value):
    """Parse an ISO-8601 timestamp; returns None when absent or malformed."""
    if not value:
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except (ValueError, AttributeError):
        return None


def iter_records(path):
    """Yield decoded JSON objects from a JSONL file, skipping unparsable lines.

    Transcripts are appended to while a session runs, so the final line can be a partial write.
    """
    with open(path, "r", encoding="utf-8", errors="replace") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            try:
                yield json.loads(line)
            except json.JSONDecodeError:
                continue


def blank_session(session_id):
    return {
        "id": session_id,
        "cwd": None,
        "branch": None,
        "file": None,
        "start": None,
        "end": None,
        "version": None,
        "models": set(),
        "tools": Counter(),
        "types": Counter(),
        "tokens": Counter(),
        "errors": [],
        "sidechain": 0,
        "userTurns": 0,
        "assistantTurns": 0,
        "firstPrompt": None,
    }


def text_of(content):
    """Flatten a message content field (string, or list of typed blocks) to plain text."""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts = []
        for block in content:
            if isinstance(block, dict) and block.get("type") == "text":
                parts.append(block.get("text", ""))
        return " ".join(parts)
    return ""


def scan_sessions(claude_root):
    """Build one aggregated record per sessionId across all project transcripts."""
    projects_dir = Path(claude_root) / "projects"
    sessions = {}
    if not projects_dir.is_dir():
        return sessions

    for path in sorted(projects_dir.glob("*/*.jsonl")):
        for record in iter_records(path):
            session_id = record.get("sessionId")
            if not session_id:
                continue

            session = sessions.setdefault(session_id, blank_session(session_id))
            session["file"] = str(path)
            session["types"][record.get("type", "unknown")] += 1

            for key, field in (("cwd", "cwd"), ("gitBranch", "branch"), ("version", "version")):
                if record.get(key):
                    session[field] = record[key]

            stamp = parse_ts(record.get("timestamp"))
            if stamp:
                if session["start"] is None or stamp < session["start"]:
                    session["start"] = stamp
                if session["end"] is None or stamp > session["end"]:
                    session["end"] = stamp

            if record.get("isSidechain"):
                session["sidechain"] += 1

            if record.get("isApiErrorMessage"):
                session["errors"].append(
                    {
                        "status": record.get("apiErrorStatus"),
                        "at": record.get("timestamp"),
                    }
                )

            message = record.get("message")
            if not isinstance(message, dict):
                continue

            role = message.get("role")
            # isMeta marks injected context (system reminders, hook output), not a real user turn.
            if role == "user" and not record.get("isMeta"):
                session["userTurns"] += 1
                if session["firstPrompt"] is None:
                    prompt = text_of(message.get("content")).strip()
                    if prompt:
                        session["firstPrompt"] = prompt[:220]
            elif role == "assistant":
                session["assistantTurns"] += 1

            model = message.get("model")
            if model and model != "<synthetic>":
                session["models"].add(model)

            usage = message.get("usage")
            if isinstance(usage, dict):
                for field in TOKEN_FIELDS:
                    value = usage.get(field)
                    if isinstance(value, int):
                        session["tokens"][field] += value

            content = message.get("content")
            if isinstance(content, list):
                for block in content:
                    if isinstance(block, dict) and block.get("type") == "tool_use":
                        session["tools"][block.get("name", "unknown")] += 1

    return sessions


def git(repo, *args):
    """Run a git command in `repo`; returns stdout, or '' when git fails or is unavailable."""
    try:
        result = subprocess.run(
            ("git", "-C", str(repo)) + args,
            capture_output=True,
            text=True,
            timeout=20,
        )
    except (OSError, subprocess.SubprocessError):
        return ""
    return result.stdout if result.returncode == 0 else ""


def scan_git(repo, max_commits=200):
    """Collect branches and a bounded commit graph for one repository."""
    if not git(repo, "rev-parse", "--git-dir").strip():
        return None

    branches = []
    for line in git(
        repo,
        "for-each-ref",
        "--format=%(refname:short)%09%(objectname:short)%09%(committerdate:iso-strict)",
        "refs/heads",
    ).splitlines():
        parts = line.split("\t")
        if len(parts) == 3:
            branches.append({"name": parts[0], "head": parts[1], "date": parts[2]})

    commits = []
    separator = "\x1f"
    log_format = separator.join(["%h", "%p", "%an", "%aI", "%s", "%D"])
    for line in git(
        repo,
        "log",
        "--all",
        "--date-order",
        f"--max-count={max_commits}",
        f"--pretty=format:{log_format}",
    ).splitlines():
        fields = line.split(separator)
        if len(fields) != 6:
            continue
        sha, parents, author, date, subject, refs = fields
        commits.append(
            {
                "sha": sha,
                "parents": parents.split() if parents else [],
                "author": author,
                "date": date,
                "subject": subject,
                "refs": [r.strip() for r in refs.split(",") if r.strip()],
            }
        )

    return {
        "path": str(repo),
        "name": Path(repo).name,
        "current": git(repo, "rev-parse", "--abbrev-ref", "HEAD").strip() or None,
        "branches": branches,
        "commits": commits,
    }


def overlaps(a, b):
    """True when two sessions were active at the same time (i.e. ran in parallel)."""
    if not (a["start"] and a["end"] and b["start"] and b["end"]):
        return False
    return a["start"] <= b["end"] and b["start"] <= a["end"]


def serialize(session):
    duration = None
    if session["start"] and session["end"]:
        duration = round((session["end"] - session["start"]).total_seconds())
    return {
        "id": session["id"],
        "short": session["id"][:8],
        "cwd": session["cwd"],
        "project": Path(session["cwd"]).name if session["cwd"] else None,
        "branch": session["branch"],
        "start": session["start"].isoformat() if session["start"] else None,
        "end": session["end"].isoformat() if session["end"] else None,
        "durationSec": duration,
        "version": session["version"],
        "models": sorted(session["models"]),
        "tools": dict(session["tools"].most_common()),
        "types": dict(session["types"]),
        "tokens": dict(session["tokens"]),
        "totalTokens": sum(session["tokens"].values()),
        "errors": session["errors"],
        "sidechain": session["sidechain"],
        "userTurns": session["userTurns"],
        "assistantTurns": session["assistantTurns"],
        "firstPrompt": session["firstPrompt"],
        "parallelWith": session.get("parallelWith", []),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--claude-root", default=os.path.expanduser("~/.claude"))
    parser.add_argument("--out", default="session-monitor/sessions-data.js")
    parser.add_argument("--json", dest="json_out", default=None, help="also write raw JSON here")
    parser.add_argument("--repo", action="append", default=[], help="extra repo path to include (repeatable)")
    args = parser.parse_args()

    sessions = scan_sessions(args.claude_root)
    if not sessions:
        print(f"No session transcripts found under {args.claude_root}/projects", file=sys.stderr)

    ordered = sorted(sessions.values(), key=lambda s: s["start"] or datetime.max.replace(tzinfo=None))
    for session in ordered:
        session["parallelWith"] = [
            other["id"][:8]
            for other in ordered
            if other["id"] != session["id"] and overlaps(session, other)
        ]

    repo_paths = {s["cwd"] for s in ordered if s["cwd"]}
    repo_paths.update(args.repo)
    repos = [r for r in (scan_git(p) for p in sorted(repo_paths)) if r]

    payload = {
        "generatedAt": datetime.now().astimezone().isoformat(),
        "claudeRoot": args.claude_root,
        "sessions": [serialize(s) for s in ordered],
        "repos": repos,
    }

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    body = json.dumps(payload, indent=2, ensure_ascii=False)
    out_path.write_text(
        "// Generated by scripts/scan-claude-sessions.py — do not edit by hand.\n"
        f"window.DKZ_SESSIONS = {body};\n",
        encoding="utf-8",
    )

    if args.json_out:
        Path(args.json_out).write_text(body + "\n", encoding="utf-8")

    parallel = sum(1 for s in payload["sessions"] if s["parallelWith"])
    errors = sum(len(s["errors"]) for s in payload["sessions"])
    print(
        f"{len(payload['sessions'])} session(s), {len(repos)} repo(s), "
        f"{parallel} with parallel overlap, {errors} API error(s) -> {out_path}"
    )


if __name__ == "__main__":
    main()
