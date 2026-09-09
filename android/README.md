# Android stack (Termux)

Goal: reach the VPS (ssh, herdr, VNC) from the phone **without** using Android's
single VPN slot, so ProtonVPN stays on.

## Why it looks like this

- Termux from **F-Droid** (the Play Store build is abandoned).
- Stock `tailscaled` cannot run in Termux on Android 13+: the kernel denies netlink
  to non-root apps (`netmon.New: netlinkrib: permission denied`). The community
  build [bropines/tailscale-termux-cli](https://github.com/bropines/tailscale-termux-cli)
  patches around it and runs in **userspace mode**: no VPN interface, just a local
  SOCKS5 proxy (`127.0.0.1:1055`, credentials in `~/.tailscale/socks5.env`).
- Because there is no interface, apps can't dial `100.x` directly. `ssh` goes through
  `proxychains4`; VNC goes through an `ssh -L` tunnel and the VNC app connects to
  `localhost:5901`.
- Termux `nmap` ships no `ncat`, and openbsd `nc` can't do SOCKS auth
  non-interactively — hence proxychains.
- The phone gets its own ssh key, added to the VPS `authorized_keys` as a separate
  line, so it can be revoked without touching the laptop.

## Setup

```sh
curl -fsSL https://raw.githubusercontent.com/AndreRovira/workspace/main/android/termux-setup.sh | bash
```

Then, once:

1. `tailscale up --hostname phone --accept-dns=false` → open the URL → GitHub → Connect.
2. `cat ~/.ssh/id_ed25519.pub` → add that line to the VPS `~/.ssh/authorized_keys`.
3. Reopen Termux (tailscaled auto-starts from `.bashrc`).

## Daily use

| Command | Does |
|---------|------|
| `vps` | ssh into the VPS through the tailnet (`proxychains4 ssh vps`) — then `herdr` |
| `vnc` | tunnel `localhost:5901` → VPS desktop; keep it open, connect AVNC to `localhost:5901`, password `vps` |

Typing: Termux's extra-keys row has CTRL/ALT/arrows for herdr's `Ctrl+B` prefix.
Telegram bot on the VPS is the low-friction path from the phone; VNC is for watching.
