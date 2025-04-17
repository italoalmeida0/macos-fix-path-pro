#!/usr/bin/env zsh
# ---------------------------------------------------------------
#  macos-fix-path-pro.zsh    v2025-04-17 (macOS · zsh) - Improved
#  Rebuilds the $PATH by discovering popular CLIs, with caching,
#  external config, optional interactive selection, and performance tweaks.
#  Repository: https://github.com/italoalmeida0/macos-fix-path-pro
# ---------------------------------------------------------------

# ———————————————————————————————————————————
# Bootstrap PATH
# ———————————————————————————————————————————
if [[ -x /usr/libexec/path_helper ]]; then
  eval "$(/usr/libexec/path_helper -s)"
else
  export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
fi

set -uo pipefail
setopt null_glob

# Load user config if available
config_file="$HOME/.config/macos-fix-path-pro/config.zsh"
if [[ -f $config_file ]]; then
  source "$config_file"
else
  # Default commands to search for
  cmds=(
    # Build systems / compilers
    gcc clang make cmake ninja gradle mvn ant
    # Version control
    git gh hub
    # Homebrew
    brew
    # Languages and package managers
    node npm npx yarn pnpm bun deno
    python python3 pip3 pipx poetry
    ruby gem bundle rake
    go goget gopls
    rustc cargo rustup
    javac java kotlin kotlinc scala sbt
    php composer laravel symfony
    swift swiftc xcodebuild
    dart flutter
    # Container & cloud
    docker docker-compose podman nerdctl
    kubectl helm kind minikube k3d
    terraform terragrunt pulumi
    ansible vagrant packer
    aws az gcloud doctl heroku
    # Extended CLIs
    supabase firebase vercel netlify wrangler fly
    oc kustomize kubeseal
    vault nomad consul trivy hadolint
    buildah podman-compose
    sfdx ghr
    # Databases & dev‑ops
    psql mysql mongod redis-cli sqlite3
    # Utilities
    jq yq curl wget nmap httpie
  )

  # Candidate directories
  candidate_dirs=(
    /usr/bin /bin /usr/sbin /sbin
    /opt/homebrew/bin /opt/homebrew/sbin /opt/homebrew/opt/*/bin /opt/homebrew/opt/*/libexec/bin
    /usr/local/bin /usr/local/sbin /usr/local/opt/*/bin /usr/local/opt/*/libexec/bin
    $HOME/.local/bin $HOME/bin
    $HOME/.nvm/versions/node/*/bin
    $HOME/.pyenv/shims $HOME/.pyenv/versions/*/bin
    $HOME/.rbenv/shims $HOME/.rbenv/versions/*/bin
    $HOME/.asdf/shims
    $HOME/.sdkman/candidates/*/current/bin
    $HOME/.jenv/shims
    $HOME/.cargo/bin
    $HOME/go/bin
    $HOME/.dotnet/tools
    $HOME/.flutter/bin
    $HOME/Library/Android/sdk/platform-tools
    $HOME/.composer/vendor/bin
    $HOME/.raycast/scripts
  )
fi

# Prepare unique dirs array
typeset -gU dirs
dirs=()
add_dir() { [[ -d $1 ]] && dirs+=$1 }

# Cache paths
cache_dir="$HOME/.cache/macos-fix-path-pro"
cache_file="$cache_dir/last_path"
mkdir -p "$cache_dir"

# Use cached PATH if less than 24h old
if [[ -f $cache_file && $(find "$cache_file" -mmin -1440) ]]; then
  newPATH=$(<"$cache_file")
  print -P "%F{cyan}Using cached PATH (last scan < 24h)%f"
else
  print -P "%F{cyan}Scanning directories and CLIs…%f"

  # Add fixed candidate dirs
  for d in "${candidate_dirs[@]}"; do
    add_dir "$d"
  done

  # Search for each command
  for c in "${cmds[@]}"; do
    if command -v "$c" &>/dev/null; then
      add_dir "$(dirname "$(command -v "$c")")"
    else
      for d in "${candidate_dirs[@]}"; do
        [[ -x "$d/$c" ]] && add_dir "$d"
      done
    fi
  done

  # Add personal Ruby gems bin
  add_dir "$HOME/.gem/ruby/3.4.0/bin"

  newPATH=$(IFS=:; echo "${dirs[*]}")
  echo "$newPATH" >| "$cache_file"
fi

# Optional interactive filter if fzf is installed
if command -v fzf &>/dev/null; then
  print -P "%F{cyan}Filtering directories interactively via fzf…%f"
  newPATH=$(printf "%s
" "${dirs[@]}" | fzf --multi --reverse | paste -sd ':' -)
fi

# Preview new PATH
print -P "
%F{green}Preview of proposed PATH:%f"
print "$newPATH" | tr ':' '\n'

print -P "
%F{cyan}Write to ~/.zshrc? [y/N]%f "
read -k reply; echo
[[ $reply != [yY] ]] && { print "Aborted. No changes made."; exit 0; }

# Backup old .zshrc
backup="$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
[[ -f ~/.zshrc ]] && cp ~/.zshrc "$backup"

# Append new PATH
{
  echo "
# --- PATH created by macos-fix-path-pro.zsh on $(date) ---"
  echo "export PATH=\"$newPATH\""
  echo "# ------------------------------------------------------"
} >> ~/.zshrc

print -P "%F{green}✅  PATH inserted!%f Open a new terminal or run 'source ~/.zshrc'."
print "Backup saved at $backup"

