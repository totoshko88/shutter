###################################################
#
#  Copyright (C) 2008-2013 Mario Kemper <mario.kemper@gmail.com>
#
#  This file is part of Shutter.
#
#  Shutter is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#
#  Shutter is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with Shutter; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
#
###################################################

package Shutter::Geometry::Region;

#modules
#--------------------------------------
use utf8;
use strict;
use warnings;

use Gtk3;

#Glib
use Glib qw/TRUE FALSE/;

sub new {
	my $class = shift;

	#constructor
	my $self = {};

	bless $self, $class;
	return $self;
}

sub get_clipbox {
	my $self   = shift;
	my $region = shift;

	#store clipbox here
	my $clip = undef;

	#calculate clipbox
	my $len = $region->num_rectangles-1;
	for my $i (0..$len) {
		my $rect = $region->get_rectangle($i);

		unless (defined $clip) {
			$clip = $rect;
		} else {
			if ($rect->{x} < $clip->{x}) {
				$clip->{width} = $clip->{width} + $clip->{x};
				$clip->{x} = $rect->{x};
			}
			if ($rect->{y} < $clip->{y}) {
				$clip->{height} = $clip->{height} + $clip->{y};
				$clip->{y} = $rect->{y};
			}
			if ($rect->{x} + $rect->{width} > $clip->{x} + $clip->{width}) {
				$clip->{width} = $rect->{x} + $rect->{width} - $clip->{x};
			}
			if ($rect->{y} + $rect->{height} > $clip->{y} + $clip->{height}) {
				$clip->{height} = $rect->{y} + $rect->{height} - $clip->{y};
			}
		}
	}

	#return clip or empty rectangle
	if (defined $clip) {
		return $clip;
	} else {
		return {x=>0, y=>0, width=>0, height=>0};
	}

}

1;

