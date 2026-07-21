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
| `config/` | Mirror of `~/.config/` — ghostty, kanata, nvim, starship, zellij |
| `macos/defaults.sh` | Sensible system defaults |
| `macos/install-kanata-driver.sh` | Installs the pinned Karabiner DriverKit driver kanata needs |
| `macos/com.local.kanata.plist` | LaunchDaemon: kanata (homerow mods) |
| `macos/com.local.karabiner-vhidd.plist` | LaunchDaemon: Karabiner virtual-HID daemon (kanata's output path) |
| `config/karabiner/` | Legacy Karabiner-Elements config — kept only to document the old Glove80 Cmd↔Ctrl swap (see §3) |
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

### 3. Glove80 Cmd↔Ctrl swap

The Glove80 (`vendor_id 5824 / product_id 10203`) has its Command and Control
keys swapped so its effective modifiers match everything else. Karabiner-Elements
used to do this (`config/karabiner/karabiner.json`, kept for reference), but we no
longer install it (see §4 for why).

**Current setup — macOS native (manual, per machine):** System Settings →
Keyboard → Keyboard Shortcuts… → Modifier Keys → pick "Glove80" in the device
dropdown → set Command→Control and Control→Command. This is a system preference,
not captured in this repo, so redo it on a fresh machine.

Alternative: bake the swap into the **Glove80 firmware** (MoErgo Layout Editor →
flash) — OS-independent and set-and-forget, since the Glove80 already runs its
homerow mods in ZMK.

Do **not** reinstall Karabiner-Elements to get this back — it's exactly what
broke kanata (§4).

### 4. Kanata setup (homerow mods)

Kanata remaps the built-in keyboard (and the "Gaming Keyboard") for homerow mods
and emits the result through Karabiner's **DriverKit VirtualHIDDevice** driver.
Two things run as **LaunchDaemons** (root at boot — no sudo wrapper, no NOPASSWD):
kanata itself, and the Karabiner virtual-HID daemon kanata sends output to.

> **Version lock — read before touching the driver.** kanata is built against a
> specific Karabiner driver `client_protocol_version`. Full Karabiner-Elements
> bundles that driver and **auto-updates** it; when it moved to protocol 7 (driver
> v8.0.0), kanata (protocol 5 / driver **v6.2.0**) could no longer connect and the
> built-in keyboard went dead — the only clue being `connect_failed asio.system:2`
> spamming `/tmp/kanata.stdout.log`. So we install the **standalone driver at a
> pinned version** and never install Karabiner-Elements. Bump the version in
> `macos/install-kanata-driver.sh` only when kanata's release notes change the
> supported driver version.

**a. Install the pinned Karabiner driver**, then approve + reboot as the script
tells you:

```sh
./macos/install-kanata-driver.sh
```

**b. Install both LaunchDaemons** (root-owned, mode 644):

```sh
for p in com.local.karabiner-vhidd com.local.kanata; do
  sudo install -m 644 -o root -g wheel "macos/$p.plist" "/Library/LaunchDaemons/$p.plist"
  sudo launchctl bootstrap system "/Library/LaunchDaemons/$p.plist"
done
```

Start order doesn't matter at boot: kanata retries until the virtual-HID daemon's
socket exists, so whichever comes up first, it converges.

**c. Grant Input Monitoring** in **System Settings → Privacy & Security → Input
Monitoring** for `/opt/homebrew/bin/kanata` (click `+`, ⌘⇧G, paste the path).

If your username is not `andre`, edit the `--cfg` path inside
`com.local.kanata.plist` before installing.

**Logs & health:** kanata → `/tmp/kanata.stdout.log` (+ `.stderr.log`); Karabiner
daemon → `/var/log/karabiner/virtual_hid_device_service.log`. A healthy kanata log
shows `entering the processing loop` and `driver version matched: true`, with no
`connect_failed`. The daemon log should show `client_protocol_version 5`.

**Uninstall:**
```sh
for p in com.local.kanata com.local.karabiner-vhidd; do
  sudo launchctl bootout system "/Library/LaunchDaemons/$p.plist"
  sudo rm "/Library/LaunchDaemons/$p.plist"
done
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
