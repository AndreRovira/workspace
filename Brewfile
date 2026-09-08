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

# AI / coding
brew "sst/tap/opencode"   # third-party tap — install.sh runs `brew trust --tap sst/tap` first (Homebrew 6+)
brew "node@22", link: true   # Node LTS: the caveman + ponytail Claude Code plugin hooks run under `node`
                             # (install.sh installs those plugins). Keg-only, so force-link. Bump when 22 EOLs (2027-04).
# Claude Code is installed via its native auto-updating installer in install.sh,
# not Homebrew — the brew cask doesn't auto-update. It's a cross-platform CLI.
