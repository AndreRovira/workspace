# Ubuntu's /etc/zsh/zshrc runs a bare `compinit` (no -d) before ~/.zshrc, which
# writes ~/.zcompdump straight back into $HOME and makes every shell pay for two
# full compinit runs — .zshrc already runs its own against $XDG_CACHE_HOME.
# That file names this variable as the opt-out, and only .zshenv is early enough
# (.zshrc/.zshrc.local both run after it). Deliberately not exported: /etc/zsh/zshrc
# is the same process. Inert on macOS — the block there is gated on ID=ubuntu.
skip_global_compinit=1

# XDG base dirs — tools that respect XDG will use these
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

# User-installed binaries (curl-installed Claude Code, pipx, etc.)
# Set in .zshenv (not .zshrc) so brew shellenv runs after and keeps
# /opt/homebrew/bin ahead of ~/.local/bin in PATH precedence.
# Prepend ONLY if absent: .zshrc skips `brew shellenv` when HOMEBREW_PREFIX is
# inherited, so an unconditional prepend would hoist ~/.local/bin above Homebrew
# in every nested shell (zellij pane) and nowhere else — the same rc files
# resolving a name two different ways. The guard leaves an inherited entry where
# the parent put it, so pane and tab agree.
typeset -U path PATH fpath FPATH   # dedupe across nested / re-exec'd shells
(( ${path[(Ie)$HOME/.local/bin]} )) || export PATH="$HOME/.local/bin:$PATH"

# Redirect dotfile sprawl that would otherwise land in $HOME
export HISTFILE="$XDG_STATE_HOME/zsh/history"
export LESSHISTFILE=-

# Default editor
export EDITOR=nvim
export VISUAL=nvim
