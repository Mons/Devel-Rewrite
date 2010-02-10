#!/usr/bin/perl

use lib::abs '../lib';

use testx;

testx::test();
testx::injected() if defined &testx::injected;
