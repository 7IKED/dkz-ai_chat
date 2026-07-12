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
├── index.html          # Hauptseite
├── style.css           # Modul-spezifische Styles
├── *.js                # Logik
├── multiplexer/        # 🖥️ Cosmo Multiplexer Umgebung (Zellij + Zsh)
├── prototypes/         # 🟢 Matrix-Terminal-Prototypen (HTML, Galerie: index.html)
└── README.md           # Diese Datei
```

## 🖥️ Cosmo Multiplexer Umgebung

Die Terminal-Version der Cosmo/Matrix Dashboards: eine **Zellij**-basierte
Multiplexer-Umgebung mit 5 Profilen — **Desktop · VPS · Agent · Builder
(mit Teststrassen-Erfassung) · Monitor** — lauffähig unter **Linux, Windows
(WSL) und Docker**.

```bash
cd multiplexer && ./install.sh     # Linux/macOS/WSL
cosmo desktop                       # oder: agent · builder · vps · monitor
```

→ Details in [`multiplexer/README.md`](multiplexer/README.md) · Schritt-für-Schritt: [`TUTORIAL.md`](TUTORIAL.md)

Dazu gehören:
- **Perfect Zsh Setup** (`multiplexer/shell/`) — zinit, Autosuggestions, Syntax-Highlighting, fzf-tab, zoxide, eza, Matrix-Prompt (Starship-Config + Fallback)
- **Prototypen-Galerie** (`prototypes/index.html`) — die 5 Matrix-HTML-Prototypen, aus denen die Terminal-Umgebung entstand

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
