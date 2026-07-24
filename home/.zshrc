# Homebrew — load from wherever it lives (Apple Silicon, Intel, or Linuxbrew).
# Only detect+eval when a parent shell hasn't already exported it — skips the
# brew-shellenv fork in nested shells / zellij panes that inherit the env.
if [[ -z "${HOMEBREW_PREFIX:-}" ]]; then
  for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew \
               /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
    [[ -x "$_brew" ]] && eval "$("$_brew" shellenv)" && break
  done
  unset _brew
else
  # HOMEBREW_PREFIX is exported and inherited; fpath is NOT. Skipping the fork
  # above therefore also skips the site-functions entry brew shellenv delivers,
  # so nested shells lose _brew/_gh/_bat/_fd/_rg/_aws completions AND compinit
  # rebuilds the shared dump on every tab<->pane alternation (it validates the
  # cache by counting fpath files). `fpath[1,0]=` is brew shellenv's own
  # slice-prepend, so a pane's fpath comes out identical to its parent's;
  # `typeset -U fpath` in .zshenv keeps it single if this file is re-sourced.
  [[ -d "$HOMEBREW_PREFIX/share/zsh/site-functions" ]] \
    && fpath[1,0]="$HOMEBREW_PREFIX/share/zsh/site-functions"
fi

# History. EXTENDED_HISTORY writes the `: <epoch>:<elapsed>;` prefix — without it
# the first interactive shell rewrites $HISTFILE and silently strips every
# timestamp already in it, killing `history -i` / `fc -li` for good.
# No INC_APPEND_HISTORY: SHARE_HISTORY already implies it (man zshoptions).
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS

# Kill XON/XOFF flow control. Ubuntu ptys ship with ixon on, so at a bare prompt
# Ctrl+S freezes the terminal with no feedback and only Ctrl+Q releases it — the
# exact two keys zellij teaches you are "scroll mode" and "detach", so the freeze
# reads as a hang. Also hands Ctrl+S / Ctrl+Q back to ZLE outside zellij.
[[ -t 0 ]] && stty -ixon 2>/dev/null

# Force emacs line editing. zsh links the `main` keymap to `viins` whenever
# $VISUAL/$EDITOR contains "vi" (man zshzle) — and .zshenv sets EDITOR=nvim,
# which matches. Without this every shell starts in vi insert mode: ^A/^E/^K/^R
# self-insert, Alt+b/f undefined, Esc drops to command mode. oh-my-zsh used to
# hide this behind its own `bindkey -e`.
# Must stay ABOVE the binds below — `bindkey -e` relinks `main`, so anything
# bound before it lands in the old keymap and is orphaned.
bindkey -e

# Emacs keymap, explicitly. With no `bindkey -e`/`-v`, zsh picks the keymap from
# $EDITOR/$VISUAL — and .zshenv sets those to nvim, so `main` silently became the
# *vi insert* keymap. There Alt+Backspace (ESC DEL) is unbound, so zsh falls back
# to the longest match — bare ESC, i.e. vi-cmd-mode — and DEL then just walks the
# cursor left. Nothing gets erased and starship swaps ❯ for its vicmd ❮.
# Must come before the bindkey lines below, which bind into whatever `main` is.
bindkey -e
bindkey '^[^H' backward-kill-word   # terminals that send ESC+^H rather than ESC+DEL

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
# break completion caching and history persistence. The `:=` defaults cover the case
# where .zshenv hasn't been linked yet (otherwise these would expand to "/zsh").
: "${XDG_CACHE_HOME:=$HOME/.cache}" "${XDG_STATE_HOME:=$HOME/.local/state}"
[[ -d "$XDG_CACHE_HOME/zsh" ]] || mkdir -p "$XDG_CACHE_HOME/zsh"
[[ -d "$XDG_STATE_HOME/zsh" ]] || mkdir -p "$XDG_STATE_HOME/zsh"
autoload -Uz compinit && compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"

# Aliases — guarded so a fresh clone (before ./install.sh) keeps working ls/cat/etc.
if command -v eza >/dev/null; then
  alias ls='eza --group-directories-first'
  alias l='eza -l --group-directories-first'    # was `colorls -l --sort-dirs` under omz
  alias la='eza -al --group-directories-first'
  alias ll='eza -lA --group-directories-first'  # -A: almost-all, so `ll` != `l`
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

# Local-only overrides (outside the repo, never tracked — secrets, machine-specific tweaks)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# mise — runtime version manager (node, elixir, erlang, rebar; config/mise/config.toml).
# Placement is load-bearing, in both directions:
#   • AFTER `brew shellenv` and AFTER ~/.zshrc.local. mise prepends its tool bins to
#     PATH as it stands the moment it runs, so anything that prepends later wins over
#     it. Homebrew ships a node of its own, and .zshrc.local is where a machine adds
#     keg-only/handrolled bins — activating earlier would let either shadow mise.
#   • BEFORE zoxide, which has to stay last. No conflict: mise PREPENDS
#     _mise_hook_precmd / _mise_hook_chpwd to the hook arrays rather than appending,
#     so zoxide's own chpwd hook is never displaced.
# Guarded by `command -v` so a fresh clone before ./install.sh doesn't error.
command -v mise >/dev/null && eval "$(mise activate zsh)"

# Zoxide last — its doctor warns if anything adds hooks after it.
# _ZO_DOCTOR=0 silences a spurious "init not at end" warning that fires every
# shell even when init is correctly placed last (see zoxide init zsh source).
export _ZO_DOCTOR=0
command -v zoxide >/dev/null && eval "$(zoxide init zsh --cmd cd)"
