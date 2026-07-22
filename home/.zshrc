# Homebrew — load from wherever it lives (Apple Silicon, Intel, or Linuxbrew).
# Only detect+eval when a parent shell hasn't already exported it — skips the
# brew-shellenv fork in nested shells / zellij panes that inherit the env.
if [[ -z "${HOMEBREW_PREFIX:-}" ]]; then
  for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew \
               /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
    [[ -x "$_brew" ]] && eval "$("$_brew" shellenv)" && break
  done
  unset _brew
fi

# History
HISTSIZE=50000
SAVEHIST=50000
setopt INC_APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS

# Keybindings — Up/Down search history by current prefix
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search      # CSI (normal cursor-key mode)
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[OA' up-line-or-beginning-search      # SS3 (application cursor-key mode)
bindkey '^[OB' down-line-or-beginning-search

# Completion (cache lives under XDG_CACHE_HOME). Self-heal the zsh cache/state dirs
# so a wiped ~/.cache — or a symlink-only try before ./install.sh — doesn't silently
# break completion caching and history persistence.
[[ -d "$XDG_CACHE_HOME/zsh" ]] || mkdir -p "$XDG_CACHE_HOME/zsh"
[[ -d "$XDG_STATE_HOME/zsh" ]] || mkdir -p "$XDG_STATE_HOME/zsh"
autoload -Uz compinit && compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"

# Aliases — guarded so a fresh clone (before ./install.sh) keeps working ls/cat/etc.
if command -v eza >/dev/null; then
  alias ls='eza --group-directories-first'
  alias la='eza -al --group-directories-first'
  alias ll='eza -l --group-directories-first'
  alias tree='eza --tree'
fi
command -v bat     >/dev/null && alias cat='bat --plain --paging=never'
command -v lazygit >/dev/null && alias lg='lazygit'
command -v nvim    >/dev/null && alias v='nvim'

# Tools — guarded so a fresh clone (before ./install.sh) doesn't error on startup
command -v starship >/dev/null && eval "$(starship init zsh)"
command -v fzf      >/dev/null && eval "$(fzf --zsh)"

# Plugins (sourced before zoxide so they don't clobber its precmd hook)
[[ -r "${HOMEBREW_PREFIX:-}/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] \
  && source "${HOMEBREW_PREFIX}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
[[ -r "${HOMEBREW_PREFIX:-}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] \
  && source "${HOMEBREW_PREFIX}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# Local-only overrides (gitignored — secrets, machine-specific tweaks)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Zoxide last — its doctor warns if anything adds hooks after it.
# _ZO_DOCTOR=0 silences a spurious "init not at end" warning that fires every
# shell even when init is correctly placed last (see zoxide init zsh source).
export _ZO_DOCTOR=0
command -v zoxide >/dev/null && eval "$(zoxide init zsh --cmd cd)"
