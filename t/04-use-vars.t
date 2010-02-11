#!/usr/bin/env perl

use lib::abs '../lib', 'lib';
use Test::More tests => 2;
use Test::NoWarnings;

use Devel::Rewrite;
use t::ok::vars;
is $t::ok::vars::VERSION, '0.01', 'var with use vars ok';
