#!/usr/bin/env bash
# Sensible macOS defaults for a developer machine.
# Safe to re-run; each command is idempotent.
set -euo pipefail

# Keyboard ----------------------------------------------------------------
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Disable autocorrect & smart substitutions (they fight code)
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Trackpad ----------------------------------------------------------------
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write -g com.apple.mouse.tapBehavior -int 1

# Finder ------------------------------------------------------------------
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"   # search current folder
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Don't litter network/USB volumes with .DS_Store
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Screenshots in ~/Pictures/Screenshots, no shadow on window grabs
mkdir -p "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture disable-shadow -bool true

# Dock --------------------------------------------------------------------
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.2
defaults write com.apple.dock show-recents -bool false

# Spaces / animations -----------------------------------------------------
# Reduce Motion: kills the desktop-switch swoosh animation (instant feel)
defaults write com.apple.universalaccess reduceMotion -bool true
# Don't auto-rearrange spaces by most-recent-use
defaults write com.apple.dock mru-spaces -bool false

# Restart affected services so changes take effect
killall Finder Dock SystemUIServer 2>/dev/null || true

echo "✓ macOS defaults applied (some changes require logout/restart to fully apply)"
