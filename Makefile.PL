use inc::Module::Install;

name         'Devel-Rewrite';
all_from     'lib/Devel/Rewrite.pm';
author       'Mons Anderson <mons@cpan.org>';
perl_version '5.10.0';
license      'perl';
version      my $v = '0.01';

build_requires 'lib::abs';
build_requires 'Test::More';
build_requires 'Test::NoWarnings';

auto_install;

provides 'Devel::Rewrite' => {
	version => $v,
	file    => 'lib/Devel/Rewrite.pm',
};


WriteAll;

