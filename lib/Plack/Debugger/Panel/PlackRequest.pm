package Plack::Debugger::Panel::PlackRequest;

# ABSTRACT: Debug panel for inspecting the Plack $env

use strict;
use warnings;

our $VERSION   = '0.03';
our $AUTHORITY = 'cpan:STEVAN';

use parent 'Plack::Debugger::Panel';

sub new {
    my $class = shift;
    my %args  = @_ == 1 && ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;

    $args{'title'}     ||= 'Plack Request';
    $args{'formatter'} ||= 'ordered_key_value_pairs';

    $args{'before'} = sub {
        my ($self, $env) = @_;
        $self->set_result([ 
            map { 
                my $value = $env->{ $_ };
                if ( ref $value ) {
                    # NOTE:
                    # break down refs in a sane way, 
                    # but assume that nothing nests 
                    # beyond one level, this can be 
                    # improved later on if need be
                    # with a simple visitor closure.
                    # - SL
                    if ( ref $value eq 'ARRAY' ) {
                        $value = [ map { ($_ . '') } @$value ];
                    } 
                    elsif ( ref $value eq 'HASH' ) {
                        $value = { map { $_ => ($value->{ $_ } . '') } keys %$value };
                    }
                    else {
                        $value .= '';
                    }
                } 
                else {
                    $value .= '';
                }
                ($_ => $value);
            } sort keys %$env # sorting keys creates predictable ordering ...
        ]);
    };

    $class->SUPER::new( \%args );
}

1;

__END__

=pod

=head1 NAME

Plack::Debugger::Panel::PlackRequest - Debug panel for inspecting the Plack $env

=head1 VERSION

version 0.03

=head1 DESCRIPTION

This is a L<Plack::Debugger::Panel> subclass that will display the 
PSGI request as sensibly as possible.

=head1 ACKNOWLEDGMENT

This module was originally developed for Booking.com. With approval 
from Booking.com, this module was generalized and published on CPAN, 
for which the authors would like to express their gratitude.

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Stevan Little.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
