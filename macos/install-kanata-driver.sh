#!/usr/bin/env bash
# Install the Karabiner DriverKit VirtualHIDDevice driver that kanata needs.
#
# WHY THIS EXISTS (and why we do NOT install the karabiner-elements cask):
#   kanata emits its remapped keystrokes through Karabiner's DriverKit virtual
#   keyboard. The daemon and kanata talk over a versioned "client_protocol_version",
#   and kanata is built against a SPECIFIC driver version. Full Karabiner-Elements
#   bundles + AUTO-UPDATES that driver. When it jumped to protocol 7 (driver
#   v8.0.0), kanata 1.11/1.12 — which speak protocol 5 (driver v6.2.0) — could no
#   longer connect, and since kanata seizes the built-in keyboard, the keyboard
#   went dead with no error beyond "connect_failed asio.system:2" in its log.
#   So we pin the standalone driver here and never let Karabiner-Elements manage it.
#
# VERSION LOCK: bump KARABINER_DRIVER_VERSION only when kanata's release notes
# change "The supported Karabiner driver version in this release is vX.Y.Z"
# (https://github.com/jtroo/kanata/releases). As of kanata 1.11/1.12 it is 6.2.0.
set -euo pipefail

KARABINER_DRIVER_VERSION="6.2.0"   # kanata 1.11/1.12 -> client_protocol_version 5
PKG_URL="https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/releases/download/v${KARABINER_DRIVER_VERSION}/Karabiner-DriverKit-VirtualHIDDevice-${KARABINER_DRIVER_VERSION}.pkg"
PKG="/tmp/Karabiner-DriverKit-VirtualHIDDevice-${KARABINER_DRIVER_VERSION}.pkg"
MGR="/Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager"

log() { printf '\n▶ %s\n' "$*"; }

if [ "$(id -u)" = 0 ]; then
  echo "Run as your normal user (this script calls sudo itself), not with sudo."; exit 1
fi

log "Downloading Karabiner driver v${KARABINER_DRIVER_VERSION}…"
curl -fL --progress-bar -o "$PKG" "$PKG_URL"

log "Verifying the package is Apple-notarized (team G43BCU2T37, pqrs.org)…"
if ! pkgutil --check-signature "$PKG" | grep -q "Notarization: trusted"; then
  echo "Signature/notarization check FAILED — refusing to install. Delete $PKG and retry."; exit 1
fi

log "Installing the driver (sudo)…"
sudo installer -pkg "$PKG" -target /

# On a machine that already has a NEWER driver active (e.g. one that KE installed),
# macOS won't downgrade on a plain activate. Deactivate first, reboot, then re-run
# this script. On a clean machine, activate just works.
log "Activating the driver (sudo)…"
sudo "$MGR" activate

cat <<'EOF'

▶ Two manual steps remain (a system extension can't be fully scripted):
   1. APPROVE: System Settings > General > Login Items & Extensions >
      Driver Extensions  ->  enable "pqrs.org".
   2. REBOOT (also finalizes the extension swap).

After reboot, verify the driver speaks the version kanata expects:
   grep -m1 client_protocol_version /var/log/karabiner/virtual_hid_device_service.log
     -> want:  client_protocol_version 5

If a NEWER driver was already active and this didn't take, run:
   sudo "/Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager" deactivate
   # reboot, then re-run this script.
EOF
