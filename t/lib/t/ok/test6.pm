package #hide
	t::ok::test6;

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
