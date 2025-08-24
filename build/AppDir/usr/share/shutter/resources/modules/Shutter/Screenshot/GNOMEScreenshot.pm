use utf8;
use strict;
use warnings;

package Shutter::Screenshot::GNOMEScreenshot;

use File::Temp qw/tempfile/;
use File::Which qw/which/;
use Time::HiRes qw/usleep/;

sub _is_gnome_session {
    return (
        (defined $ENV{XDG_CURRENT_DESKTOP} && $ENV{XDG_CURRENT_DESKTOP} =~ /GNOME/i) ||
        (defined $ENV{XDG_SESSION_DESKTOP} && $ENV{XDG_SESSION_DESKTOP} =~ /gnome/i) ||
        (defined $ENV{DESKTOP_SESSION} && $ENV{DESKTOP_SESSION} =~ /gnome/i)
    ) ? 1 : 0;
}

sub is_available {
    # Available when gnome-screenshot exists and we're on a GNOME session
    return 0 unless defined which('gnome-screenshot');
    return _is_gnome_session();
}

sub _run_and_load {
    my (@args) = @_;
    my ($fh, $tmpfile) = tempfile('shutter-gnome-XXXXXX', SUFFIX => '.png', UNLINK => 0);
    close $fh;

    my @cmd = ('gnome-screenshot', @args, ('-f', $tmpfile));
    my $rc = system(@cmd);
    warn "[gnome-screenshot] rc=$rc cmd=@cmd\n" if $ENV{SHUTTER_DEBUG};

    # Non-zero exit or missing/empty file is treated as cancel for interactive flows, error otherwise
    if ($rc != 0 || !-e $tmpfile || -s $tmpfile == 0) {
        unlink $tmpfile if -e $tmpfile && -s $tmpfile == 0;
        return ($rc != 0) ? 5 : 9;
    }

    my $pixbuf;
    eval { $pixbuf = Gtk3::Gdk::Pixbuf->new_from_file($tmpfile); 1 } or do {
        my $e = $@ || 'unknown error';
        warn "[gnome-screenshot] failed to load pixbuf from $tmpfile: $e\n" if $ENV{SHUTTER_DEBUG};
        unlink $tmpfile if -e $tmpfile;
        return 9;
    };
    unlink $tmpfile if -e $tmpfile;
    return $pixbuf;
}

sub _delay_args {
    my ($opts) = @_;
    my @extra;
    if (defined $opts->{delay} && $opts->{delay} =~ /^\d+$/ && $opts->{delay} > 0) {
        my $sec = int($opts->{delay} / 1000);
        $sec = 1 if $sec < 1;
        push @extra, ('-d', $sec);
    }
    return @extra;
}

sub full {
    my ($screenshooter, $opts) = @_;
    $opts ||= {};
    my @args;
    push @args, ('-p') if $opts->{include_cursor};
    push @args, _delay_args($opts);
    return _run_and_load(@args);
}

sub selection {
    my ($screenshooter, $opts) = @_;
    $opts ||= {};
    my @args = ('-a'); # interactive area select
    push @args, ('-p') if $opts->{include_cursor};
    push @args, _delay_args($opts);
    return _run_and_load(@args);
}

sub window {
    my ($screenshooter, $opts) = @_;
    $opts ||= {};
    my @args = ('-w');
    push @args, ('-p') if $opts->{include_cursor};
    push @args, _delay_args($opts);
    return _run_and_load(@args);
}

1;
