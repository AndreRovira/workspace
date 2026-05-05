# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# History
HISTSIZE=50000
SAVEHIST=50000
setopt INC_APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS

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
eval "$(zoxide init zsh --cmd cd)"
eval "$(starship init zsh)"
eval "$(fzf --zsh)"

# Plugins (must load last)
source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# Local-only overrides (gitignored — secrets, machine-specific tweaks)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
