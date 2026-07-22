# XDG base dirs — tools that respect XDG will use these
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

# User-installed binaries (curl-installed Claude Code, pipx, etc.)
# Set in .zshenv (not .zshrc) so brew shellenv runs after and keeps
# /opt/homebrew/bin ahead of ~/.local/bin in PATH precedence.
typeset -U path PATH          # dedupe PATH across nested / re-exec'd shells
export PATH="$HOME/.local/bin:$PATH"

# Redirect dotfile sprawl that would otherwise land in $HOME
export HISTFILE="$XDG_STATE_HOME/zsh/history"
export LESSHISTFILE=-

# Default editor
export EDITOR=nvim
export VISUAL=nvim
