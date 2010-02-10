package #hide
	t::ok::test1;

use t::ok::test2;
$VAR1 = $VAR2; # no strict test

sub test1 {
	# @rewrite s/'not\s+/'/;
	return 'not rewritten';
}

sub test2 {
	# @include debug.inc
	return 'not rewritten';
}

sub test3 {
	# @include ../debug.inc
	return 'not rewritten';
}

1;
