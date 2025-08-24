use utf8;
use strict;
use warnings;
use Net::DBus;
use Net::DBus::Reactor; # fallback main loop if GLib integration is unavailable
# Try to integrate Net::DBus with GLib main loop, but don't hard-require it
my $HAS_DBUS_GLIB = 0;
BEGIN {
	$HAS_DBUS_GLIB = eval {
		require Net::DBus::GLib; Net::DBus::GLib->import(); 1
	} ? 1 : 0;
	warn "[wayland] Net::DBus::GLib not available; using Net::DBus::Reactor fallback\n" if !$HAS_DBUS_GLIB && $ENV{SHUTTER_DEBUG};
}
# Net::DBus::Annotation helpers are not available everywhere; avoid and pass plain scalars.
use Time::HiRes qw(usleep);

package Shutter::Screenshot::Wayland;

sub xdg_portal {
	# xdg_portal($screenshooter, { interactive => 0|1, include_cursor => 0|1 })
	my ($screenshooter, $opts) = @_;
	$opts ||= {};

	# We'll use a nested Glib::MainLoop to wait for the portal response,
	# which keeps the Gtk main context responsive.
	my $loop; # Glib::MainLoop (when $HAS_DBUS_GLIB)
	my $bus = Net::DBus->find;
	my $me = $bus->get_unique_name;
	$me =~ s/\./_/g;
	$me =~ s/^://g;

	my $pixbuf;
	my $last_err;

	eval {
	warn "[wayland] invoking xdg-desktop-portal Screenshot...\n" if $ENV{SHUTTER_DEBUG};

		# Honor optional delay (milliseconds)
		if (defined $opts->{delay} && $opts->{delay} =~ /^\d+$/ && $opts->{delay} > 0) {
			my $ms = int($opts->{delay});
			warn "[wayland] delaying capture by ${ms}ms\n" if $ENV{SHUTTER_DEBUG};
			usleep($ms * 1000);
		}
	my $portal_service = $bus->get_service('org.freedesktop.portal.Desktop');
	my $portal = $portal_service->get_object('/org/freedesktop/portal/desktop', 'org.freedesktop.portal.Screenshot');

		my $num;
		my $output;
			my $cb = sub {
				($num, $output) = @_;
				if ($HAS_DBUS_GLIB) {
					$loop->quit if $loop;
				} else {
					Net::DBus::Reactor->main->shutdown;
				}
			};

		my $token = 'shutter' . rand;
		$token =~ s/\.//g;
		# Build options map (a{sv})
		my %o = (
			handle_token => $token,
		);
		# Allow a "minimal" mode to aid compatibility: avoid passing optional flags
		# Enable by setting SHUTTER_PORTAL_MINIMAL=1
		my $minimal = $ENV{SHUTTER_PORTAL_MINIMAL} && $ENV{SHUTTER_PORTAL_MINIMAL} =~ /^(1|true|yes)$/i;
		if (defined $opts->{interactive}) {
			$o{interactive} = $opts->{interactive} ? 1 : 0;
			# keep modal only if not in minimal mode
			$o{modal}       = 1 unless $minimal;
		}
		if (defined $opts->{include_cursor} && !$minimal) {
			# 0 hidden, 1 embedded, 2 metadata. Map to embedded if requested, else hidden.
			my $cm = $opts->{include_cursor} ? 1 : 0;
			$o{'cursor-mode'} = $cm;
		}

		# Call Screenshot first to obtain the request path, then connect to the signal on that object.
		my $request_path = $portal->Screenshot('', \%o);
		warn "[wayland] portal request path: $request_path\n" if $ENV{SHUTTER_DEBUG};
		my $request = $portal_service->get_object($request_path, 'org.freedesktop.portal.Request');
		my $conn = $request->connect_to_signal(Response => $cb);
		# Timeout strategy:
		# - If interactive, do NOT enforce a timeout (let user take time to select)
		# - Else, use SHUTTER_PORTAL_TIMEOUT_MS (default 30000ms)
		my $timeout_ms = 0;
		if (!$opts->{interactive}) {
			$timeout_ms = defined $ENV{SHUTTER_PORTAL_TIMEOUT_MS} && $ENV{SHUTTER_PORTAL_TIMEOUT_MS} =~ /^(\d+)$/ ? $1 : 30000;
		}
		my $timed_out = 0;
		if ($HAS_DBUS_GLIB) {
			my $timeout_id;
			if ($timeout_ms > 0) {
				$timeout_id = Glib::Timeout->add($timeout_ms, sub {
					$timed_out = 1;
					$last_err = 'XDG portal response timeout';
					warn "[wayland] $last_err (after ${timeout_ms}ms)\n" if $ENV{SHUTTER_DEBUG};
					$loop->quit if $loop;
					return 0; # one-shot
				});
			}
			$loop = Glib::MainLoop->new(undef, 0);
			$loop->run;
			# Best effort to clear timeout if response arrived in time
			Glib::Source->remove($timeout_id) if defined $timeout_id && !$timed_out;
		} else {
			my $reactor = Net::DBus::Reactor->main;
			if ($timeout_ms > 0) {
				$reactor->add_timeout($timeout_ms, sub {
					$timed_out = 1;
					$last_err = 'XDG portal response timeout';
					warn "[wayland] $last_err (after ${timeout_ms}ms)\n" if $ENV{SHUTTER_DEBUG};
					$reactor->shutdown;
					return 0; # one-shot
				});
			}
			$reactor->run;
		}
		$request->disconnect_from_signal(Response => $conn);
		if (!defined $num || $num != 0) {
			# Map portal response codes to Shutter error codes
			# 0 = success, 1 = cancelled, 2 = other error
			if (defined $num && $num == 1) {
				$last_err = 'User cancelled screenshot via portal';
				warn "[wayland] portal response cancel: $last_err\n" if $ENV{SHUTTER_DEBUG};
				return 5; # user-aborted in Shutter::Screenshot::Error
			}
			$last_err = defined $num ? "Response $num from XDG portal" : "No response from XDG portal";
			warn "[wayland] portal response error: $last_err\n" if $ENV{SHUTTER_DEBUG};
			return 9;
		}
		my $uri = $output->{uri};
		warn "[wayland] portal provided uri: $uri\n" if $ENV{SHUTTER_DEBUG};
		my $giofile = Glib::IO::File::new_for_uri($uri);

		# Try to get a local path first; if not available, fall back to loading contents via Gio
		my $local_path = eval { $giofile->get_path };
		warn "[wayland] xdg portal: local path: " . (defined $local_path ? $local_path : '<undef>') . "\n" if $ENV{SHUTTER_DEBUG};
		if (defined $local_path && length $local_path) {
			# If file exists but is empty, treat as cancel
			if (-e $local_path && -s $local_path == 0) {
				$last_err = 'Portal returned empty file (cancelled)';
				warn "[wayland] $last_err\n" if $ENV{SHUTTER_DEBUG};
				return 5;
			}
			$pixbuf = Gtk3::Gdk::Pixbuf->new_from_file($local_path);
			# best-effort cleanup
			eval { $giofile->delete };
		} else {
			# Some portals return a document portal URI without a direct local path; load contents instead
			my ($ok, $data);
			if (eval { ($ok, $data) = $giofile->load_contents(undef); 1 } && $ok && defined $data) {
				if (length($data) == 0) {
					$last_err = 'Portal returned empty contents (cancelled)';
					warn "[wayland] $last_err\n" if $ENV{SHUTTER_DEBUG};
					return 5;
				}
				my $loader = Gtk3::Gdk::PixbufLoader->new;
				$loader->write($data);
				$loader->close;
				$pixbuf = $loader->get_pixbuf;
				# Attempt deletion even if no local path; the document portal usually allows unlink
				eval { $giofile->delete };
			} else {
				$last_err = 'Failed to load screenshot contents from portal URI';
				warn "[wayland] $last_err\n" if $ENV{SHUTTER_DEBUG};
				return 9;
			}
		}
	};
	if ($@) {
		$last_err = $@;
		warn "[wayland] portal exception: $last_err\n" if $ENV{SHUTTER_DEBUG};
		return 9;
	};

	return $pixbuf;
}

1;
