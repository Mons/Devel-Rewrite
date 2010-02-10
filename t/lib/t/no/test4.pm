package #hide
	t::no::test4;

sub test1 {
	# @rewrite s/'not\s+/'/;
	return 'not rewritten';
}

sub test2 {
	# @include debug.inc
	return 'not rewritten';
}

1;
