#
# RPM spec for Shutter on openSUSE Tumbleweed
# Builds from a tarball of this source tree and installs via the provided Makefile
#

Name:           shutter
Version:        0.99.7
Release:        0
Summary:        Screenshot tool for X11/Wayland with editing (Perl/GTK3)
License:        GPL-3.0-or-later
URL:            https://github.com/totoshko88/shutter
Source0:        %{name}-%{version}.tar.gz
BuildArch:      noarch

# Build tools
BuildRequires:  make
BuildRequires:  gettext-tools

# Runtime: Perl and GI/GTK3 stack
Requires:       perl
Requires:       perl(Gtk3)
Requires:       perl(Pango)
Requires:       perl(Glib)
Requires:       perl(Glib::Object::Introspection)
Requires:       perl(Gtk3::ImageView) >= 10
Requires:       perl(Number::Bytes::Human)
Requires:       perl(XML::Simple)
Requires:       perl(Net::DBus)
Requires:       perl(HTTP::Status)
Requires:       perl(Digest::MD5)
Requires:       perl(Proc::Simple)
Requires:       perl(Sort::Naturally)
Requires:       perl(Image::Magick)
Requires:       perl(Locale::gettext)
Requires:       perl(File::Which)
Requires:       perl(File::Copy::Recursive)
Requires:       perl(Moo) >= 2.0

# Optional integrations and editing canvas
Suggests:       perl(Net::DBus::GLib)
Suggests:       perl(GooCanvas2)
Recommends:     grim
Recommends:     slurp
Recommends:     spectacle
Recommends:     cosmic-screenshot

%description
Shutter is a feature-rich screenshot tool written in Perl with a GTK3 UI.
It supports X11 and Wayland sessions via multiple backends (XDG Desktop Portal,
GNOME Shell, KDE Spectacle, wlroots grim+slurp, and System76 COSMIC screenshot).
Optional image editing and advanced selection features use GooCanvas2.

%prep
%setup -q

%build
make all

%install
make install prefix=%{buildroot}%{_prefix}
rm -rf %{buildroot}%{_datadir}/doc/%{name}

%files
%license COPYING
%doc README.md CHANGES
%{_bindir}/shutter
%{_datadir}/applications/shutter.desktop
%{_datadir}/metainfo/shutter.metainfo.xml
%{_datadir}/man/man1/shutter.1*
%{_datadir}/pixmaps/shutter.png
%{_datadir}/icons/hicolor/*/apps/shutter.png
%{_datadir}/icons/hicolor/16x16/apps/shutter-panel.png
%{_datadir}/icons/hicolor/22x22/apps/shutter-panel.png
%{_datadir}/icons/hicolor/24x24/apps/shutter-panel.png
%{_datadir}/icons/hicolor/scalable/apps/shutter.svg
%{_datadir}/icons/hicolor/scalable/apps/shutter-panel.svg
%{_datadir}/icons/HighContrast/scalable/apps/shutter.svg
%{_datadir}/icons/HighContrast/scalable/apps/shutter-panel.svg
%{_datadir}/shutter/
%{_datadir}/locale/*/LC_MESSAGES/shutter*.mo

%changelog
* Sun Aug 24 2025 Shutter Project Maintainers <shutter-project@users.noreply.github.com> - 0.99.7-0
- Initial packaging for openSUSE Tumbleweed (Wayland-first fork 0.99.7)
