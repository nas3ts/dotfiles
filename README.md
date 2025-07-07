# dotfiles
My dotfiles

## 🧩 Using Submodules (Terminal Themes)

This repo uses a **Git submodule** to include the [terminal themes](https://github.com/nas3ts/terminal-themes).

### 🛠 First Time Setup

If you're cloning this repo for the first time:

```bash
git clone --recurse-submodules https://github.com/nas3ts/dotfiles.git
```

> ✅ This grabs both the main repo and the themes inside `themes/terminal`.

---

### 🔁 Updating Later

To pull updates from both this repo **and** the terminal themes:

```bash
git pull --recurse-submodules
git submodule update --remote
```

> 🔄 Use this to stay synced with any theme updates.

