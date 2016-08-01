#!/usr/bin/env perl
use strict;

use Text::Lorem;

my $text = Text::Lorem->new();
my ($mode, $count) = @ARGV;

if ($mode =~ /^word$/) {
	print $text->words($count);
} else {
	my $paragraphs = $text->paragraphs($count);
	$paragraphs =~ s/\n/\n+\n/g;
	print $paragraphs;
}
exit 0;
