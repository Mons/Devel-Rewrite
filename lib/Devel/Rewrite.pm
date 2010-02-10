package Devel::Rewrite;

use 5.010;
use strict;
use warnings;

=head1 NAME

Devel::Rewrite - Development preprocessor

=cut

our $VERSION = '0.01';

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

Also this module implements pragmatic behaviour.

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

=head1 DESCRIPTION

The main purpose of this module is creating optional debugging routines.

- which does not require any additional prerequsites for production, like for ex L<Devel::Leak::Cb>

- which does not provide any perfomance overhead in production enveronment.

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

=cut

our $KEY = '@rewrite';
our $old;
our $done;
our $effective = 0;

sub in_effect {
	my $level = shift // 0;
	my $hinthash = (caller($level))[10];
	return $hinthash->{$KEY} ? 1 : 0;
}

sub rewrite {
	use strict;
	my $self = shift;
	my $realfilename = shift;
	( my $base = $realfilename ) =~ s{[^/]+$}{};
	my @data = do {
		open my $f, '<', $realfilename or die "can't open file $realfilename: $!";
		<$f>;
	};
	my $rewritten = 0;
	my ($rw,$rwline);
	my $data = "#line 1 $realfilename\n";
	my $i    = 0; # index in source file
	my $grow = 0; # grow size for array;
	
	while(@data) {
		$i++;
		for( shift @data ) {
			if (s/^\s*#\s*\@include\s+//) {
				s{\s*$}{};
				my $inc = $base . $_;
				my $idata = $self->rewrite($inc);
				$idata .= "\n" unless $idata =~ /\n$/s;
				$data .= "# included: $inc\n" . $idata . "#line ".($i+1)." $realfilename\n";
				if ( defined $rw ) {
					warn "\@rewrite $rw is ignored at $realfilename line $rwline.\n";
					undef $rw;
				};
				next;
				#warn "include $inc + \n@lines";
			}
			elsif (s/^\s*#\s*\@rewrite\s+//) {
				warn "\@rewrite $rw is ignored at $realfilename line $rwline.\n" if defined $rw;
				$rw = $_;chomp($rw);
				$rwline = $i;
				$data .= "\n";
				next;
			}
			elsif ($rw and !/^\s*$/) {
				#warn "rewriting $realfilename line $i using $rw defined on line $rwline";
				{
					$@ = undef;
					eval("#line $rwline $realfilename\n".$rw);
					die "\@rewrite error: $@" if $@;
				}
				$rewritten = 1;
				undef $rw;undef $rwline;
			}
			$data .= $_;
		}
	}
	#warn "evaling:\n$data" if $rewritten;
	return $data;
}

sub require : method {
	my $self = shift;
		local $_ = $_[0];
		if (
			( !in_effect(1) and !$effective ) or
			( !/\w/ and sprintf("%vd", $_) =~ /^\d+\.\d+(?:\.\d+|)$/ )
			or /^\d+\.\d+$/
			or m{^(strict|warnings|utf8|feature|mro|Devel/Rewrite)\.pm$}
		) {
			return $old ? goto &$old : CORE::require($_);
		}
		#warn "myrequire @_ : active=".in_effect(1)." effective=$effective";
		#if (( !in_effect(1) and !$effective )) {
		#	return $old ? goto &$old : CORE::require($_);
		#}
		if (exists $INC{$_}) {
			return 1 if $INC{$_};
			die "Compilation failed in require";
		}
		my ($cfile,$cline) = (caller)[1,2];
		my $result;
		ITER: {
			for my $prefix (@INC) {
				my $realfilename = "$prefix/$_";
				if (-f $realfilename) {
					$INC{$_} = $realfilename;
					#$result = do $realfilename;
					#$result = 
					my $data = $self->rewrite($realfilename);
					{
						local $effective = 1;
						# since we're evaling foreign code, switch off our pragmas
						no strict;
						no warnings;
						$result = eval( "#line 1 $realfilename\n".$data );
					}
					$result or $@ and die $@;
					last ITER;
				}
			}
			die "Can't locate $_ in \@INC (\@INC contains: @INC). at $cfile line $cline.\n";
		}
		if ($@) {
			$INC{$_} = undef;
			die $@;
		} elsif (!$result) {
			delete $INC{$_};
			die "$_ did not return true value at $cfile line $cline.\n";
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

1; # End of Devel::Rewrite
