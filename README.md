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
