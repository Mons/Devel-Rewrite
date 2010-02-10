package #hide
	t::no::test3;

use t::no::test4;
$VAR1 = $VAR2; # no strict test

sub test1 {
	# @rewrite s/'not\s+/'/;
	return 'not rewritten';
}

sub test2 {
	# @include debug.inc
	return 'not rewritten';
}

1;
