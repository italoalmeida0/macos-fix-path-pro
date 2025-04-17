#!/usr/bin/env zsh
# -------------------------------------------------------------------------
#  macos-fix-path-pro.zsh    v2025-04-17c (macOS · zsh)
#  Rebuilds $PATH in a reproducible way:
#    • discovers popular CLIs across multiple package managers
#    • supports caching, diff preview, interactive fzf selection
#    • multi‑shell install (zsh|bash), dry‑run & non‑interactive modes
#  Repository: https://github.com/italoalmeida0/macos-fix-path-pro
# -------------------------------------------------------------------------

set -uo pipefail
setopt null_glob
setopt extended_glob

trap 'print -P "%F{red}Aborted by user (Ctrl‑C).%f"; exit 130' INT

# -------------------------------------------------------------------------
# Compact helpers
# -------------------------------------------------------------------------
add_dir() { [[ -d "$1" ]] && dirs+="$1" }
join_by() { local IFS="$1"; shift; print "$*" }

# -------------------------------------------------------------------------
# Default PATH bootstrap (before anything else)
# -------------------------------------------------------------------------
if [[ -x /usr/libexec/path_helper ]]; then
  eval "$(/usr/libexec/path_helper -s)"
else
  export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
fi

# -------------------------------------------------------------------------
# CLI list and candidate dirs (can be overridden in $config_file)
# -------------------------------------------------------------------------
# Popular commands – extend as new ecosystems appear.
default_cmds=(
  # languages & toolchains
  gcc clang make cmake ninja gradle mvn ant ccache llvm-config clangd clang-tidy
  git gh hub
  brew pod
  node npm npx yarn pnpm bun deno
  python python3 pip3 pipx poetry conda mamba micromamba
  ruby gem bundle rake
  go goget gopls dlv buf protoc protoc-gen-go
  rustc cargo rustup rust-analyzer just
  javac java kotlin kotlinc scala sbt
  php composer laravel symfony
  swift swiftc xcodebuild
  dart flutter
  haskell-stack cabal ghcup
  # containers & infra
  docker docker-compose podman nerdctl buildah
  kubectl k9s helm kind minikube k3d kustomize kubectx skaffold stern
  terraform terragrunt pulumi
  ansible vagrant packer nomad consul vault trivy hadolint sops age
  aws az gcloud doctl heroku aws-vault saml2aws
  supabase firebase vercel netlify wrangler fly
  # db & data
  psql mysql mongod redis-cli clickhouse-client etcdctl
  jq yq rg fd bat delta zoxide chezmoi httpie curl wget nmap
)

# Determine Homebrew prefix dynamically to support Intel & Apple Silicon
if command -v brew &>/dev/null; then
  brew_prefix=$(brew --prefix)
else
  brew_prefix="/opt/homebrew"
fi

default_candidate_dirs=(
  # system
  /usr/bin /bin /usr/sbin /sbin
  # Homebrew core  gnubin additions
  $brew_prefix/bin $brew_prefix/sbin $brew_prefix/opt/*/bin \
  $brew_prefix/opt/*/libexec/bin $brew_prefix/opt/*/libexec/gnubin
  # MacPorts & Fink
  /opt/local/bin /opt/local/sbin /sw/bin /sw/sbin
  # Nix (user & system profiles)
  /nix/var/nix/profiles/*/bin $HOME/.nix-profile/bin
  # Conda / Micromamba
  $HOME/micromamba/bin $HOME/miniconda3/bin $HOME/opt/miniconda3/bin
  # Gems
  /usr/local/lib/ruby/gems/*/bin $HOME/.gem/ruby/*/bin
  # Haskell
  $HOME/.ghcup/bin
  # User‑managed misc
  $HOME/.local/bin $HOME/bin
  # Node – NVM
  $HOME/.nvm/versions/node/*/bin
  # Python – pyenv
  $HOME/.pyenv/shims $HOME/.pyenv/versions/*/bin
  # Ruby – rbenv
  $HOME/.rbenv/shims $HOME/.rbenv/versions/*/bin
  # ASDF
  $HOME/.asdf/shims
  # SDKMAN
  $HOME/.sdkman/candidates/*/current/bin
  # jEnv
  $HOME/.jenv/shims
  # Rust
  $HOME/.cargo/bin
  # Go
  $HOME/go/bin
  # .NET
  $HOME/.dotnet/tools
  # Flutter
  $HOME/.flutter/bin
  # Android
  $HOME/Library/Android/sdk/platform-tools
  # Composer
  $HOME/.composer/vendor/bin
  # Raycast
  $HOME/.raycast/scripts
  # JetBrains Toolbox scripts (note the space!)
  $HOME/Library/Application\ Support/JetBrains/Toolbox/scripts
)

# -------------------------------------------------------------------------
# Config file override (user can redefine cmds/candidate_dirs arrays)
# -------------------------------------------------------------------------
config_file="$HOME/.config/macos-fix-path-pro/config.zsh"
if [[ -r $config_file ]]; then
  source "$config_file"
else
  cmds=("${default_cmds[@]}")
  candidate_dirs=("${default_candidate_dirs[@]}")
fi

# -------------------------------------------------------------------------
# Argument parsing
# -------------------------------------------------------------------------
interactive=true
skip_cache=false
apply=false
print_only=false
target_shell="zsh"

usage() {
  cat <<EOF
Usage: $(basename $0) [options]

Options:
  --no-interactive, -n   Do not launch fzf; use full candidate set
  --apply, -a            Apply without confirmation prompt
  --print, -p            Dry‑run: print PATH and exit
  --shell <sh>           Target shell rc file (zsh|bash). Default: zsh
  --no-cache, -c         Force rescan and skip cache
  --help, -h             Display this help message
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-interactive|-n) interactive=false ;;
    --apply|-a)          apply=true ;;
    --print|-p)          print_only=true ;;
    --shell)             target_shell="$2"; shift ;;
    --no-cache|-c)       skip_cache=true ;;
    --help|-h)           usage; exit 0 ;;
    *)                   print -P "%F{red}Unknown option: $1%f"; usage; exit 1 ;;
  esac
  shift
done

# Resolve target rc file
case $target_shell in
  zsh)  rc_file="$HOME/.zshrc" ;;
  bash) rc_file="$HOME/.bash_profile" ;;
  *)    print -P "%F{red}Unsupported shell: $target_shell%f"; exit 1 ;;
esac

# -------------------------------------------------------------------------
# Cache logic (24 h OR hash change)
# -------------------------------------------------------------------------
cache_dir="$HOME/.cache/macos-fix-path-pro"
cache_file="$cache_dir/last_path"
cache_meta="$cache_dir/meta"
mkdir -p "$cache_dir"

cache_fresh() {
  [[ -f $cache_file && -f $cache_meta ]] || return 1
  [[ $(find "$cache_file" -mmin -1440) ]] || return 1
  local current_hash
  current_hash=$(print -l "${candidate_dirs[@]}" "${cmds[@]}" | shasum | cut -d" " -f1)
  [[ $(<"$cache_meta") == "$current_hash" ]]
}

if ! $skip_cache && cache_fresh; then
  newPATH=$(<"$cache_file")
  print -P "%F{cyan}Using cached PATH (still valid)%f"
else
  $skip_cache && print -P "%F{yellow}Skipping cache and rescanning...%f" || print -P "%F{cyan}Scanning directories and CLIs...%f"

  typeset -gU dirs
  dirs=()

  # 1) Static candidate dirs (wildcards expand thanks to 'null_glob')
  for d in "${candidate_dirs[@]}"; do
    add_dir "$d"
  done

  # 2) Directories that hold the CLIs
  for c in "${cmds[@]}"; do
    if command -v "$c" &>/dev/null; then
      add_dir "$(dirname "$(command -v "$c")")"
    else
      for d in "${candidate_dirs[@]}"; do
        [[ -x "$d/$c" ]] && add_dir "$d"
      done
    fi
  done

  newPATH=$(join_by ":" "${dirs[@]}")

  # Update cache atomically
  print "$newPATH" >| "$cache_file"
  print -l "${candidate_dirs[@]}" "${cmds[@]}" | shasum | cut -d" " -f1 >| "$cache_meta"
fi

# -------------------------------------------------------------------------
# Interactive selection (fzf with preview)
# -------------------------------------------------------------------------
if $interactive && command -v fzf &>/dev/null; then
  print -P "%F{cyan}Interactive selection (Tab to toggle, Enter to confirm)%f"
  selected=$(print -rl -- "${dirs[@]}" | fzf \
    --multi --reverse \
    --prompt="Select PATH dirs> " \
    --preview 'ls -1 {} | head -50' \
    --preview-window=down:40%:wrap)
  [[ -n $selected ]] && newPATH=$(join_by ":" ${(f)selected})
fi

# -------------------------------------------------------------------------
# Diff against current PATH
# -------------------------------------------------------------------------
print -P "\n%F{green}Diff vs current PATH:%f"
current_dirs=("${(s.:.)PATH}")
typeset -gU current_dirs
typeset -gU new_dirs
new_dirs=("${(s.:.)newPATH}")

for d in "${new_dirs[@]}"; do
  if (( ${current_dirs[(i)$d]} > ${#current_dirs} )); then
    print -P "%F{green} $d%f"
  fi
done
for d in "${current_dirs[@]}"; do
  if (( ${new_dirs[(i)$d]} > ${#new_dirs} )); then
    print -P "%F{red}- $d%f"
  fi
done

# -------------------------------------------------------------------------
# Output and persist
# -------------------------------------------------------------------------
print -P "\n%F{green}Proposed PATH:%f"
print "$newPATH" | tr ':' '\n'

if $print_only; then
  exit 0
fi

if ! $apply; then
  read -q "reply?$(print -P '\n%F{cyan}Write to $rc_file? [y/N] %f')" || { print "\nAborted. No changes made."; exit 0; }
  print
fi

backup=$(mktemp "$rc_file.backup.XXXXXXXX")
[[ -f $rc_file ]] && cp "$rc_file" "$backup"

{
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  print "\n# --- macos-fix-path-pro BEGIN (${timestamp}) ---"
  print "export PATH=\"$newPATH\""

  # roll‑back helper (added once; safe to re‑append)
  print '\n# roll back the last PATH change made by macos‑fix‑path‑pro'
  print 'revert-path() {'
  print '  local rc f'
  print '  case "$(basename "$SHELL")" in'
  print '    zsh)  rc="$HOME/.zshrc" ;;'
  print '    bash) rc="$HOME/.bash_profile" ;;'
  print '    *)    echo "Unsupported shell: $SHELL" >&2; return 1 ;;'
  print '  esac'
  print '  f=$(ls -t "${rc}.backup."* 2>/dev/null | head -n1)'
  print '  [[ -f $f ]] || { echo "No backup found." >&2; return 1; }'
  print '  cp "$f" "$rc" && echo "Restored $rc from $f."'
  print '}'

  print "# --- macos-fix-path-pro END ---"
 } >> "$rc_file"
 
 print -P "%F{green}PATH atualizado! Backup salvo em $backup%f"