#!/usr/bin/env bash
# Idempotent bootstrap for a personal machine.
#
# Auto-detects the OS: on macOS it installs the full stack; on Linux/WSL2 it
# installs the cross-platform core (CLI tools + shell/editor/git configs) and
# skips everything macOS-specific (GUI casks, kanata, system defaults).
# On macOS it PROMPTS for the optional extras (GUI apps, kanata, system defaults);
# pre-answer non-interactively with env vars, e.g.  INSTALL_KANATA=0 ./install.sh
#
# Run from inside this repo:  ./install.sh
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"   # Darwin (macOS) | Linux (incl. WSL2)

log()  { printf '\n▶ %s\n' "$*"; }
note() { printf '  %s\n' "$*"; }

# ask VAR "Prompt?" DEFAULT(Y|N)  -> yes:0 / no:1
# A preset env var VAR (1/y/yes/true) wins for non-interactive runs; with no TTY
# it falls back to DEFAULT.
ask() {
  local var="$1" prompt="$2" default="${3:-Y}" reply
  if [[ -n "${!var:-}" ]]; then
    case "${!var}" in
      1|[Yy]|[Yy][Ee][Ss]|[Tt][Rr][Uu][Ee]|[Oo][Nn]) return 0 ;;
      *) return 1 ;;
    esac
  fi
  if [[ ! -t 0 ]]; then
    [[ "$default" == "Y" ]] && return 0 || return 1
  fi
  local hint="[Y/n]"; [[ "$default" == "N" ]] && hint="[y/N]"
  read -r -p "  $prompt $hint " reply || true
  [[ "${reply:-$default}" =~ ^[Yy] ]] && return 0 || return 1
}

# link SRC DEST — replace DEST with a symlink to SRC, moving anything real aside.
#
# The `! -L` branch is load-bearing, not politeness: `ln -sfn SRC DEST` where DEST is
# a *real directory* does not replace it, it creates DEST/$(basename SRC) inside it.
# -n/-h only suppresses following a symlink, never a real dir. So a real ~/.config/nvim
# must be moved out of the way first. Once DEST is a symlink — live, dangling, or
# pointing elsewhere — `-f -n` unlinks and recreates it correctly on both GNU coreutils
# and BSD/macOS ln, which is the re-run case.
link() {
  local src="$1" dest="$2"
  if [[ -e "$dest" && ! -L "$dest" ]]; then
    local bak="$dest.backup"
    [[ -e "$bak" ]] && bak="$dest.backup.$(date +%Y%m%d%H%M%S)"   # never clobber an old backup
    log "Backing up existing $dest → $bak"
    mv "$dest" "$bak"
  fi
  ln -sfn "$src" "$dest"
}

# ---------------------------------------------------------------------------
# 1. Xcode CLT (macOS) + Homebrew
# ---------------------------------------------------------------------------
if [[ "$OS" == "Darwin" ]] && ! xcode-select -p >/dev/null 2>&1; then
  log "Installing Xcode Command Line Tools (a GUI prompt will appear)…"
  xcode-select --install || true
  note "Re-run this script after the CLT install finishes."
  exit 0
fi

if ! command -v brew >/dev/null 2>&1; then
  log "Installing Homebrew…"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Load brew into this shell from wherever it installed itself
# (Apple Silicon, Intel, or Linuxbrew).
for _b in /opt/homebrew/bin/brew /usr/local/bin/brew \
          /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
  [[ -x "$_b" ]] && eval "$("$_b" shellenv)" && break
done
unset _b

# ---------------------------------------------------------------------------
# 2. Packages — core everywhere; GUI apps only on macOS (prompted)
# ---------------------------------------------------------------------------
# opencode's tap and its trust marker are both declared in the Brewfile
# (`tap "anomalyco/tap", trusted: true`), which `brew bundle` applies before it
# loads any formula — so no pre-tap and no `brew trust` call is needed here, and
# `brew bundle --file=Brewfile` works standalone on a fresh machine.
log "Installing core packages (Brewfile)…"
brew bundle --file="$DIR/Brewfile" \
  || log "⚠ Some core Brewfile entries failed — continuing so dotfiles still get linked. Fix them and re-run."

if [[ "$OS" == "Darwin" ]]; then
  if ask INSTALL_GUI "Install macOS GUI apps (Ghostty, VS Code, Alt-Tab, Nerd Font)?" Y; then
    log "Installing GUI apps (Brewfile.macos)…"
    brew bundle --file="$DIR/Brewfile.macos" || log "⚠ Some GUI apps failed — continuing."
  else
    note "Skipping GUI apps."
  fi
fi

# VPS access (opt-in, default no): Tailscale + VNC viewer. Skip on machines that
# should not reach the VPS. See README → "VPS access".
VPS=0
if [[ "$OS" == "Darwin" ]]; then
  if ask INSTALL_VPS "Install VPS access tools (Tailscale app, TigerVNC viewer)?" N; then
    VPS=1
    log "Installing VPS access tools (Brewfile.vps — tailscale pkg asks for sudo)…"
    brew bundle --file="$DIR/Brewfile.vps" || log "⚠ Some VPS tools failed — continuing."
  else
    note "Skipping VPS access tools."
  fi
fi

# ---------------------------------------------------------------------------
# 3. Claude Code (native, auto-updating) — cross-platform CLI, not in Homebrew
#    because the brew cask doesn't auto-update; the native installer does.
# ---------------------------------------------------------------------------
if ! command -v claude >/dev/null 2>&1; then
  log "Installing Claude Code (native, stable channel)…"
  curl -fsSL https://claude.ai/install.sh | bash -s stable \
    || log "⚠ Claude Code install failed — continuing so dotfiles still get linked. Install it later."
fi

# ---------------------------------------------------------------------------
# 3b. Claude Code plugins — caveman (terse replies) + ponytail (minimal code).
#     Marketplace plugins, installed at user scope; their hooks run under Node
#     (node@22 in Brewfile). Idempotent: skips what's already present.
#     Update later with:  claude plugin update caveman && claude plugin update ponytail
# ---------------------------------------------------------------------------
export PATH="$HOME/.local/bin:$PATH"   # the native installer drops `claude` here
if command -v claude >/dev/null 2>&1; then
  log "Installing Claude Code plugins (caveman, ponytail)…"
  # "<github owner/repo>  <plugin@marketplace>"
  # Snapshot the lists once (no `cmd | grep -q` — pipefail + early grep exit is flaky).
  have_mkts="$(claude plugin marketplace list 2>/dev/null || true)"
  have_plugins="$(claude plugin list 2>/dev/null || true)"
  for entry in "DietrichGebert/ponytail ponytail@ponytail" \
               "JuliusBrussee/caveman   caveman@caveman"; do
    read -r repo plugin <<<"$entry"
    mkt="${plugin#*@}"
    if ! grep -q "❯ $mkt\$" <<<"$have_mkts"; then
      claude plugin marketplace add "$repo" >/dev/null \
        || log "⚠ Could not add marketplace $repo — continuing."
    fi
    if ! grep -q "❯ $plugin\$" <<<"$have_plugins"; then
      claude plugin install "$plugin" >/dev/null \
        || log "⚠ Could not install plugin $plugin — continuing."
    else
      note "$plugin already installed."
    fi
  done
else
  note "claude not on PATH — skipped Claude Code plugins; re-run ./install.sh once it's installed."
fi

# ---------------------------------------------------------------------------
# 4. XDG directories + state/cache subfolders tools won't auto-create
# ---------------------------------------------------------------------------
log "Creating XDG directories…"
mkdir -p \
  ~/.config ~/.config/herdr ~/.config/mise ~/.local/share ~/.local/state/zsh ~/.cache/zsh \
  ~/.config/git ~/.local/bin ~/code

# ---------------------------------------------------------------------------
# 5. Symlink dotfiles — core everywhere; ghostty is macOS-only
# ---------------------------------------------------------------------------
log "Symlinking home dotfiles…"
link "$DIR/home/.zshenv"    ~/.zshenv
link "$DIR/home/.zshrc"     ~/.zshrc
link "$DIR/home/.gitconfig" ~/.gitconfig

# Pin the gh credential helper to an absolute path, machine-locally.
#
# home/.gitconfig ships the portable `!gh auth git-credential` because the repo
# serves several machines with different Homebrew prefixes. But `gh` is only ever
# on PATH in a shell that ran `brew shellenv` — and git gets invoked plenty of
# other ways (system /usr/bin/git, editors, GUI clients, hooks, cron), where a
# bare `gh` is simply not found and the HTTPS push fails with a bad-credentials
# error that points nowhere near the real cause. So resolve gh once, here, and
# write the absolute path into the machine-local include — which home/.gitconfig
# loads LAST precisely so it can win. Never tracked; re-resolved on every re-run.
if GH_BIN="$(command -v gh 2>/dev/null)"; then
  LOCAL_GITCONFIG="$HOME/.config/git/local.gitconfig"
  [[ -e "$LOCAL_GITCONFIG" ]] || : > "$LOCAL_GITCONFIG"
  for _host in github.com gist.github.com; do
    # The empty first value resets any helper inherited from an outer scope;
    # --replace-all collapses repeats so re-running never stacks duplicates.
    git config --file "$LOCAL_GITCONFIG" --replace-all "credential.https://$_host.helper" ""
    git config --file "$LOCAL_GITCONFIG" --add         "credential.https://$_host.helper" "!$GH_BIN auth git-credential"
  done
  unset _host LOCAL_GITCONFIG
  note "Pinned gh credential helper → $GH_BIN (in ~/.config/git/local.gitconfig)"
fi

log "Symlinking ~/.config entries…"
for d in nvim zellij; do link "$DIR/config/$d" ~/.config/"$d"; done
link "$DIR/config/starship.toml" ~/.config/starship.toml
link "$DIR/config/herdr/config.toml" ~/.config/herdr/config.toml
# mise's global tool list. Symlinking it is safe in both directions: `mise use -g`
# rewrites the file in place through the link, so a version bump lands as a repo
# diff instead of drifting into an untracked copy.
link "$DIR/config/mise/config.toml" ~/.config/mise/config.toml
[[ "$OS" == "Darwin" ]] && link "$DIR/config/ghostty" ~/.config/ghostty

# ---------------------------------------------------------------------------
# 6. macOS-only extras (prompted): kanata, system defaults
# ---------------------------------------------------------------------------
KANATA=0
if [[ "$OS" == "Darwin" ]]; then
  if ask INSTALL_KANATA "Set up kanata homerow mods (install kanata + link its config)?" N; then
    KANATA=1
    log "Installing kanata…"
    # Do NOT install Karabiner-Elements — its auto-updating driver breaks kanata.
    # The pinned DriverKit driver is installed later by macos/install-kanata-driver.sh.
    brew list kanata >/dev/null 2>&1 || brew install kanata || log "⚠ kanata install failed — continuing."
    link "$DIR/config/kanata" ~/.config/kanata
  fi

  if ask INSTALL_DEFAULTS "Apply macOS system defaults (keyboard, Finder, Dock, screenshots…)?" Y; then
    log "Applying macOS defaults…"
    bash "$DIR/macos/defaults.sh" || log "⚠ Some macOS defaults failed — continuing."
  else
    note "Skipping macOS defaults."
  fi
fi

# ---------------------------------------------------------------------------
# 7. Final notes
# ---------------------------------------------------------------------------
log "✓ Bootstrap complete ($OS)."
echo
note "Manual follow-ups (one-time):"
# History first, and on BOTH platforms: .zshenv repoints HISTFILE to the XDG path, so
# an existing ~/.zsh_history silently stops being read. macOS needs this at least as
# much as Linux — zsh has been the default login shell there since Catalina.
# `cp`, not `mv`: nothing is destroyed until the user has seen the entries arrive.
if [[ -f "$HOME/.zsh_history" && ! -s "$HOME/.local/state/zsh/history" ]]; then
  note "  • Copy your old shell history over (HISTFILE is XDG now) BEFORE the next zsh:"
  note "      cp -p ~/.zsh_history ~/.local/state/zsh/history"
  note "    Then open a new shell, check \`history -i | head\` shows the old dates, and"
  note "    only then remove ~/.zsh_history."
fi
if [[ "$OS" == "Darwin" && "$KANATA" == "1" ]]; then
  note "  • Finish kanata: ./macos/install-kanata-driver.sh (approve + reboot), then install"
  note "    the two LaunchDaemons and grant Input Monitoring — see README → \"Kanata setup\"."
  note "  • Glove80 Cmd↔Ctrl swap — see README → \"Glove80 Cmd↔Ctrl swap\"."
fi
if [[ "$VPS" == "1" ]]; then
  note "  • VPS: open Tailscale.app → log in; copy the vps blocks from ssh/config.example"
  note "    into ~/.ssh/config — see README → \"VPS access\"."
fi
if [[ "$OS" == "Linux" ]]; then
  # Fall back to $SHELL when getent yields nothing (no `files` NSS source, container
  # image with no passwd entry, LDAP/SSSD lookup failure) — an empty result would
  # otherwise match `!= *zsh` and print the note to someone already running zsh.
  login_shell="$(getent passwd "$(id -un)" 2>/dev/null | cut -d: -f7)"
  if [[ "${login_shell:-$SHELL}" != *zsh ]]; then
    note "  • Make zsh your login shell so these configs load (Ubuntu ships bash):"
    note "      sudo apt install -y zsh && chsh -s \"\$(which zsh)\""
    note "    WSL has no log-out: just open a new terminal tab. Still bash? Run"
    note "      wsl.exe --shutdown   from PowerShell, then reopen."
  fi
  if [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
    note "  • WSL2: install a Nerd Font on WINDOWS and set it in Windows Terminal"
    note "    (Settings → Profiles → Defaults → Appearance → JetBrainsMono Nerd Font),"
    note "    and unbind WT's Alt+arrows / Alt+Shift++ so zellij can see them."
    note "    VS Code \`code\`, clipboard and systemd notes: README → \"WSL2 + Windows"
    note "    Terminal checklist\"."
  fi
fi
# `brew bundle` installs mise but never the runtimes it manages — the linked config
# only declares them, so until this runs `node`/`elixir` fall back to whatever else
# is on PATH (on a fresh box: nothing, or Homebrew's).
if command -v mise >/dev/null 2>&1 && mise ls 2>/dev/null | grep -q '(missing)'; then
  note "  • Install the runtimes mise declares (config/mise/config.toml):"
  note "      mise install        # then: command -v node  →  ~/.local/share/mise/installs/…"
fi
note "  • Create ~/.zshrc.local for secrets / machine-specific PATH (never tracked)."
note "  • SSH key + GitHub CLI:"
note "      ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_personal   # add .pub at github.com/settings/keys"
note "      gh auth login"
note "  • Restart your shell (or:  exec zsh)."
echo
