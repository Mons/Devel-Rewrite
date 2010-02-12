package Devel::Rewrite;

{
	# We need this to emulate do $filename behaviour.
	# See L<perlfunc/do>
	# Eval should not see lexicals in the enclosing scope
	sub doeval {
		defined $_[1] or return;
		return eval("package $_[2];\n".$_[1]);
	}
}
{
use 5.010;
use strict;
use warnings;

=head1 NAME

Devel::Rewrite - Development preprocessor

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    # Your::Module:
    
    # @rewrite s/^#\s+//;
    # use Some::Development::Module;
    
    # @rewrite s/some_call/another_call/;
    $object->some_call;
    
    sub something {
        # @include sub.debug.inc
        ...
    }

And in author tests:

    # xt/some-development-test.t:
    use strict;
    {
        use Devel::Rewrite;
        use Modules::That::Should::Be::Rewrited;
    }
    use Modules::Other;

    # make your tests...


=head1 DESCRIPTION

The main purpose of this module is creating optional debugging routines.

- which does not require any additional prerequsites for production, like for ex L<Devel::Leak::Cb>

- which does not provide any perfomance overhead in production environment.

- which requires no rebuild of target modules for enabling debugging routines

In other words, this module is external source filter, for any loading modules

=head1 IMPORTANT NOTICE

This module overloads C<CORE::GLOBAL::require> on C<import>.
Since this is module loading endpoint, it won't call any previously overloaded

So, if you use something, like L<as>, load this package earlier, than L<as>

Also, please, don't use this module inside your modules. Only in external scripts and applications.
That's because there is no way to change the behaviour of C<use>'d module inside your sources

=head1 DIRECTIVES

=over 4

=item @include filename

Include source of C<filename> into directive place.
Rewrite subprocessing of include will be done.
C<filename> should be relative to file, which call C<@include>

    # Module.pm:
    sub yoursub {
        my @args = @_;
        # @include debug.inc
        ...
    }
    # debug.inc:
    warn "Entered sub";

=item @rewrite EXPR

Call EXPR in context of next non-empty source line

    sub test {
    
        # @rewrite s/'not\s+/'/;
        
        return 'not rewritten';
        
    }

If next non-empty line is another directive, rewrite is ifnored and warning is emitted

=back

=head1 CONTROLLING

This module implements pragmatic behaviour (so, perl 5.10+).
Recommented usage way is just enable (by C<use Devel::Rewrite>) in some test script.

    use Devel::Rewrite;
    use Module1; # rewrite enabled;
    use Module2; # rewrite enabled;
    # ...

Another recommended way is enabling rewrite only for a subset of C<use>'d modules

    use Module1; # rewrite disabled;
    {
        use Devel::Rewrite;
        use Module2; # rewrite enabled;
    }
    use Module3; # rewrite disabled;
    # ...

But also may be used complex blocks like:

    use Devel::Rewrite;
    use Module1; # rewrite enabled;
    {
        no Devel::Rewrite;
        use Module2; # rewrite disabled;
        {
            use Devel::Rewrite;
            use Module3; # rewrite enabled;
        }
        use Module4; # rewrite disabled;
    }
    use Module5; # rewrite enabled;

Please, note: If some module was C<use>d before enabled rewrite,
it will not be rewrited anymore in rewrite-enabled scope in later use (see L<perlfunc/require>)

=cut

our $KEY = '@rewrite';
our $old;
our $done;
our $recursive = 0;

#=for rem
use subs 'warn';
sub warn {
	my ($f,$l) = (caller)[1,2];
	local $_ = "@_";
	s{\n$}{} or $_ .= " at $f line $l.";
	print STDERR "$_\n";
	return 1;
}
#=cut

sub in_effect {
	use strict;
	my $level = shift // 0;
	my @c = caller($level + $recursive);
	defined $c[0] or return 0;
	my $hinthash = $c[10];
	#my $v = $hinthash->{$KEY};
	no warnings;
	#print STDERR "$KEY at $level not defined @c[1,2]\n" unless defined $hinthash->{$KEY};
	return
		defined $hinthash->{$KEY} ? 
			$hinthash->{$KEY}
			: do { local $recursive = $recursive + 1; in_effect($level+1) }
}

sub rewrite {
	use strict;
	my $self = shift;
	my ($indata,$file,$realfile) = @_;
	my $base;
	if (!$indata) {
		die "Need either indata or realfile" unless $realfile;
		open my $f, '<:raw', $realfile or die "can't open file $realfile: $!";
		$indata = do { local $/; <$f> };
		close $f;
	} else {
		#unless ($realfile and !ref $INC{$file}) {
		if (!$realfile and !ref $INC{$file}) {
			warn "No realfile, use inc $INC{$file}";
			$realfile = $INC{$file};
		}
	}
	if ($indata =~ s{^\xEF\xBB\xBF}{} ) {
		# utf8;
	}
	elsif ($indata =~ s{\xFF\xFE}{} ) {
		# utf16 LE
		$indata = pack 'C*', unpack 'v*', $indata;
	}
	elsif ( $indata =~ s{\xFE\xFF}{} ) {
		# utf16 BE
		$indata = pack 'C*', unpack 'n*', $indata;
	}
	if (ref $INC{$file}) {
		# Can't define base for dynamycally loaded files;
	}
	elsif ($INC{$file}) {
		( $base = $INC{$file} ) =~ s{[^/]+$}{};
	}
	elsif ( $realfile ) {
		( $base = $realfile ) =~ s{[^/]+$}{};
	}
	else {
		warn "No either \$INC or \$realfile entry for $file";
	}
	#( $base = $realfile ) =~ s{[^/]+$}{};
	
	#my @data = $indata =~ m{^(.+)$}mg;
	my @data = split /\015?\012/,$indata;
	#return join '',@data; # disable rewrite for debug
	my $rewritten = 0;
	my ($rw,$rwline);
	my $data;
	$data .= "#line 1 $realfile\n" if $realfile;
	my $i    = 0; # index in source file
	
	while(@data) {
		$i++;
		for( shift(@data)."\n" ) {
			#print STDERR "# line $i | $_";
			if (s/^\s*#\s*\@include\s+//) {
				unless ($base) {
					CORE::warn("Can't use \@include inside dynamycally loaded files without %INC entry at $realfile line $i.\n");
					$data .= "# include: Can't use \@include inside dynamycally loaded files without %INC entry\n";
					next;
				}
				s{\s*$}{};
				my $inc = $base . $_;
				my ($idata) = $self->rewrite(undef, $_, $inc);
				$idata .= "\n" unless $idata =~ /\n$/s;
				$data .= "# included: $inc\n" . $idata . "#line ".($i+1)." $realfile\n";
				if ( defined $rw ) {
					warn "\@rewrite $rw is ignored at $realfile line $rwline.\n";
					undef $rw;
				};
				$rewritten = 1;
				next;
			}
			elsif (s/^\s*#\s*\@rewrite\s+//) {
				warn "\@rewrite $rw is ignored at $realfile line $rwline.\n" if defined $rw;
				$rw = $_;chomp($rw);
				$rwline = $i;
				$data .= "\n";
				next;
			}
			elsif ($rw and !/^\s*$/) {
				#warn "rewriting $realfilename line $i using $rw defined on line $rwline";
				{
					$@ = undef;
					eval("#line $rwline $realfile\n".$rw);
					die "\@rewrite error: $@" if $@;
				}
				$rewritten = 1;
				undef $rw;undef $rwline;
			}
			$data .= $_;
		}
	}
	#print STDERR "evaling:\n$data" if $rewritten;
	return $data, $rewritten;
}

sub load_ref {
	my $self = shift;
	my ($cpkg,$cfile,$cline) = (caller 2)[0..2];
	@_ or warn("No args"),return; #
	defined $_[0] or warn("No fh"),return;
	my ($fh,$sub,$st);
	if (ref $_[0] eq 'CODE') {
		my ($gen,@arg) = @_;
		#warn "# Generator @_";
		my $out = '';
		{
			local $_;
			while ($gen->($gen,@arg)) {
				$out .= $_;
			}
		}
		return $out;
	} elsif ( ref $_[0] eq 'GLOB' ) {
		my $fh = shift;
		# seek $fh,0,0 or die "Cant seek $fh: $!";
		if (ref $_[0] eq 'CODE') {
			my ($filter,@arg) = @_;
			#warn "# Source filter @_";
			my $out = '';
			{
				local $/ = "\012";
				my $last = 0;
				while () {
					local $_ = <$fh>;
					$last=1,$_ = '' unless defined;
					#warn "line = <$_>";
					my $rc = $filter->($filter,@arg);
					$out .= $_;
					#$rc or last;
					$last and last;
				}
			}
			return $out;
		}
		else {
			#warn "# Simple fh";
			return scalar do { local $/; <$fh> };
		}
	} else {
		warn "Wrong INC code $_[0], dunno what to do at $cfile line $cline.\n";
	}
	return;
}

sub require : method {
	my $self = shift;
		local $_ = $_[0];
		my ($cpkg,$cfile,$cline) = (caller 0)[0..2];
		defined and length or die "Null filename used at $cfile line $cline.\n";
		print STDERR "# @_ ". in_effect(1) . "\n" if $ENV{RUSES};
		if (
			( !in_effect(1) ) or
			/[\x00-\x09]+/
			#( sprintf("%vd", $_) =~ /^\d+(?:\.\d+(?:\.\d+|)|)$/ )
			or /^\d+(\.\d+|)/
			or m{^(strict|warnings.*|utf8|feature|mro|Carp.*|Devel/Rewrite)\.pm$}
		) {
			return $old ? goto &$old : CORE::require($_);
		}
		#if ($INC{$_}) {
		if (exists $INC{$_}) {
			return 1 if $INC{$_};
			die "Compilation failed in require";
		}
		my $result;
		my ($data,$rwok,$refinc);
		ITER: {
			for my $inc (@INC) {
				if (my $ref = ref $inc) {
					#warn "require ref $ref";
					my @rv = ();
					{
						local $_ = $_;
						if ($ref eq 'CODE') {
							warn "Call $inc" if $ENV{RUSES};
							@rv = $inc->($inc,$_);
						}
						elsif ($ref eq 'ARRAY' and ref $inc->[0] eq 'CODE' ) {
							warn "Call $inc [ @$inc ]" if $ENV{RUSES};
							@rv = $inc->[0]($inc, $_);
							warn "Call $inc [ @$inc ]" if $ENV{RUSES};
						}
						elsif (UNIVERSAL::can($inc, 'isa')) {
							warn "Call $inc" if $ENV{RUSES};
							@rv = $inc->INC($_);
						}
						else {
							warn "Bad inc entry $inc";
							next ITER;
						}
						@rv or next ITER;# warn("No args 1"),next ITER;
						defined $rv[0] or next ITER;# warn("No fh 1"),next ITER;
					}
					$INC{$_} = $inc unless exists $INC{$_};
					warn "[@rv] \$INC{$_} = $INC{$_}" if $ENV{RUSES};
					my $indata = $self->load_ref(@rv) or next;
					my $origin;
					if (ref $INC{$_}) {
						(my $refaddr) = "$inc" =~ /\((0x[\da-f]+)\)/;
						$origin = "/loader/$refaddr/$_";
					} else {
						$origin = $INC{$_};
					}
					warn "Set origin for $_ to $INC{$_}" if $ENV{RUSES};
					($data,$rwok) = $self->rewrite($indata,$_,$origin);
					#warn "Rewritten($rwok): $data";
					last ITER;
				} else {
					my $realfilename = "$inc/$_";
					if (-f $realfilename.'c') {
						$realfilename .= 'c'; # .pmc
					}
					if (-f $realfilename) {
						$INC{$_} = $realfilename;
						#$result = do $realfilename;$result or $@ and die $@;last ITER; # this is how it works natively
						($data,$rwok) = $self->rewrite(undef,$_,$realfilename);
						last ITER;
					}
				}
			}
			die "!Can't locate $_ in \@INC (\@INC contains: @INC). at $cfile line $cline.\n";
		}
		{
			{
				use Data::Dumper;
				warn "Evaling ".Dumper($data)."\n\t" if $ENV{RSRC};
				$result = $self->doeval( $data, $cpkg );
				if ($@ and $ENV{RSRC}) {
					warn "eval $_ failed: $@" if $@;
				}
			}
			#$result or $@ and warn("Dying with $@ for $_"),die $@;
			if ($refinc) {
				#$INC{$_} = $refinc;
			}
		}
		if ($@) {
			$INC{$_} = undef;
			die $@;
		} elsif (!$result) {
			delete $INC{$_};
			die "$_ did not return a true value at $cfile line $cline.\n";
		} else {
			return $result;
		}
	
}

sub import {
	my $self = shift;
	$^H{$KEY} = 1;
	return if $done;
	#warn "\@rewrite enable";
	$old = \&CORE::GLOBAL::require;
	eval { $old->() };
	if ($@ =~ /CORE::GLOBAL::require/) { $old = undef; }
	*CORE::GLOBAL::require = sub {
		unshift @_,$self;
		goto &{$self->can('require')};
		#CORE::require($_);
	};
	$done = 1;
}

sub unimport {
	shift;
	$^H{$KEY} = 0;
	return unless $done;
	#warn "\@rewrite disable";
	return;
	if ($old) {
		*CORE::GLOBAL::require = $old;
		$old = undef;
	}else{
		undef *CORE::GLOBAL::require;
	}
	$done = undef;
	return;
}


=head1 AUTHOR

Mons Anderson, C<< <mons@cpan.org> >>

=head1 SUPPORT

You can look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Devel-Rewrite>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Devel-Rewrite>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/Devel-Rewrite>

=item * Search CPAN

L<http://search.cpan.org/dist/Devel-Rewrite/>

=item * GitHub

L<http://github.com/Mons/Devel-Rewrite>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2010 Mons Anderson.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
}
1; # End of Devel::Rewrite
