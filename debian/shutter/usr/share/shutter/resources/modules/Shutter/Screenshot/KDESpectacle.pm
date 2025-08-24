use utf8;
use strict;
use warnings;
use File::Temp qw/tempfile/;
use File::Which qw/which/;

package Shutter::Screenshot::KDESpectacle;

# Simple KDE Plasma backend that shells out to Spectacle for window captures on Wayland.
# This is optional and only used if Spectacle is available at runtime.

sub _is_plasma_session {
    return (($ENV{XDG_CURRENT_DESKTOP} && $ENV{XDG_CURRENT_DESKTOP} =~ /KDE/i)
        || ($ENV{XDG_SESSION_DESKTOP} && $ENV{XDG_SESSION_DESKTOP} =~ /plasma/i)
        || ($ENV{DESKTOP_SESSION} && $ENV{DESKTOP_SESSION} =~ /plasma/i)
        || $ENV{KDE_FULL_SESSION});
}

sub is_available {
    return 0 unless ($ENV{XDG_SESSION_TYPE} && $ENV{XDG_SESSION_TYPE} eq 'wayland');
    return 0 unless _is_plasma_session();
    return defined which('spectacle') ? 1 : 0;
}

sub window {
    # window($screenshooter, { include_cursor => 0|1, delay => ms })
    my ($screenshooter, $opts) = @_;
    $opts ||= {};

    my ($fh, $tmpfile) = tempfile('shutter-kde-XXXXXX', SUFFIX => '.png', UNLINK => 0);
    close $fh; # Spectacle will write into it

    my @cmd = ('spectacle', '--background', '--window');
    # Avoid desktop notifications/popups
    push @cmd, '--nonotify';

    # Include pointer if supported. Flag name differs across versions; try common ones.
    if ($opts->{include_cursor}) {
        push @cmd, '--pointer';
    }

    # Delay in ms; Spectacle expects seconds for --delay
    if (defined $opts->{delay} && $opts->{delay} =~ /^\d+$/ && $opts->{delay} > 0) {
        my $sec = int($opts->{delay} / 1000);
        $sec = 1 if $sec < 1; # minimum 1s to be effective
        push @cmd, ('--delay', $sec);
    }

    push @cmd, ('--output', $tmpfile);

    my $rc = system(@cmd);
    if ($rc != 0) {
        unlink $tmpfile if -e $tmpfile;
        warn "[kde] spectacle failed rc=$rc\n" if $ENV{SHUTTER_DEBUG};
        return 9; # generic error
    }

    # Load into a Pixbuf
    my $pixbuf;
    eval {
        $pixbuf = Gtk3::Gdk::Pixbuf->new_from_file($tmpfile);
        1;
    } or do {
        my $e = $@ || 'unknown error';
        warn "[kde] failed to load pixbuf from $tmpfile: $e\n" if $ENV{SHUTTER_DEBUG};
        unlink $tmpfile if -e $tmpfile;
        return 9;
    };

    unlink $tmpfile if -e $tmpfile;
    return $pixbuf;
}

sub full {
    # full($screenshooter, { include_cursor => 0|1, delay => ms })
    my ($screenshooter, $opts) = @_;
    $opts ||= {};

    my ($fh, $tmpfile) = tempfile('shutter-kde-XXXXXX', SUFFIX => '.png', UNLINK => 0);
    close $fh;

    my @cmd = ('spectacle', '--background', '--fullscreen', '--nonotify');
    if ($opts->{include_cursor}) {
        push @cmd, '--pointer';
    }
    if (defined $opts->{delay} && $opts->{delay} =~ /^\d+$/ && $opts->{delay} > 0) {
        my $sec = int($opts->{delay} / 1000);
        $sec = 1 if $sec < 1;
        push @cmd, ('--delay', $sec);
    }
    push @cmd, ('--output', $tmpfile);

    my $rc = system(@cmd);
    if ($rc != 0) {
        unlink $tmpfile if -e $tmpfile;
        warn "[kde] spectacle failed rc=$rc\n" if $ENV{SHUTTER_DEBUG};
        return 9;
    }

    my $pixbuf;
    eval {
        $pixbuf = Gtk3::Gdk::Pixbuf->new_from_file($tmpfile);
        1;
    } or do {
        my $e = $@ || 'unknown error';
        warn "[kde] failed to load pixbuf from $tmpfile: $e\n" if $ENV{SHUTTER_DEBUG};
        unlink $tmpfile if -e $tmpfile;
        return 9;
    };
    unlink $tmpfile if -e $tmpfile;
    return $pixbuf;
}

1;
