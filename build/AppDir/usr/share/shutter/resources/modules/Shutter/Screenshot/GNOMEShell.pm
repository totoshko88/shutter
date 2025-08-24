use utf8;
use strict;
use warnings;
use Net::DBus;
use Time::HiRes qw(usleep);
use File::Spec;
use File::Path qw(make_path);

package Shutter::Screenshot::GNOMEShell;

sub _cache_dir {
    my $home = $ENV{HOME} || (getpwuid($<))[7] || '/tmp';
    my $dir = File::Spec->catdir($home, '.cache', 'shutter');
    eval { make_path($dir, { mode => 0700 }) };
    return $dir;
}

sub is_available {
    # Returns true if GNOME Shell Screenshot D-Bus API is available on session bus
    my $ok = 0;
    eval {
        my $bus = Net::DBus->find;
        my $svc = $bus->get_service('org.gnome.Shell.Screenshot');
        my $obj = $svc->get_object('/org/gnome/Shell/Screenshot', 'org.gnome.Shell.Screenshot');
        # Try a harmless call (introspection typically exists, but a simple property read is not exposed).
        # Just reaching here without dying is good enough.
        $ok = $obj ? 1 : 0;
    };
    return $ok ? 1 : 0;
}

sub window {
    # Capture the active window via GNOME Shell and return a GdkPixbuf
    # window($screenshooter, { include_cursor => 0|1, delay => ms })
    my ($screenshooter, $opts) = @_;
    $opts ||= {};

    my $last_err;

    eval {
        if (defined $opts->{delay} && $opts->{delay} =~ /^\d+$/ && $opts->{delay} > 0) {
            usleep(int($opts->{delay}) * 1000);
        }

        my $bus = Net::DBus->find;
        my $svc = $bus->get_service('org.gnome.Shell.Screenshot');
        my $obj = $svc->get_object('/org/gnome/Shell/Screenshot', 'org.gnome.Shell.Screenshot');

        my $dir = _cache_dir();
        my $name = sprintf('shutter-%d-%d.png', time, int(rand(1_000_000)));
        my $path = File::Spec->catfile($dir, $name);

        my $include_frame   = 1; # include window frame
        my $include_pointer = $opts->{include_cursor} ? 1 : 0;
        my $flash           = 0;

        warn "[gnome-shell] ScreenshotWindow -> $path (cursor=$include_pointer)\n" if $ENV{SHUTTER_DEBUG};
        # Method signature: ScreenshotWindow(b include_frame, b include_pointer, b flash, s filename) -> (b success)
        my $success = $obj->ScreenshotWindow($include_frame, $include_pointer, $flash, $path);
        unless ($success) {
            $last_err = 'GNOME Shell: ScreenshotWindow failed';
            die $last_err;
        }

        # Load and return pixbuf
        my $pixbuf = Gtk3::Gdk::Pixbuf->new_from_file($path);
        unlink $path; # best-effort cleanup
        return $pixbuf;
    };

    if ($@) {
        # Treat all failures as generic error (9); GNOME Shell method has no interactive cancel
        warn "[gnome-shell] error: $@\n" if $ENV{SHUTTER_DEBUG};
        return 9;
    }
}

sub full {
    # Capture the full desktop via GNOME Shell and return a GdkPixbuf
    # full($screenshooter, { include_cursor => 0|1, delay => ms })
    my ($screenshooter, $opts) = @_;
    $opts ||= {};

    my $last_err;

    eval {
        if (defined $opts->{delay} && $opts->{delay} =~ /^\d+$/ && $opts->{delay} > 0) {
            usleep(int($opts->{delay}) * 1000);
        }

        my $bus = Net::DBus->find;
        my $svc = $bus->get_service('org.gnome.Shell.Screenshot');
        my $obj = $svc->get_object('/org/gnome/Shell/Screenshot', 'org.gnome.Shell.Screenshot');

        my $dir = _cache_dir();
        my $name = sprintf('shutter-%d-%d.png', time, int(rand(1_000_000)));
        my $path = File::Spec->catfile($dir, $name);

        my $include_pointer = $opts->{include_cursor} ? 1 : 0;
        my $flash           = 0;

        warn "[gnome-shell] Screenshot -> $path (cursor=$include_pointer)\n" if $ENV{SHUTTER_DEBUG};
        # Method signature: Screenshot(b include_pointer, b flash, s filename) -> (b success)
        my $success = $obj->Screenshot($include_pointer, $flash, $path);
        unless ($success) {
            $last_err = 'GNOME Shell: Screenshot failed';
            die $last_err;
        }

        my $pixbuf = Gtk3::Gdk::Pixbuf->new_from_file($path);
        unlink $path; # best-effort cleanup
        return $pixbuf;
    };

    if ($@) {
        warn "[gnome-shell] error: $@\n" if $ENV{SHUTTER_DEBUG};
        return 9;
    }
}

1;
