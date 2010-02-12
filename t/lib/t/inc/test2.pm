package #hide
	t::inc::test2;
sub ok { 'ok2' } sub cl { sub{(caller(0))[1]}->() } sub fl { __FILE__ }
1;