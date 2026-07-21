# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

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

# Completion (cache lives under XDG_CACHE_HOME)
autoload -Uz compinit && compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"

# Aliases
alias cat='bat --plain --paging=never'
alias ls='eza --group-directories-first'
alias la='eza -al --group-directories-first'
alias ll='eza -l --group-directories-first'
alias tree='eza --tree'
alias lg='lazygit'
alias v='nvim'

# Tools
eval "$(starship init zsh)"
eval "$(fzf --zsh)"

# Plugins (sourced before zoxide so they don't clobber its precmd hook)
source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# Local-only overrides (gitignored — secrets, machine-specific tweaks)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Zoxide last — its doctor warns if anything adds hooks after it.
# _ZO_DOCTOR=0 silences a spurious "init not at end" warning that fires every
# shell even when init is correctly placed last (see zoxide init zsh source).
export _ZO_DOCTOR=0
eval "$(zoxide init zsh --cmd cd)"
