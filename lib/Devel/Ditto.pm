package Devel::Ditto;

use 5.008;

=head1 NAME

Devel::Ditto - Identify where print output comes from

=head1 VERSION

This document describes Devel::Ditto version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  perl -MDevel::Ditto myprog.pl
  
=head1 DESCRIPTION

=head1 INTERFACE 

=cut

no warnings;

open( REALSTDOUT, ">&STDOUT" );
open( REALSTDERR, ">&STDERR" );

use warnings;
use strict;

sub import {
  my $class  = shift;
  my %params = @_;

  tie *STDOUT, $class, %params,
   is_err  => 0,
   realout => sub {
    open( local *STDOUT, ">&REALSTDOUT" );
    $_[0]->( @_[ 1 .. $#_ ] );
   };

  tie *STDERR, $class, %params,
   is_err  => 1,
   realout => sub {
    open( local *STDOUT, ">&REALSTDERR" );
    $_[0]->( @_[ 1 .. $#_ ] );
   };
}

sub TIEHANDLE {
  my ( $class, %params ) = @_;
  bless \%params, $class;
}

{
  my $depth = 0;

  sub _caller {
    my $self = shift;
    while () {
      my ( $pkg, $file, $line ) = caller $depth;
      return unless defined $pkg;
      return ( $pkg, $file, $line )
       unless $pkg->isa( __PACKAGE__ );
      $depth++;
    }
  }
}

sub _logbit {
  my $self = shift;
  my ( $pkg, $file, $line ) = $self->_caller();
  return "[$pkg, $file, $line] ";
}

sub PRINT {
  my $self = shift;
  $self->{realout}->( sub { print $self->_logbit, @_ }, @_ );
}

sub PRINTF {
  my $self = shift;
  $self->PRINT( sprintf $_[0], @_[ 1 .. $#_ ] );
}

sub WRITE {
  my $self = shift;
  $self->{realout}->(
    sub {
      my ( $buf, $len, $offset ) = @_;
      syswrite STDOUT, $buf, $len, defined $offset ? $offset : 0;
    },
    @_
  );
}

1;
__END__

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-devel-Ditto@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Andy Armstrong C<< <andy@hexten.net> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
