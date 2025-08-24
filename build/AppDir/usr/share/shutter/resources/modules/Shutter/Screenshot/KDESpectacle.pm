package Shutter::Screenshot::KDESpectacle;

use utf8;
use strict;
use warnings;
use File::Temp qw/tempfile/;
use File::Which qw/which/;
use Time::HiRes qw/usleep/;

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

sub _load_from_tmpfile {
    my ($tmpfile, $tag) = @_;
    $tag ||= 'kde';
    # Treat missing/empty file as user cancel to avoid confusing errors upstream
    unless (-e $tmpfile) {
        warn "[$tag] no output file produced by Spectacle (cancelled?)\n" if $ENV{SHUTTER_DEBUG};
        return 5; # user-cancel
    }
    if (-s $tmpfile == 0) {
        unlink $tmpfile; # cleanup empty
        warn "[$tag] empty output file from Spectacle (cancelled?)\n" if $ENV{SHUTTER_DEBUG};
        return 5; # user-cancel
    }
    my $pixbuf;
    eval {
        $pixbuf = Gtk3::Gdk::Pixbuf->new_from_file($tmpfile);
        1;
    } or do {
        my $e = $@ || 'unknown error';
        warn "[$tag] failed to load pixbuf from $tmpfile: $e\n" if $ENV{SHUTTER_DEBUG};
        unlink $tmpfile if -e $tmpfile;
        return 9;
    };
    unlink $tmpfile if -e $tmpfile;
    return $pixbuf;
}

sub _wait_for_file {
    my ($path, $max_ms, $tag) = @_;
    $tag ||= 'kde';
    $max_ms = 120000 unless defined $max_ms; # default 120s for interactive flows
    my $elapsed = 0;
    while ($elapsed <= $max_ms) {
        if (-e $path && -s $path > 0) {
            warn "[$tag] output file ready after ${elapsed}ms: $path\n" if $ENV{SHUTTER_DEBUG};
            return 1;
        }
        usleep(100_000); # 100ms
        $elapsed += 100;
    }
    warn "[$tag] timed out waiting for output file: $path\n" if $ENV{SHUTTER_DEBUG};
    return 0;
}

sub window {
    # window($screenshooter, { include_cursor => 0|1, delay => ms })
    my ($screenshooter, $opts) = @_;
    $opts ||= {};

    my ($fh, $tmpfile) = tempfile('shutter-kde-XXXXXX', SUFFIX => '.png', UNLINK => 0);
    close $fh;
    # Important: let Spectacle create the file; pre-created zero-length targets may be ignored
    unlink $tmpfile if -e $tmpfile;

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
    warn "[kde] spectacle window rc=$rc\n" if $ENV{SHUTTER_DEBUG};
    _wait_for_file($tmpfile, 10000, 'kde'); # up to 10s for non-interactive window capture
    return _load_from_tmpfile($tmpfile, 'kde');
}

sub full {
    # full($screenshooter, { include_cursor => 0|1, delay => ms })
    my ($screenshooter, $opts) = @_;
    $opts ||= {};

    my ($fh, $tmpfile) = tempfile('shutter-kde-XXXXXX', SUFFIX => '.png', UNLINK => 0);
    close $fh;
    unlink $tmpfile if -e $tmpfile;

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
    warn "[kde] spectacle full rc=$rc\n" if $ENV{SHUTTER_DEBUG};
    _wait_for_file($tmpfile, 10000, 'kde'); # up to 10s for full capture
    return _load_from_tmpfile($tmpfile, 'kde');
}

sub selection {
    # selection($screenshooter, { include_cursor => 0|1, delay => ms })
    # Use Spectacle's interactive region selector in background mode and load the result.
    my ($screenshooter, $opts) = @_;
    $opts ||= {};

    my ($fh, $tmpfile) = tempfile('shutter-kde-XXXXXX', SUFFIX => '.png', UNLINK => 0);
    close $fh;
    unlink $tmpfile if -e $tmpfile;

    my @cmd = ('spectacle', '--region', '--background', '--nonotify');
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
    warn "[kde] spectacle selection rc=$rc\n" if $ENV{SHUTTER_DEBUG};
    # Region selection is asynchronous in background mode; wait up to 3 minutes for user action
    _wait_for_file($tmpfile, 180000, 'kde');
    return _load_from_tmpfile($tmpfile, 'kde');
}

1;
