#!/usr/bin/env perl

use strict;
use Test::More tests => 16;

unshift @INC, my $code = sub {
	my $f = $_[1];
	$f =~ m{t/test\d} or return;
	( my $pk = join ('::', split '/',$f ) ) =~ s/\.pm$//;
	warn "$f => $pk";
	my $line = 0;
	if ($f =~ /test2/) {
		print "# ENTER: set inc for $f, have ".( exists $INC{$f} ? "$INC{$f} ".\$INC{$f} : 'no current' )."\n";
		#delete $INC{$f};
		$INC{$f} = '/custom1/path/'.$f;
	} else {
		print "# ENTER: don't set inc for $f, have ".( exists $INC{$f} ? "$INC{$f} ".\$INC{$f} : 'no current' )."\n";
		#delete $INC{$f};
	}
	return (sub {
		if (++$line == 1) {
			$_ = 'package '.$pk.'; sub f { sub{ (caller(0))[1] }->() }'."1;\n";
			return 1;
		}
		else {
			if ($f =~ /test3/) {
				print "# LEAVE: set inc for $f, have ".( exists $INC{$f} ? "$INC{$f} ".\$INC{$f} : 'no current' )."\n";
				# delete $INC{$f}; # This will fix last fail
				$INC{$f} = '/custom2/path/'.$f;
			} else {
				print "# LEAVE: don't set inc for $f, have ".( exists $INC{$f} ? "$INC{$f} ".\$INC{$f} : 'no current' )."\n";
			}
			return 0;
		}
	});
};

(my $ref) = "$code" =~ /\((0x.+)\)/;

ok eval{ require t::test1 }, 'use 1' or diag "$@";
is t::test1::f(), "/loader/$ref/t/test1.pm", 'file 1';
is $INC{'t/test1.pm'}, $code, '%INC 1';

ok eval{ require t::test2 }, 'use 2' or diag "$@";
is t::test2::f(), '/custom1/path/t/test2.pm', 'file 2';
is $INC{'t/test2.pm'}, '/custom1/path/t/test2.pm', '%INC 2';

is t::test1::f(), "/loader/$ref/t/test1.pm", 'file 1 again 1';
is $INC{'t/test1.pm'}, $code, '%INC 1 again 1';

ok eval{ require t::test3 }, 'use 3' or diag "$@";

{
	# Since we define new %INC after loading the source, we already
	# processed all source with previous __FILE__ = /loader/ref/...
	# So, %INC contains new value, but __FILE__ contains old
	local $TODO = 'Current implementation';
	is t::test3::f(), '/custom2/path/t/test3.pm', 'file 3';
}
is $INC{'t/test3.pm'}, '/custom2/path/t/test3.pm', '%INC 3';

is t::test2::f(), '/custom1/path/t/test2.pm', 'file 2';
is $INC{'t/test2.pm'}, '/custom1/path/t/test2.pm', '%INC 3';

is t::test1::f(), "/loader/$ref/t/test1.pm", 'file 1 again 2';

# $INC{test1} and $INC{test3} refers to the same address.
# So, after changing $INC{test3} we get changed $INC{test1}
is $INC{'t/test1.pm'}, $code, '%INC 1 again 2' or diag "%INC 1 lost it's value";
is $INC[0], $code, '$INC[0] is ok' or diag "\@INC = ( @INC[0..2] , ... )";
