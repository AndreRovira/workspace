# Core CLI — cross-platform (macOS + Linux/WSL2 via Homebrew).
# macOS GUI apps live in Brewfile.macos; kanata is installed by install.sh when
# you opt in. Both are macOS-only.

# Shell
brew "starship"
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"

# Navigation
brew "zoxide"
brew "fzf"
brew "eza"
brew "bat"
brew "ripgrep"
brew "fd"

# Editor + git
brew "neovim"
brew "lazygit"
brew "git"
brew "gh"

# Multiplexer + terminal agents
brew "zellij"
brew "herdr"        # terminal agent multiplexer (herdr.dev)

# Runtimes — mise owns node/elixir/erlang/rebar for interactive shells; the versions
# live in config/mise/config.toml (symlinked by install.sh). Nothing here may pull a
# language runtime in *as a dependency* — two on PATH and the winner depends on rc
# ordering. The one deliberate exception is node@22 below: mise only reaches PATH via
# `mise activate` in .zshrc, so processes that never source it (plugin hooks, editors,
# GUI-spawned tools) need a node that is simply always there. mise still wins in an
# interactive shell — it is activated last, and prepends.
brew "mise"

# AI / coding
# opencode from its own tap — upstream's recommended channel, and a self-contained
# release binary. The homebrew-core formula is a version behind AND `depends_on
# "node"`, which would plant a second node in $HOMEBREW_PREFIX/bin for mise to
# fight. The tap moved sst → anomalyco; the old sst/tap name resolves today only
# through GitHub's rename redirect, so use the current one. `tap` must precede the
# formula: brew bundle walks this file in order.
# `trusted: true` is required, not decoration: Homebrew 6 refuses to load formulae
# from third-party taps until they are trusted, and `brew bundle` applies these
# markers before it fetches anything — so a fresh machine works with no pre-tap
# step and no interactive prompt.
tap "anomalyco/tap", trusted: true
brew "anomalyco/tap/opencode", trusted: true
# Node LTS: the caveman + ponytail Claude Code plugin hooks run under `node`, and
# they are spawned without an interactive shell — so mise's node is not on their
# PATH and this one has to be. Keg-only, so force-link. Bump when 22 EOLs (2027-04).
brew "node@22", link: true
# Claude Code is installed via its native auto-updating installer in install.sh,
# not Homebrew — the brew cask doesn't auto-update. It's a cross-platform CLI.
