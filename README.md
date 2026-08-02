# 💬 AI Chat

> 🤖 AI & Chat | DEVKiTZ™ Ecosystem

---

## 📦 Installation

```bash
# Repository klonen
git clone https://github.com/7IKED/dkz-ai_chat.git
cd dkz-ai_chat

# Direkt im Browser oeffnen (kein Build-Schritt noetig!)
open index.html
# oder
start index.html    # Windows
```

> 💡 **Kein `npm install` noetig!** Dieses Modul ist reines Vanilla JS und laeuft direkt im Browser.

## ✨ Features

- 🎨 **Glassmorphism UI** — DkZ Design System v2
- 📱 **Responsive** — Desktop + Mobile
- 🌙 **Dark Mode** — Standardmaessig dunkel
- ⚡ **Vanilla JS** — Kein Framework, pure Performance
- 🔗 **DkZ Integration** — NanoBot, Copilot, NavBar

## 🛠️ Tech Stack

| Technologie | Details |
|:-----------|:--------|
| Frontend | HTML5, CSS3, JavaScript ES6+ |
| Design | DkZ Design System v2, CSS Custom Properties |
| Fonts | Inter (UI) + JetBrains Mono (Code) |
| Framework | Keines (Vanilla JS) |
| Integration | DkZ Shared Scripts (NavBar, Copilot, Guide) |

## 📁 Struktur

```
dkz-ai_chat/
├── index.html                      # Hauptseite (Multi-Provider Chat)
├── chat_version_1/                 # Chat UI v1
├── chat_version_2/                 # Chat UI v2
├── dkz-webhook-agents.js           # Webhook-Agenten
├── session-monitor/                # 🛰️ Claude Session Monitor
│   ├── index.html                  #    Viewer (Zeitachse + Git-Graph)
│   └── README.md                   #    Doku
├── scripts/
│   └── scan-claude-sessions.py     #    Scanner fuer ~/.claude Transkripte
└── README.md                       # Diese Datei
```

## 🛰️ Claude Session Monitor

Visualisiert die **parallel laufenden Claude-Code-Chats** und verknüpft sie mit der **Git-Historie** —
welche Session lief wann auf welchem Branch, und welcher Commit stammt aus welchem Chat.

```bash
python3 scripts/scan-claude-sessions.py   # Daten aus ~/.claude erzeugen
open session-monitor/index.html           # Viewer oeffnen (auch per file://)
```

Details siehe [`session-monitor/README.md`](session-monitor/README.md).

## 🔗 Teil des DEVKiTZ™ Ecosystem

Dieses Modul ist Teil von [DEVKiTZ™](https://github.com/7IKED/devkitz-workspace) — einem vollstaendigen AI-Entwickler-Oekosystem mit **154+ Modulen**, **NanoBot Schwarm**, **32 LLM Providern** und **Glassmorphism Design**.

| Metrik | Wert |
|:-------|:-----|
| Module | 154+ |
| Shared Scripts | 69 |
| LLM Provider | 32 |
| Design System | v2 |

## 📜 Lizenz

MIT © [DEVKiTZ™](https://github.com/7IKED/devkitz-workspace)
