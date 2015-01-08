package Plack::Test::Debugger;

# ABSTRACT: A subclass of Plack::Test suitable for testing the debugger

use strict;
use warnings;

our $VERSION   = '0.03';
our $AUTHORITY = 'cpan:STEVAN';

# load the test implementation ...
BEGIN {  $ENV{'PLACK_TEST_IMPL'} = 'MockHTTP::WithCleanupHandlers' }

# now load Plack::Test ...
use Plack::Test;

# inherit the ->import method from Plack::Test, 
# this is one of those really horrid perl idioms
# that really should go away.
use parent 'Plack::Test';
our @EXPORT = qw[ test_psgi ];

1;

__END__

=pod

=head1 NAME

Plack::Test::Debugger - A subclass of Plack::Test suitable for testing the debugger

=head1 VERSION

version 0.03

=head1 DESCRIPTION

This module simply extends the L<Plack::Test> module to set the 
C<PLACK_TEST_IMPL> variable in C<%ENV> such that L<Plack::Test>
will use the L<Plack::Test::MockHTTP::WithCleanupHandlers> to 
run all the tests. See the module for more information.

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
