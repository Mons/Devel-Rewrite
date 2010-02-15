#!/usr/bin/env perl

use lib::abs '../lib';
use Test::More tests => 2;
use Test::NoWarnings;

use Devel::Rewrite;
my $path = lib::abs::path('lib/t/ok/vars.pm');
require $path;
is $t::ok::vars::VERSION, '0.01', 'var with use vars ok';
