package #hide
	testx;

# @rewrite s/^#//;
# warn __PACKAGE__ . " rewritten";

warn 'head';

# @rewrite 'bad before include';

# @include inject.inc

sub test {
	# @rewrite s/'not\s+/'/;
	warn 'not rewritten';
}

1;
