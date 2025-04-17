# 🔧 macOS Fix PATH Pro · `macos-fix-path-pro.zsh`

> ⚡️ The ultimate `$PATH` fixer for macOS. Rebuilds your environment variable with surgical precision — detects over 100 CLI tools, scans dozens of locations (Brew, Nix, SDKs, etc.), and injects a clean, deduplicated `PATH` into your `~/.zshrc` or `~/.bash_profile` — all with interactive previews, caching, rollbacks, and full user control.

[![Made for macOS](https://img.shields.io/badge/made%20for-macOS-blue?logo=apple)](https://github.com/italoalmeida0/macos-fix-path-pro)
[![Shell](https://img.shields.io/badge/script-zsh%20%7C%20bash-informational?logo=gnu-bash)](https://zsh.sourceforge.io)

---

## ✨ Why It's Awesome

- ✅ **Auto-fixes broken or bloated `$PATH`s** in one shot
- 🔍 **Scans over 50 folders** across all major environments
- 🧠 **Knows 100+ dev tools** by name: `docker`, `npm`, `aws`, `brew`, `flutter`, `kubectl`, etc.
- 🎯 **Interactive mode with `fzf`**, plus live previews
- 🔁 **Diff vs your current PATH** – see exactly what changes
- 💾 **Smart 24h caching** – only rescans when needed
- 🔄 **Safe apply** with `--apply` or preview-only with `--print`
- 🔥 **Works with Zsh and Bash** – switch via `--shell`
- 🛟 **Rollbacks made easy** – backups + `revert-path` helper

> 🧙‍♂️ It's like `brew doctor` for your `$PATH`.

---

## 🚀 One-liner Fix (quick & dirty)

```bash
/usr/bin/curl -fsSL https://raw.githubusercontent.com/italoalmeida0/macos-fix-path-pro/main/macos-fix-path-pro.zsh | /bin/zsh
```

## 📥 Full Install (keep it forever)

```bash
/usr/bin/curl -fsSL -o macos-fix-path-pro.zsh \
  https://raw.githubusercontent.com/italoalmeida0/macos-fix-path-pro/main/macos-fix-path-pro.zsh \
&& /bin/chmod +x macos-fix-path-pro.zsh \
&& /bin/zsh macos-fix-path-pro.zsh --apply \
&& sudo install -m755 macos-fix-path-pro.zsh /usr/local/bin/macos-fix-path-pro
```

Run it with:

```bash
macos-fix-path-pro           # Interactive wizard (with fzf if available)
macos-fix-path-pro --print   # Just show the proposed PATH
macos-fix-path-pro --apply   # Run silently and apply
```

---

## 🧠 How It Works

1. Loads a curated list of 100+ common dev tools (Docker, Nix, Flutter, Bun, etc.)
2. Scans the usual suspects: Homebrew, Nix, pyenv, ASDF, SDKMAN, JetBrains scripts, and more
3. Discovers the true install location of every CLI
4. Merges all paths into a clean, deduped list
5. Optionally lets you **interactively pick directories** (fzf powered ✨)
6. Compares with your current `$PATH` and previews changes
7. Safely inserts it into your shell rc file (`.zshrc`, `.bash_profile`)
8. Creates backups with timestamps and a quick rollback function

---

## 🔧 Command Line Flags

| Flag | Shortcut | Description |
|------|----------|-------------|
| `--apply`       | `-a` | Save without confirmation |
| `--print`       | `-p` | Dry-run (print only) |
| `--no-cache`    | `-c` | Force full rescan |
| `--no-interactive` | `-n` | Skip fzf picker |
| `--shell bash|zsh` |     | Choose shell target |

---

## 🧩 Powered by fzf (optional)

If [fzf](https://github.com/junegunn/fzf) is installed, you'll get:

- ✅ Multi-select directory picker
- 👀 Preview with `ls` for each path

Install it via:
```bash
brew install fzf
```

---

## 💡 Custom Config

Want to fine-tune what gets included?
Create your own config file:

```bash
mkdir -p ~/.config/macos-fix-path-pro
nano ~/.config/macos-fix-path-pro/config.zsh
```

Then define:

```zsh
cmds=(node deno bun php docker git ...)
candidate_dirs=(/opt/homebrew/bin $HOME/.cargo/bin ...)
```

This **completely overrides** the defaults with your custom list.

---

## 🧠 CLIs It Understands

A taste of what it can auto-detect:

> `node` · `bun` · `python3` · `pipx` · `docker` · `kubectl` · `flutter` · `aws` · `gcloud` · `brew` · `nix` · `rustc` · `cargo` · `terraform` · `java` · `go` · `deno` · `composer` · `laravel` · `firebase` · `vercel` · `heroku` · `rg` · `fd` · `zoxide` · `chezmoi` · ...

> 💥 You can add or remove anything via your config.

---

## 📂 Smart Caching

- Cache lives in `~/.cache/macos-fix-path-pro/`
- Valid for 24h **or until config changes**
- Use `--no-cache` to force rescan anytime

---

## 🧨 Rollback Anytime

Every time you apply, a `.zshrc.backup.XXXXXXXX` is saved.

Also adds a handy shell function:
```bash
revert-path  # instantly restores the last backup
```

---

## 🧑‍💻 Author

Crafted by [@italoalmeida0](https://github.com/italoalmeida0) with ❤️

> Got a suggestion? Open an issue or PR!

---

## 🪪 License

MIT License — do whatever you want, just don't break people's `$PATH`. 😄

