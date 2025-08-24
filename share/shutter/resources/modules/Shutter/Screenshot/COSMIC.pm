use utf8;
use strict;
use warnings;
package Shutter::Screenshot::COSMIC;
use File::Temp qw/tempfile tempdir/;
use File::Which (); # use fully-qualified call to avoid package import ordering issues
use Time::HiRes qw/usleep/;

sub is_available {
    # Only offer on Wayland COSMIC sessions and when the CLI exists
    return 0 unless ($ENV{XDG_SESSION_TYPE} && $ENV{XDG_SESSION_TYPE} eq 'wayland');
    my $desk = ($ENV{XDG_CURRENT_DESKTOP} // '') . ' ' . ($ENV{XDG_SESSION_DESKTOP} // '');
    return 0 unless ($desk =~ /COSMIC/i);
    return File::Which::which('cosmic-screenshot') ? 1 : 0;
}

sub _load_pixbuf_from_path {
    my ($path) = @_;
    return 9 unless defined $path && length $path && -f $path;
    my $pixbuf;
    eval { $pixbuf = Gtk3::Gdk::Pixbuf->new_from_file($path); 1 } or do {
        my $e = $@ || 'unknown error';
        warn "[cosmic] failed to load pixbuf from $path: $e\n" if $ENV{SHUTTER_DEBUG};
        return 9;
    };
    # try best-effort cleanup
    unlink $path if -f $path;
    return $pixbuf;
}

sub _run_and_get_path {
    my (@cmd) = @_;
    my $out = qx{@cmd 2>&1};
    my $rc = $? >> 8;
    chomp $out;
    warn "[cosmic] rc=$rc out='$out'\n" if $ENV{SHUTTER_DEBUG};
    if ($rc != 0) {
        # Treat non-zero as user-cancel for interactive flows; generic error otherwise
        return wantarray ? (undef, $rc) : undef;
    }
    return wantarray ? ($out, 0) : $out;
}

sub full {
    my ($screenshooter, $opts) = @_;
    $opts ||= {};
    # Honor optional delay (milliseconds)
    if (defined $opts->{delay} && $opts->{delay} =~ /^\d+$/ && $opts->{delay} > 0) {
        my $ms = int($opts->{delay});
        warn "[cosmic] delaying capture by ${ms}ms\n" if $ENV{SHUTTER_DEBUG};
        usleep($ms * 1000);
    }
    my $tmpdir = tempdir('shutter-cosmic-XXXXXX', CLEANUP => 1, TMPDIR => 1);
    my @cmd = ('cosmic-screenshot', '--interactive=false', '--notify=false', '--save-dir', $tmpdir);
    my ($path, $rc) = _run_and_get_path(@cmd);
    return 9 unless defined $path && length $path;
    return _load_pixbuf_from_path($path);
}

sub selection {
    my ($screenshooter, $opts) = @_;
    $opts ||= {};
    # Interactive via portal; include_cursor not controllable here
    my @cmd = ('cosmic-screenshot', '--interactive=true', '--modal=true', '--notify=false');
    my ($path, $rc) = _run_and_get_path(@cmd);
    if (!defined $path || $path eq '') {
        # Non-zero rc likely means user cancelled
        return defined($rc) && $rc != 0 ? 5 : 9;
    }
    return _load_pixbuf_from_path($path);
}

1;
