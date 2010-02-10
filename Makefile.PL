use inc::Module::Install;

name     'Devel-Rewrite';
all_from 'lib/Devel/Rewrite.pm';
author   'Mons Anderson <mons@cpan.org>';
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

