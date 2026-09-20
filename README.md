# workspace

Personal dotfiles + bootstrap for macOS and Linux/WSL2. Optimized for a clean home
directory using XDG base directories. No work tooling. External editor/agent tools install fresh
and self-configure on first launch (Claude Code and opencode everywhere; VS Code
on macOS when you opt into GUI apps) — of the editors, only Neovim's config is
tracked here. The one exception: `install.sh` also installs two Claude Code
plugins, [caveman](https://github.com/JuliusBrussee/caveman) and
[ponytail](https://github.com/DietrichGebert/ponytail) (see §6).

`install.sh` auto-detects the OS: macOS gets the full stack (and prompts for the
optional GUI apps / kanata / system defaults); Linux/WSL2 gets the cross-platform
core (CLI tools + shell/editor/git configs), skipping everything macOS-specific.

## What's in here

| Path | Purpose |
|------|---------|
| `Brewfile` | Core CLI packages — cross-platform (macOS + Linux/WSL2) |
| `Brewfile.macos` | macOS-only GUI apps (Ghostty, VS Code, Alt-Tab, Nerd Font) — opt-in |
| `install.sh` | Idempotent bootstrap; auto-detects OS, prompts for macOS extras |
| `home/` | `.zshenv`, `.zshrc`, `.gitconfig` — symlinked into `$HOME` |
| `config/` | Mirror of `~/.config/` — nvim, zellij, starship, herdr, mise everywhere; ghostty and kanata are macOS-only |
| `macos/defaults.sh` | Sensible system defaults |
| `macos/install-kanata-driver.sh` | Installs the pinned Karabiner DriverKit driver kanata needs |
| `macos/com.local.kanata.plist` | LaunchDaemon: kanata (homerow mods) |
| `macos/com.local.karabiner-vhidd.plist` | LaunchDaemon: Karabiner virtual-HID daemon (kanata's output path) |
| `config/karabiner/` | Legacy Karabiner-Elements config — kept only to document the old Glove80 Cmd↔Ctrl swap (see §3) |
| `ssh/config.example` | Multi-account GitHub + VPS host aliases (NOT auto-installed) |
| `Brewfile.vps` | Opt-in VPS access tools: Tailscale app, TigerVNC viewer |
| `android/` | Phone stack: Termux + userspace Tailscale + ssh/VNC to the VPS |

## Bootstrap a fresh machine

```sh
git clone https://github.com/AndreRovira/workspace.git ~/code/workspace
cd ~/code/workspace
./install.sh
```

The script is safe to re-run. Anything real already sitting at a target path — a
file *or* a whole directory like `~/.config/nvim` — is moved aside to `*.backup`
(never overwritten; a second run timestamps it) before the symlink is created.
Existing symlinks are just repointed, so re-runs are silent. Directories are moved
wholesale, not merged — pull anything you want to keep out of `*.backup` by hand.

**Before your first new zsh, copy your shell history across.** `.zshenv` points
`HISTFILE` at `$XDG_STATE_HOME/zsh/history`, so a pre-existing `~/.zsh_history`
looks like it vanished. This applies on macOS as much as on Linux/WSL2 — zsh has
been the default macOS login shell since Catalina, so there is almost always a
history file to bring over. Do it *before* opening a new zsh, or you will be
merging two files by hand:

```sh
mkdir -p ~/.local/state/zsh
if [ -f ~/.zsh_history ] && [ ! -e ~/.local/state/zsh/history ]; then
  cp -p ~/.zsh_history ~/.local/state/zsh/history
fi
```

`cp`, not `mv`, and it refuses to overwrite an existing destination: keep
`~/.zsh_history` until a new shell proves the entries arrived (`history -i | head`
should list the old dates), then delete it by hand. Copy it as a file — never
`cat`/redirect — the history format is metafied bytes, not text. The timestamps
survive only because `home/.zshrc` sets `EXTENDED_HISTORY`; without that option zsh
rewrites the file at the first prompt and strips every `: <epoch>:<elapsed>;` prefix
(command text survives, dates do not), so don't drop it.

**Language runtimes come from mise, not Homebrew.** `Brewfile` installs `mise`, and
`install.sh` symlinks `config/mise/config.toml` onto `~/.config/mise/config.toml` —
but that file only *declares* node/elixir/erlang/rebar. Bootstrap does not download
them, so materialise them once per machine:

```sh
mise install
```

Until then `mise ls` lists them as `(missing)` and `node` falls back to whatever
else is on PATH. `home/.zshrc` activates mise after `brew shellenv` and after
`~/.zshrc.local`, so mise's toolchain beats Homebrew's — confirm with `command -v
node`, which must resolve under `~/.local/share/mise/installs/`. `mise use -g`
edits the config in place through the symlink, so a version bump shows up as a
diff in this repo; commit it. Per-project pins belong in the project's own
`mise.toml`, never here.

**On macOS** it installs the core CLI, then asks whether to install the GUI apps
(`Brewfile.macos`), set up kanata, and apply the macOS system defaults. It also asks (default no) whether to install the VPS access tools
(`Brewfile.vps`) — only say yes on machines meant to reach the VPS. Pre-answer
non-interactively with env vars (`INSTALL_GUI` / `INSTALL_KANATA` / `INSTALL_DEFAULTS` /
`INSTALL_VPS`), e.g. `INSTALL_KANATA=0 INSTALL_GUI=1 INSTALL_DEFAULTS=0 INSTALL_VPS=0 ./install.sh`.

**On Linux / WSL2** it installs only the cross-platform core (CLI tools + shell,
Neovim, zellij, starship, herdr, git configs) — no GUI casks, no Ghostty, no kanata,
no macOS system defaults. Homebrew on Linux (Linuxbrew) needs build prerequisites
first: `sudo apt install -y build-essential procps curl file git`.

### WSL2 + Windows Terminal checklist

The host terminal is a Windows app, so several things live outside this repo. Do
these once per machine, in any order.

- **zsh as the login shell.** Ubuntu ships bash, and none of these configs load
  under bash (macOS already uses zsh — nothing to do there):
  ```sh
  sudo apt install -y zsh && chsh -s "$(which zsh)"
  ```
  WSL has no "log out". The change lands in the *next* shell WSL starts, so just
  open a new Windows Terminal tab. If it still comes up as bash, restart the
  distro from PowerShell: `wsl.exe --shutdown`.

- **Nerd Font, installed on Windows.** Neovim, starship and zellij all draw Nerd
  Font glyphs, and the font cask is macOS-only. Install
  [JetBrainsMono Nerd Font](https://www.nerdfonts.com/font-downloads) **on the
  Windows side** (installing it inside WSL does nothing — the glyphs are rendered
  by Windows Terminal), then Windows Terminal → Settings → Profiles → **Defaults**
  → Appearance → Font face → `JetBrainsMono Nerd Font`. Set it on *Defaults* so
  every profile inherits it.

- **Unbind Windows Terminal's Alt shortcuts.** WT's own tab/pane shortcuts are
  `Ctrl+Shift+<key>`, so every `Ctrl+<key>` this repo binds passes straight
  through, and WT's shipped defaults bind no plain `Alt+<letter>` at all — which is
  why the `Alt j/k/l/;` nav layer needs no fixing. What *does* collide is the
  Alt+arrow and Alt+Shift layer: WT binds `Alt+←/↓/↑/→` to `moveFocus`,
  `Alt+Shift+←/↓/↑/→` to `resizePane`, and `Alt+Shift++` / `Alt+Shift+-` to
  `duplicatePane`. Two of those hit this config. On a US layout `Alt` `+` *is*
  `alt+shift+plus`, so zellij's `Alt +` resize never arrives (use `Alt =`, bound to
  the same action). The arrows are sneakier: WT only consumes them when the tab
  holds more than one **WT** pane, so zellij focus nav works perfectly until the
  first WT split and then silently dies in one direction.

  Unbind the five in Settings → Actions, or edit the JSON behind Settings →
  *Open JSON file*. That file holds only your overrides, so it will usually already
  have a `"keybindings"` array — merge these entries into it rather than adding a
  second array, and add a comma to whichever entry you paste behind:
  ```jsonc
  // Windows Terminal 1.21+. Older builds have no binding IDs; there the unbind
  // form is  { "command": "unbound", "keys": "alt+left" }  and the array is
  // called "actions" instead of "keybindings".
  "keybindings": [
      { "id": null, "keys": "alt+left"  },
      { "id": null, "keys": "alt+right" },
      { "id": null, "keys": "alt+up"    },
      { "id": null, "keys": "alt+down"  },
      { "id": null, "keys": "alt+shift+plus" }
  ]
  ```
  Related, and worth knowing because it is *not* a WT default: out of the box WT
  copies on `Ctrl+Shift+C` / `Ctrl+Insert` / `Enter` and pastes on `Ctrl+Shift+V` /
  `Shift+Insert` — plain `Ctrl+C` and `Ctrl+V` are unbound. If you add your own
  `ctrl+v` → paste binding, note that WT's paste action *always* consumes its key
  (copy falls through when there is no selection, paste never does), so it costs
  you Neovim's `<C-v>` visual-block. Remove that binding to get visual block back;
  `Ctrl+Shift+V` pastes regardless.

- **The `code` command.** VS Code is a Windows install this repo never touches;
  WSL reaches it over interop. If `code` isn't on your PATH, add the Windows
  install directory in `~/.zshrc.local` — it's machine-specific, so it does not
  belong in `home/.zshrc`:
  ```sh
  # ~/.zshrc.local
  export PATH="$PATH:/mnt/c/Users/<you>/AppData/Local/Programs/Microsoft VS Code/bin"
  ```
  Put it in `~/.zshrc.local`, not `~/.zprofile`: `.zprofile` is read only by *login*
  shells, so `code` would be missing from every zellij pane and every nested shell.
  Install the **WSL** extension in VS Code so `code .` opens the folder as a
  remote-WSL window instead of a `\\wsl$\…` Windows-path window.

- **Clipboard.** Windows Terminal accepts OSC 52, which is how zellij copies by
  default — so no `copy_command` is needed and none is set. WT also has
  `copyOnSelect` (its equivalent of Ghostty's `copy-on-select`), but unlike Ghostty
  it ships **off**: set `"copyOnSelect": true` in `settings.json` if you want it. If
  a zellij copy silently does nothing (older Windows Terminal, plain conhost, or VS
  Code's integrated terminal), uncomment `copy_command "clip.exe"` in
  `config/zellij/config.kdl`. For one-off piping, `clip.exe` is the WSL stand-in for
  `pbcopy`.

- **systemd.** Nothing in the core stack requires it, but `brew services` (e.g.
  `brew services start herdr`) drives `systemctl --user` on Linux and needs a
  systemd session. Enable it once in `/etc/wsl.conf`, then `wsl.exe --shutdown`:
  ```ini
  [boot]
  systemd=true
  ```
  Without systemd, run the server in the foreground instead: `herdr server`.

- **MTU, if a VPN runs on Windows.** With a WireGuard tunnel up on the host
  (ProtonVPN here), WSL2's `eth0` keeps an MTU the tunnel can't carry, and the
  failure is a black hole, not an error: TCP connects fine, DNS resolves, and then
  every TLS handshake hangs — `brew` sits on its API fetch, `git clone` over HTTPS
  stalls, `curl https://github.com` returns `000`. The `claude plugin marketplace
  add owner/repo` form makes it worse by falling back to SSH and reporting *that*
  failure, so it reads as a missing key. Confirm before touching anything else:
  ```sh
  ip link show eth0 | grep -o 'mtu [0-9]*'          # 1420 or 1500 = suspect
  ping -c1 -W3 -M do -s 1372 140.82.113.3          # github.com; 1400-byte frame
  ```
  A reply means the MTU is fine. `100% packet loss` with the VPN up is the black
  hole — measured ceiling on this setup is between 1392 and 1400, so 1380 leaves
  a margin. Fix it for the running session and make it stick across
  `wsl.exe --shutdown` by adding a `command` line to the same `[boot]` block
  (WSL ≥ 0.67.6; it runs as root before any shell, so `eth0` already exists):
  ```sh
  sudo ip link set eth0 mtu 1380
  ```
  ```ini
  [boot]
  systemd=true
  command = ip link set eth0 mtu 1380
  ```
  The cost with the VPN *down* is a few percent of throughput on large transfers;
  nothing else notices. Prefer this over `.wslconfig` on the Windows side, which has
  no MTU knob in NAT mode.

- **`~/.zshrc.local`.** Everything machine-specific — Windows interop PATHs, extra
  keg-only bins, secrets — goes here. `.zshrc` sources it near the end, after
  starship/fzf/plugins, so it can override anything the repo sets *except* the last
  two lines, which run after it on purpose:
  - `mise activate zsh` — deliberately after, so mise's node/elixir/erlang beat
    anything `.zshrc.local` prepends. Don't run `mise activate` there too; it just
    re-does the same work. Version changes go in `config/mise/config.toml`.
  - `zoxide init zsh --cmd cd` — the very last line, so it would clobber a `cd`
    alias or function defined in `.zshrc.local`. Don't define `cd` or re-run
    `zoxide init` there.

  See "Manual follow-ups → 5. Local secrets".

## Updating an existing machine

Pull the repo; changes propagate by type:

```sh
cd ~/code/workspace && git pull
```

- **Dotfiles & `~/.config` entries** (`home/*`, nvim, zellij, starship, herdr —
  plus ghostty on macOS) are symlinks into this repo, so edits go live the instant
  `git pull` rewrites the files. What it takes for each program to *notice*:
  - **Shell:** open a new shell (or `exec zsh`).
  - **Neovim:** restart `nvim`. A new buffer is not enough — `lua/config/keymaps.lua`
    is loaded once on `VeryLazy` and lazy.nvim resolves the `lua/plugins/*.lua`
    specs at startup. If a pull adds or removes a plugin, also run `:Lazy sync`.
  - **zellij and herdr:** both read their config at process start, so start a new
    session — detach + reattach is not enough.

  **Kanata (macOS) is the other exception:** `config/kanata/kanata.kbd` is read by
  the LaunchDaemon at launch, so after it changes restart the daemon:
  `sudo launchctl kickstart -k system/com.local.kanata`.
- **Claude Code plugins** (caveman, ponytail) are git clones under `~/.claude/plugins/`,
  not part of this repo — update them with
  `claude plugin update caveman && claude plugin update ponytail`. A fresh machine
  gets them from `./install.sh`.
- **Brewfile packages & macOS defaults:** re-run `./install.sh` (safe to re-run). Note
  `brew bundle` only *adds* — a formula removed from the Brewfile stays installed until
  you `brew uninstall` it by hand.
- **Kanata driver & LaunchDaemons are NOT reapplied by `install.sh`.** If a pull
  changes `macos/install-kanata-driver.sh` (a `KARABINER_DRIVER_VERSION` bump) or a
  `macos/*.plist`, apply it by hand: re-run the driver script for a version bump,
  or re-copy the changed plist and re-bootstrap it (see §4b and the Uninstall
  snippet in §4). A driver↔kanata version mismatch is what silently kills the
  built-in keyboard, so don't skip this after a driver bump.

## Manual follow-ups (one-time)

`§N` elsewhere in this file always means one of the numbered subsections below.

### 1. Personal email in git

`home/.gitconfig` already carries the personal email. Only change it (and commit &
push) if you're setting this account up under a different identity.

### 2. SSH key for personal GitHub

Skip the keygen if you already have a personal key — an existing `~/.ssh/id_ed25519`
does the job; just use its name below.

```sh
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_personal -C "personal"
cat ~/.ssh/id_ed25519_personal.pub   # copy the output, add it at github.com/settings/keys
# clipboard: macOS `pbcopy <` · WSL2 `clip.exe <` · Wayland `wl-copy <` · X11 `xclip -selection clipboard <`
```

Copy the relevant block from `ssh/config.example` into `~/.ssh/config`, creating that
file if it doesn't exist — nothing here installs it — and point `IdentityFile` at
whichever key you're actually using.

Then run `gh auth login` to authenticate the GitHub CLI — this activates the git
credential helper for HTTPS remotes (SSH remotes don't need it).

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
> spamming `/var/log/kanata/kanata.out.log`. So we install the **standalone driver at a
> pinned version** and never install Karabiner-Elements. Bump the version in
> `macos/install-kanata-driver.sh` only when kanata's release notes change the
> supported driver version.

**a. Install the pinned Karabiner driver**, then approve + reboot as the script
tells you:

```sh
./macos/install-kanata-driver.sh
```

**b. Install both LaunchDaemons** (root-owned, mode 644). First create the root-owned
log dir they write to (the daemons log to `/var/log/kanata`, not world-writable `/tmp`):

```sh
sudo install -d -o root -g wheel -m 755 /var/log/kanata
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

> **Security note:** these daemons run as root, and kanata's binary lives in the
> user-writable Homebrew prefix — so code running as your user could replace it and
> gain root at the next relaunch. Accepted here (single-user machine). To fully lock
> it down, copy kanata to a root-owned path (e.g. `/usr/local/sbin`) and point
> `com.local.kanata.plist`'s `ProgramArguments` there, re-copying after each
> `brew upgrade kanata`.

**Logs & health:** kanata → `/var/log/kanata/kanata.out.log` (+ `.err.log`); Karabiner
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

Anything secret goes in `~/.zshrc.local` (outside the repo, never tracked; sourced by `.zshrc`):

```sh
# ~/.zshrc.local
export OPENAI_API_KEY="sk-..."
```

### 6. Apps installed but not configured here

opencode installs via `Brewfile` (core) from upstream's own tap, `anomalyco/tap` —
declared in the Brewfile so `brew bundle` taps it first, and preferred over the
homebrew-core formula because that one is a release behind and `depends_on "node"`,
which would put a second node on PATH for mise to fight. VS Code installs via
`Brewfile.macos` (macOS GUI, opt-in — on WSL2 VS Code is a Windows install this repo
never touches); Claude Code via its native auto-updating installer in `install.sh`.
None of their configs are synced — sign in / configure each on first launch, fresh
start by design.

### 7. herdr and zellij are alternatives, not a stack

Both install from `Brewfile` and both are configured here — `config/zellij/config.kdl`
and `config/herdr/config.toml`, symlinked by `install.sh`. They deliberately claim the
same Ctrl chords, so nesting them means the outer one eats every key before the inner
one sees it. Run one or the other.

The only Claude Code customisation `install.sh` applies is two user-scope plugins,
installed from their GitHub marketplaces (idempotent, skipped if `claude` isn't on
PATH yet):

| Plugin | What it does | Toggle |
|--------|--------------|--------|
| [caveman](https://github.com/JuliusBrussee/caveman) | Terse replies: drops articles, filler, hedging. Code/diffs untouched. | `/caveman lite\|full\|ultra\|off`, or say "normal mode" |
| [ponytail](https://github.com/DietrichGebert/ponytail) | Minimal code: YAGNI ladder (exists already? stdlib? one line?) before writing anything. Validation/security/error handling exempt. | `/ponytail lite\|full\|ultra\|off`, or say "stop ponytail" |

Both inject their ruleset via a `SessionStart` hook — that hook is the point:
without it they never self-activate ([JetBrains' A/B test](https://blog.jetbrains.com/ai/2026/07/ponytail-skill-claude-tested/)).
Measured savings there were modest (ponytail ≈ −10 % cost, caveman ≈ −8 % output
tokens), with no quality change. Always-on context cost per session (ruleset +
skill listings, from `claude plugin details <name>`): ponytail ≈ 2.5k tokens,
caveman ≈ 3k. Hooks need `node` (Brewfile). Per-machine default
mode lives in `~/.config/{caveman,ponytail}/config.json` (`{"defaultMode":"lite"}`),
and caveman also honours a per-repo `<repo>/.caveman/config.json`, handy for
`{"defaultMode":"off"}` in repos where replies get pasted into tickets. Remove with
`claude plugin uninstall <name>` — they never touch this repo.

### 7. VPS access (only if you opted into `INSTALL_VPS`)

The VPS has no public ports; everything goes over the Tailscale tailnet
(`andrerovira.github`). Its config-as-code lives in
[`AndreRovira/vps`](https://github.com/AndreRovira/vps) (box `CLAUDE.md` = what runs
there); ops notes in `~/notes/technology/vps.md`.

1. Open Tailscale.app → log in with GitHub → the VPS shows up as `vps` (100.114.65.15).
2. Copy the `vps` blocks from `ssh/config.example` into `~/.ssh/config`; the key is
   `~/code/personal/openclaw/ssh-key-2026-04-07.key` (or add this machine's own
   key to the VPS `~/.ssh/authorized_keys` — preferred, revocable per machine).
3. `ssh vps` · `herdr --remote vps` (persistent workspace) · desktop:
   `open vnc://100.114.65.15:5901` or TigerVNC Viewer, password `vps` (tailnet is the gate).

`vps-public` (159.54.155.19) is break-glass only: it works after re-adding the
OCI Security List ingress rule for TCP 22.

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
~/.zshrc.local     (machine-only, never tracked)
~/.config/nvim/      → workspace/config/nvim/       (symlink)
~/.config/zellij/    → workspace/config/zellij/     (symlink)
~/.config/starship.toml → workspace/config/starship.toml (symlink)
~/.config/herdr/config.toml → workspace/config/herdr/config.toml (symlink)
~/.config/mise/config.toml → workspace/config/mise/config.toml (symlink)
~/.config/git/local.gitconfig (machine-only, never tracked)
~/.local/state/zsh/history    (shell history — XDG, NOT ~/.zsh_history)
~/.cache/zsh/zcompdump        (completion cache — XDG, NOT ~/.zcompdump)
~/.ssh/config      (machine-only, edited by hand)
~/.ssh/id_ed25519_*    (machine-only, never committed)

macOS only — install.sh creates none of these on Linux/WSL2:
~/.config/ghostty/   → workspace/config/ghostty/    (symlink)
~/.config/kanata/    → workspace/config/kanata/     (symlink, only if you opt in)
/Library/LaunchDaemons/com.local.kanata.plist          (copy of macos/…, re-copy on change)
/Library/LaunchDaemons/com.local.karabiner-vhidd.plist (copy of macos/…, re-copy on change)
Karabiner DriverKit driver   (system-wide, installed by macos/install-kanata-driver.sh; not symlinked)
```

## Editing configs

Because everything is a symlink, editing a file in `~/.config/<tool>/` is
editing the file in this repo. Commit and push from inside the repo. There's no
two-way sync to manage.
