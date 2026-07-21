#!/usr/bin/env bash
# Idempotent bootstrap for a fresh personal Mac.
# Run from inside this repo:  ./install.sh
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { printf '\n▶ %s\n' "$*"; }

# ---------------------------------------------------------------------------
# 1. Xcode Command Line Tools (idempotent — does nothing if already installed)
# ---------------------------------------------------------------------------
if ! xcode-select -p >/dev/null 2>&1; then
  log "Installing Xcode Command Line Tools (a GUI prompt will appear)…"
  xcode-select --install || true
  echo "  Re-run this script after the CLT install finishes."
  exit 0
fi

# ---------------------------------------------------------------------------
# 2. Homebrew
# ---------------------------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  log "Installing Homebrew…"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

log "Installing packages from Brewfile…"
# Don't let one failed formula/cask (e.g. an app already installed by hand) abort
# the whole bootstrap under `set -e` — the dotfile symlinks below matter more.
brew bundle --file="$DIR/Brewfile" || log "⚠ Some Brewfile entries failed — continuing so dotfiles still get linked. Fix them and re-run."

# ---------------------------------------------------------------------------
# 3. Claude Code (native, auto-updating). Not in Brewfile because the
#    homebrew cask doesn't auto-update — the native installer does.
# ---------------------------------------------------------------------------
if ! command -v claude >/dev/null 2>&1; then
  log "Installing Claude Code (native, stable channel)…"
  curl -fsSL https://claude.ai/install.sh | bash -s stable
fi

# ---------------------------------------------------------------------------
# 4. XDG directories + state/cache subfolders that tools won't auto-create
# ---------------------------------------------------------------------------
log "Creating XDG directories…"
mkdir -p \
  ~/.config \
  ~/.local/share \
  ~/.local/state/zsh \
  ~/.cache/zsh \
  ~/.config/git \
  ~/code/personal

# ---------------------------------------------------------------------------
# 5. Symlink dotfiles
# ---------------------------------------------------------------------------
link() {
  local src="$1" dest="$2"
  if [[ -e "$dest" && ! -L "$dest" ]]; then
    log "Backing up existing $dest → $dest.backup"
    mv "$dest" "$dest.backup"
  fi
  ln -sfn "$src" "$dest"
}

log "Symlinking home dotfiles…"
link "$DIR/home/.zshenv"    ~/.zshenv
link "$DIR/home/.zshrc"     ~/.zshrc
link "$DIR/home/.gitconfig" ~/.gitconfig

log "Symlinking ~/.config entries…"
for d in ghostty kanata nvim zellij; do
  link "$DIR/config/$d" ~/.config/$d
done
link "$DIR/config/starship.toml" ~/.config/starship.toml

# ---------------------------------------------------------------------------
# 6. macOS defaults
# ---------------------------------------------------------------------------
log "Applying macOS defaults…"
bash "$DIR/macos/defaults.sh"

# ---------------------------------------------------------------------------
# 7. Final notes
# ---------------------------------------------------------------------------
cat <<'EOF'

✓ Bootstrap complete.

Manual follow-ups (one-time):
  1. Kanata homerow mods — see README → "Kanata setup":
       a. ./macos/install-kanata-driver.sh   (installs the pinned Karabiner
          driver; approve the extension + reboot when it says to)
       b. install the two LaunchDaemons (kanata + karabiner-vhidd)
       c. grant Input Monitoring for /opt/homebrew/bin/kanata
     Do NOT install Karabiner-Elements — it auto-updates the driver and breaks kanata.
  2. Glove80 Cmd↔Ctrl swap — do it in Glove80 firmware or macOS Modifier Keys
     (README → "Glove80 Cmd↔Ctrl swap"), NOT Karabiner-Elements.
  3. Create ~/.zshrc.local for any secrets (e.g. OPENAI_API_KEY).
  4. Generate SSH key for personal GitHub:
       ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_personal
     Then add the .pub key at https://github.com/settings/keys
  5. Run `gh auth login` to authenticate the GitHub CLI (HTTPS credential helper).
  6. Restart your shell (or `exec zsh`).

EOF
