# workspace

Personal Mac dotfiles + bootstrap. Optimized for a clean home directory using
XDG base directories. No work tooling, no AI/editor configs synced — those tools
install fresh and configure themselves on first launch.

## What's in here

| Path | Purpose |
|------|---------|
| `Brewfile` | Declarative install of every CLI/cask |
| `install.sh` | Idempotent bootstrap (Homebrew → packages → symlinks → macOS defaults) |
| `home/` | `.zshenv`, `.zshrc`, `.gitconfig` — symlinked into `$HOME` |
| `config/` | Mirror of `~/.config/` — ghostty, karabiner, kanata, nvim, starship, zellij |
| `macos/defaults.sh` | Sensible system defaults |
| `macos/com.local.kanata.plist` | LaunchAgent for Kanata |
| `ssh/config.example` | Multi-account GitHub recipe (NOT auto-installed) |

## Bootstrap a fresh Mac

```sh
git clone <this-repo> ~/code/personal/workspace
cd ~/code/personal/workspace
./install.sh
```

The script is safe to re-run; existing dotfiles get backed up to `*.backup`
before being replaced with symlinks.

## Manual follow-ups (one-time)

### 1. Personal email in git

Edit `home/.gitconfig` and replace the placeholder email. Commit & push.

### 2. SSH key for personal GitHub

```sh
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_personal -C "personal"
pbcopy < ~/.ssh/id_ed25519_personal.pub  # then paste at github.com/settings/keys
```

Copy the relevant block from `ssh/config.example` into `~/.ssh/config`.

### 3. Karabiner-Elements

Open it once. Grant Input Monitoring + Accessibility when prompted. The
`karabiner.json` config (Cmd↔Ctrl swap on the external keyboard) loads
automatically from `~/.config/karabiner/`.

### 4. Kanata setup (homerow mods)

Kanata needs the Karabiner DriverKit VirtualHIDDevice driver (installed by the
`karabiner-elements` cask) and runs as a **LaunchDaemon** so launchd starts it
as root at boot — no sudo wrapper, no NOPASSWD rule.

**a. Install the LaunchDaemon** (root-owned, mode 644):

```sh
sudo install -m 644 -o root -g wheel \
  macos/com.local.kanata.plist /Library/LaunchDaemons/com.local.kanata.plist
sudo launchctl bootstrap system /Library/LaunchDaemons/com.local.kanata.plist
```

**b. Grant Input Monitoring** in **System Settings → Privacy & Security →
Input Monitoring** for `/opt/homebrew/bin/kanata` (click `+`, ⌘⇧G, paste the
path). Logs at `/tmp/kanata.stdout.log` and `/tmp/kanata.stderr.log`.

If your username is not `andre`, edit the `--cfg` path inside
`com.local.kanata.plist` before installing.

**Uninstall:**
```sh
sudo launchctl bootout system /Library/LaunchDaemons/com.local.kanata.plist
sudo rm /Library/LaunchDaemons/com.local.kanata.plist
```

### 5. Local secrets

Anything secret goes in `~/.zshrc.local` (gitignored, sourced by `.zshrc`):

```sh
# ~/.zshrc.local
export OPENAI_API_KEY="sk-..."
```

### 6. Apps installed but not configured here

VSCode, Claude Code, and opencode install via Brewfile but their configs are
**not** synced. Sign in / configure each on first launch — fresh start by design.

## Adding a second GitHub account

Say you want a `~/code/work-acme/` directory tied to a different GitHub account.
**Three local edits, zero changes to this repo:**

1. **New SSH key:**
   ```sh
   ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_acme -C "acme"
   ```
   Add the `.pub` key to that GitHub account.

2. **Append to `~/.ssh/config`:**
   ```
   Host github.com-acme
     HostName github.com
     User git
     IdentityFile ~/.ssh/id_ed25519_acme
     IdentitiesOnly yes
   ```

3. **Append to `~/.config/git/local.gitconfig`:**
   ```ini
   [includeIf "gitdir:~/code/work-acme/"]
       path = ~/.config/git/work-acme.gitconfig
   ```
   Then create `~/.config/git/work-acme.gitconfig`:
   ```ini
   [user]
       email = me@acme.com
   ```

Clone with `git clone git@github.com-acme:org/repo.git` into `~/code/work-acme/`.
Email and SSH key are now picked up automatically based on which subtree you're
in. Verify with `git config user.email` from inside the repo.

## File layout on the live machine

```
~/.zshenv          → workspace/home/.zshenv         (symlink)
~/.zshrc           → workspace/home/.zshrc          (symlink)
~/.gitconfig       → workspace/home/.gitconfig      (symlink)
~/.zshrc.local     (machine-only, gitignored)
~/.config/ghostty/   → workspace/config/ghostty/    (symlink)
~/.config/karabiner/ → workspace/config/karabiner/  (symlink)
~/.config/kanata/    → workspace/config/kanata/     (symlink)
~/.config/nvim/      → workspace/config/nvim/       (symlink)
~/.config/zellij/    → workspace/config/zellij/     (symlink)
~/.config/starship.toml → workspace/config/starship.toml (symlink)
~/.config/git/local.gitconfig (machine-only, gitignored)
~/.ssh/config      (machine-only, edited by hand)
~/.ssh/id_ed25519_*    (machine-only, never committed)
```

## Editing configs

Because everything is a symlink, editing a file in `~/.config/<tool>/` is
editing the file in this repo. Commit and push from inside the repo. There's no
two-way sync to manage.
