use utf8;
use strict;
use warnings;
use File::Temp qw/tempfile/;
use File::Which qw/which/;

package Shutter::Screenshot::WLRGrim;

sub is_available {
    return 0 unless ($ENV{XDG_SESSION_TYPE} && $ENV{XDG_SESSION_TYPE} eq 'wayland');
    return defined which('grim') ? 1 : 0;
}

sub _run_and_load {
    my (@cmd) = @_;
    my ($fh, $tmpfile) = tempfile('shutter-wlr-XXXXXX', SUFFIX => '.png', UNLINK => 0);
    close $fh;

    push @cmd, $tmpfile;
    my $rc = system(@cmd);
    if ($rc != 0) {
        unlink $tmpfile if -e $tmpfile;
        warn "[wlr] cmd failed rc=$rc: @cmd\n" if $ENV{SHUTTER_DEBUG};
        return 9;
    }
    my $pixbuf;
    eval { $pixbuf = Gtk3::Gdk::Pixbuf->new_from_file($tmpfile); 1 } or do {
        my $e = $@ || 'unknown error';
        warn "[wlr] failed to load pixbuf from $tmpfile: $e\n" if $ENV{SHUTTER_DEBUG};
        unlink $tmpfile if -e $tmpfile;
        return 9;
    };
    unlink $tmpfile if -e $tmpfile;
    return $pixbuf;
}

sub full {
    my ($screenshooter, $opts) = @_;
    $opts ||= {};
    my @cmd = ('grim');
    # grim does not reliably draw cursor across all versions; ignore include_cursor.
    return _run_and_load(@cmd);
}

sub selection {
    my ($screenshooter, $opts) = @_;
    $opts ||= {};
    # Requires slurp for interactive area selection
    return 9 unless defined which('slurp');
    # slurp prints geometry like: x,y w h  or "x,y w,h" depending on version; use %x,%y %w,%h
    my $geom = `slurp -f "%x,%y %w,%h"`;
    chomp $geom;
    if (!$geom || $geom !~ /\d+,\d+ \d+,\d+/) {
        warn "[wlr] slurp cancelled or invalid geometry: '$geom'\n" if $ENV{SHUTTER_DEBUG};
        return 5; # treated as user-cancel
    }
    my @cmd = ('grim', '-g', $geom);
    return _run_and_load(@cmd);
}

1;
