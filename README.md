# 📸 Shutter — Wayland‑first screenshot tool (Perl/GTK3)

Shutter is a powerful Linux screenshot app with an editor, session management, and uploads.
This fork modernizes Shutter with robust Wayland support, KDE Spectacle integration, and simpler packaging.
- Wayland backends: XDG Portal, GNOME Shell, KDE Spectacle, wlroots (grim+slurp), COSMIC
- GTK3 + GI stack (Perl 5) with GooCanvas2 and Gtk3::ImageView editor
- RPM spec for openSUSE; minimal AppImage recipe; Debian packaging still available
Fork: https://github.com/totoshko88/shutter

---
## ✨ Highlights
- Wayland‑ready with a smart backend chain and clean cancel/error handling
- KDE on Wayland: defaults to Spectacle when available; selection/full/window supported
- “Present main window after capture” enabled by default
- Preferences → Wayland: Auto • Prefer Spectacle (KDE) • Prefer COSMIC • Force Portal
- Power-user env flags: `SHUTTER_SKIP_PORTAL`, `SHUTTER_PREFER_COSMIC`, `SHUTTER_FORCE_PORTAL`, `SHUTTER_PORTAL_TIMEOUT_MS`

---
## 🧩 Backends (auto-detected)
- Portal: fullscreen + interactive selection
- GNOME Shell (org.gnome.Shell.Screenshot): window/full
- KDE Spectacle: selection/window/full
- wlroots: grim + slurp (fullscreen/selection)
- COSMIC: cosmic-screenshot (preferred on COSMIC sessions)

---
## 🚀 Install

### openSUSE RPM
Build locally from the included spec:
```bash
# Create source tarball from this tree and build
rpmbuild -ba packaging/opensuse/shutter.spec
# Install the resulting noarch RPM
sudo zypper in ~/rpmbuild/RPMS/noarch/shutter-*.noarch.rpm
```

### AppImage (thin)
Build a minimal AppImage (relies on system Perl/GTK3):

```bash
# Requires appimagetool in PATH
make install prefix=/tmp/Shutter.AppDir/usr
cp /tmp/Shutter.AppDir/usr/share/applications/shutter.desktop /tmp/Shutter.AppDir/shutter.desktop
printf '%s\n' '#!/bin/bash' 'set -e' 'HERE="$(dirname "$(readlink -f "$0")")"' \
	'export PATH="$HERE/usr/bin:$PATH"' 'exec "$HERE/usr/bin/shutter" "$@"' > /tmp/Shutter.AppDir/AppRun
chmod +x /tmp/Shutter.AppDir/AppRun
cp /tmp/Shutter.AppDir/usr/share/pixmaps/shutter.png /tmp/Shutter.AppDir/shutter.png
ARCH=$(uname -m) appimagetool /tmp/Shutter.AppDir "/tmp/Shutter-$ARCH.AppImage"
```

Run: `shutter`

---
## 🛠 Usage
- Modes: fullscreen, window, selection, websites
- Editor: shapes, text, arrow, pixelate, blur, icons
- Exports: clipboard and files; uploads (Imgur, Gyazo, FTP)

Tips:
- Debug logs: `SHUTTER_DEBUG=1 shutter`
- KDE+Wayland default backend is Spectacle; override in Preferences → Wayland

---
## 👤 Credits
- Founder: Mario Kemper
- Modernization & Wayland: Anton Isaiev (totoshko88) <totoshko88@gmail.com>
- More: `share/shutter/resources/credits`

---
## 📄 License
GPL-3.0-or-later
# 📸 Shutter — Modernized Wayland Fork

Shutter is a powerful Linux screenshot tool with an editor, session management, and uploads. This fork focuses on rock-solid Wayland support, updated deps, and easy packaging.

• Wayland-first backends: XDG Portal, GNOME Shell, KDE Spectacle, wlroots (grim+slurp), COSMIC
• Clean GTK3 + GI stack (Perl 5) with GooCanvas2 and Gtk3::ImageView
• Debian/Ubuntu .deb provided for quick install

---

## ✨ What’s different in this fork
- Reliable Wayland support with smart fallback chain
- New UI setting: choose Wayland backend (Auto / Prefer COSMIC / Force Portal)
- Env flags for power users (skip/force portal, timeouts)
- Silenced noisy Gtk warnings; guarded X11-only code on Wayland
- Updated packaging and docs

Fork: https://github.com/totoshko88/shutter

---

## 🧩 Backends (auto-detected)
- Portal: fullscreen + interactive selection
- GNOME Shell (org.gnome.Shell.Screenshot): window/full
- KDE Spectacle: window/full
- wlroots: grim + slurp (fullscreen/selection)
- COSMIC: cosmic-screenshot (preferred on COSMIC sessions)

Preferences → Wayland:
- Auto • Prefer COSMIC • Force Portal

Env flags:
- SHUTTER_SKIP_PORTAL, SHUTTER_PREFER_COSMIC, SHUTTER_FORCE_PORTAL
- SHUTTER_PORTAL_TIMEOUT_MS, SHUTTER_PORTAL_MINIMAL

---

## 🚀 Install
- Build: `dpkg-buildpackage -us -uc -b`
- Install: `sudo apt install ../shutter_0.99.7-1_all.deb`

Run: `shutter`

---

## 🛠 Usage highlights
- Fullscreen, window, selection, websites
- Editor: shapes, text, arrow, pixelate, blur, icons
- Clipboard and file export, uploads (Imgur, Gyazo, FTP)

Tips:
- Debug logs: `SHUTTER_DEBUG=1 shutter`
- Prefer COSMIC: set UI option or `SHUTTER_PREFER_COSMIC=1`
- Force Portal: set UI option or `SHUTTER_FORCE_PORTAL=1`

---

## 👤 Credits
- Founder: Mario Kemper
- Modernization & Wayland: Anton Isaiev (totoshko88) <totoshko88@gmail.com>
- More: `share/shutter/resources/credits`

---

## 📄 License
GPL-3.0-or-later
