package #hide
	t::inc::test1;
use t::inc::test2;
sub ok { 'ok1' } sub cl { sub{(caller(0))[1]}->() } sub fl { __FILE__ }
1;