# 🔧 macOS Fix PATH Pro · `macos-fix-path-pro.zsh`

> ⚡️ Smart Zsh script that rebuilds your `$PATH` on macOS by scanning the system for popular CLIs and inserting the correct `export PATH="..."` line into your `~/.zshrc` — with cache, fzf support, skip-cache option, and optional user config.

[![Made for macOS](https://img.shields.io/badge/made%20for-macOS-blue?logo=apple)](https://github.com/italoalmeida0/macos-fix-path-pro)  [![Shell](https://img.shields.io/badge/script-zsh-informational?logo=gnu-bash)](https://zsh.sourceforge.io)

---

## ✨ Features

- ✅ **Smart `$PATH` rebuilder** – finds all your installed CLIs in real paths
- 🧠 **Auto-deduplication** – ensures unique clean paths
- 🕒 **24h caching** – avoids unnecessary scanning by default
- 🟡 **Skip-cache mode** – use `--no-cache` (or `-c`) to force a full rescan
- ⚙️ **External config support** – define your own tools & directories
- 🧩 **Interactive mode** – optional filtering with `fzf`, toggle with `--no-interactive`
- 🪣 **Auto backup** – safely saves your previous `.zshrc`
- 🔒 **Safe & non-destructive** – prompts before applying changes

---

## 🚀 Quick Run

```bash
/usr/bin/curl -fsSL https://raw.githubusercontent.com/italoalmeida0/macos-fix-path-pro/main/macos-fix-path-pro.zsh | /bin/zsh -- -c # runs with skip-cache
# or for interactive selection:
/usr/bin/curl -fsSL https://raw.githubusercontent.com/italoalmeida0/macos-fix-path-pro/main/macos-fix-path-pro.zsh | /bin/zsh --
```

✅ If you agree with the previewed path, it will be appended to your `~/.zshrc`. A backup will be saved as `.zshrc.backup.YYYYMMDDHHMMSS`.

---

## 🧠 How It Works

1. Loads commands to search (like `node`, `docker`, `python`, `brew`, etc.)
2. Checks typical binary folders (`/usr/local/bin`, `$HOME/.nvm`, etc.)
3. For each known CLI, it:
   - Checks if it’s already on your system
   - Adds its path (if not already included)
4. Detects Ruby gem bin directory via `Gem.user_dir`
5. Generates a unique, clean `PATH` string
6. Shows you a preview before applying
7. Optionally lets you filter directories via `fzf`
8. Appends to your `.zshrc` safely

---

## ⚙️ Optional Configuration

Create a file at:
```sh
~/.config/macos-fix-path-pro/config.zsh
```
And define:
```zsh
cmds=(node deno bun php docker git ...)
candidate_dirs=(/opt/homebrew/bin $HOME/.cargo/bin ...)
```
This will override the defaults with your own custom preferences.

---

## 🔍 CLI Tools It Can Find

It detects 100+ CLIs including:

> `node` · `python3` · `pipx` · `docker` · `kubectl` · `git` · `brew` · `rustc` · `cargo` · `flutter` · `dart` · `aws` · `gcloud` · `heroku` · `vercel` · `netlify` · `firebase` · `supabase` · `vault` · `ansible` · `jq` · `httpie` · `mvn` · `gradle` · `composer` · `laravel` · ...

Feel free to expand the list in your config! 💪

---

## 🧪 Tip: Use with fzf

If you have [`fzf`](https://github.com/junegunn/fzf) installed, the script will offer an **interactive preview and directory picker**:

```bash
brew install fzf
```

---

## 📂 Caching & Performance

- Caches results in `~/.cache/macos-fix-path-pro/last_path` by default
- If the file is <24h old, it will reuse the result
- Use `--no-cache` (or `-c`) to skip the cache and force a full rescan

---

## 👨‍💻 Author

Made with ❤️ by [@italoalmeida0](https://github.com/italoalmeida0)

> Contribute, fork, or suggest improvements on GitHub!

---

## 📜 License

MIT License. Feel free to use, improve and share.

