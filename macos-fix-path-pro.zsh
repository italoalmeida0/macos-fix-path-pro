#!/usr/bin/env zsh
# ---------------------------------------------------------------
#  macos-fix-path-pro.zsh    v2025-04-17 (macOS · zsh) - Updated
#  Rebuilds the $PATH by discovering popular CLIs, with caching,
#  external config, optional interactive selection, and performance tweaks.
#  Repository: https://github.com/italoalmeida0/macos-fix-path-pro
# ---------------------------------------------------------------

set -uo pipefail
setopt null_glob

# ———————————————————————————————————————————
# Bootstrap PATH
# ———————————————————————————————————————————
if [[ -x /usr/libexec/path_helper ]]; then
  eval "$(/usr/libexec/path_helper -s)"
else
  export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
fi

# ———————————————————————————————————————————
# Execution parameters
# ———————————————————————————————————————————
interactive=true
skip_cache=false
while [[ $# -gt 0 ]]; do
  case $1 in
    --no-interactive|-n)
      interactive=false
      ;;
    --no-cache|-c)
      skip_cache=true
      ;;
    --help|-h)
      cat <<EOF
Usage: $(basename $0) [options]

Options:
  --no-interactive, -n   skip interactive selection (fzf)
  --no-cache, -c         force rescan and skip cache
  --help, -h             display this help message
EOF
      exit 0
      ;;
    *)
      shift; continue
      ;;
  esac
  shift
done

# ———————————————————————————————————————————
# Load user config if available
# ———————————————————————————————————————————
config_file="$HOME/.config/macos-fix-path-pro/config.zsh"
if [[ -f $config_file ]]; then
  source "$config_file"
else
  # Default commands to search for
  cmds=(
    gcc clang make cmake ninja gradle mvn ant
    git gh hub
    brew pod
    node npm npx yarn pnpm bun deno
    python python3 pip3 pipx poetry
    ruby gem bundle rake
    go goget gopls
    rustc cargo rustup
    javac java kotlin kotlinc scala sbt
    php composer laravel symfony
    swift swiftc xcodebuild
    dart flutter
    docker docker-compose podman nerdctl
    kubectl helm kind minikube k3d
    terraform terragrunt pulumi
    ansible vagrant packer
    aws az gcloud doctl heroku
    supabase firebase vercel netlify wrangler fly
    oc kustomize kubeseal
    vault nomad consul trivy hadolint
    buildah podman-compose
    sfdx ghr
    psql mysql mongod redis-cli sqlite3
    jq yq curl wget nmap httpie
  )

  # Candidate directories
  candidate_dirs=(
    /usr/bin /bin /usr/sbin /sbin
    /opt/homebrew/bin /opt/homebrew/sbin /opt/homebrew/opt/*/bin /opt/homebrew/opt/*/libexec/bin
    /usr/local/bin /usr/local/sbin /usr/local/opt/*/bin /usr/local/opt/*/libexec/bin
    /usr/local/lib/ruby/gems/*/bin
    $HOME/.gem/ruby/*/bin
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

# ———————————————————————————————————————————
# Build unique dirs list
# ———————————————————————————————————————————
typeset -gU dirs
dirs=()
add_dir() { [[ -d $1 ]] && dirs+=$1 }

# ———————————————————————————————————————————
# Cache for 24h (unless skipped)
# ———————————————————————————————————————————
cache_dir="$HOME/.cache/macos-fix-path-pro"
cache_file="$cache_dir/last_path"
mkdir -p "$cache_dir"

if ! $skip_cache && [[ -f $cache_file && $(find "$cache_file" -mmin -1440) ]]; then
  newPATH=$(<"$cache_file")
  print -P "%F{cyan}Using cached PATH (<24h)%f"
else
  if $skip_cache; then
    print -P "%F{yellow}Skipping cache and rescanning...%f"
  else
    print -P "%F{cyan}Scanning directories and CLIs...%f"
  fi

  for d in "${candidate_dirs[@]}"; do
    add_dir "$d"
  done

  for c in "${cmds[@]}"; do
    if command -v "$c" &>/dev/null; then
      add_dir "$(dirname "$(command -v "$c")")"
    else
      for d in "${candidate_dirs[@]}"; do
        [[ -x "$d/$c" ]] && add_dir "$d"
      done
    fi
  done

  newPATH=$(IFS=:\n; echo "${dirs[*]}")
  echo "$newPATH" >| "$cache_file"
fi

# ———————————————————————————————————————————
# Interactive selection (fzf)
# ———————————————————————————————————————————
if $interactive && command -v fzf &>/dev/null; then
  print -P "%F{cyan}Interactive selection via fzf... use Tab to mark multiple, Enter to confirm.%f"
  selected=$(printf "%s
" "${dirs[@]}" | fzf \
    --multi --reverse --prompt="Select PATH dirs> ")
  if [[ -n $selected ]]; then
    newPATH=$(echo "$selected" | paste -sd ':' -)
  fi
fi

# ———————————————————————————————————————————
# Preview and write
# ———————————————————————————————————————————
print -P "
%F{green}Preview of proposed PATH:%f"
print "$newPATH" | tr ':' '\n'

print -P "
%F{cyan}Write to ~/.zshrc? [y/N]%f "
read -k reply; echo
[[ $reply != [yY] ]] && { print "Aborted. No changes made."; exit 0; }

backup="$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
[[ -f ~/.zshrc ]] && cp ~/.zshrc "$backup"

{
  echo "
# --- PATH created by macos-fix-path-pro on $(date) ---"
  echo "export PATH=\"$newPATH\""
  echo "# ------------------------------------------------------"
} >> ~/.zshrc

print -P "%F{green}PATH inserted!%f Open a new terminal or run 'source ~/.zshrc'."
print "Backup saved at $backup"
