package Plack::Debugger::Storage;

# ABSTRACT: The storage manager for debugging data

use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use File::Spec;

sub new {
    my $class = shift;
    my %args  = @_ == 1 && ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;

    die "You must specify a data directory for collecting debugging data"
        unless defined $args{'data_dir'};

    die "You must specify a valid & writable data directory"
        unless -d $args{'data_dir'} && -w $args{'data_dir'};

    foreach (qw[ serializer deserializer ]) {
        die "You must provide a $_ callback"
            unless defined $args{ $_ };

        die "The $_ callback must be a CODE reference"
            unless ref $args{ $_ } 
                && ref $args{ $_ } eq 'CODE';
    }

    bless {
        data_dir     => $args{'data_dir'},
        serializer   => $args{'serializer'},
        deserializer => $args{'deserializer'},
        filename_fmt => $args{'filename_fmt'} || '%s',
    } => $class;
}

# accessors 

sub data_dir     { (shift)->{'data_dir'}     } # directory where collected debugging data is stored
sub serializer   { (shift)->{'serializer'}   } # CODE ref serializer for data into data-dir
sub deserializer { (shift)->{'deserializer'} } # CODE ref deserializer for data into data-dir
sub filename_fmt { (shift)->{'filename_fmt'} } # format string for filename, takes the request UID (optional)

# ...

sub store_request_results {
    my ($self, $request_uid, $results) = @_;
    $self->_store_results( $self->data_dir, (sprintf $self->filename_fmt => $request_uid), $results );
}

sub store_subrequest_results {
    my ($self, $request_uid, $subrequest_uid, $results) = @_;
    my $dir = File::Spec->catfile( $self->data_dir, $request_uid );
    mkdir $dir or die "Could not create $dir because $!"
        unless -e $dir;
    $self->_store_results( $dir, (sprintf $self->filename_fmt => $subrequest_uid), $results );
}

sub load_request_results {
    my ($self, $request_uid) = @_;
    return $self->_load_results( $self->data_dir, (sprintf $self->filename_fmt => $request_uid) );
}

sub load_subrequest_results {
    my ($self, $request_uid, $subrequest_uid) = @_;
    my $dir = File::Spec->catfile( $self->data_dir, $request_uid );
    die "Could not find $dir" unless -e $dir;
    return $self->_load_results( $dir, (sprintf $self->filename_fmt => $subrequest_uid) );
}

sub load_all_subrequest_results {
    my ($self, $request_uid) = @_;
    my $dir = File::Spec->catfile( $self->data_dir, $request_uid );
    return [] unless -e $dir;
    return [
        map {
            $self->_load_results( $dir, (File::Spec->splitpath($_))[2] )
        } glob( File::Spec->catfile( $dir, sprintf $self->filename_fmt => '*' ) )
    ];
}

sub load_all_subrequest_results_modified_since {
    my ($self, $request_uid, $epoch) = @_;
    die "You must specify an epoch to check modification date against"
        unless $epoch;
    my $dir = File::Spec->catfile( $self->data_dir, $request_uid );
    return [] unless -e $dir;
    return [
        map {
            $self->_load_results( $dir, (File::Spec->splitpath($_))[2] )
        } grep {
            (stat( $_ ))[9] > $epoch
        } glob( File::Spec->catfile( $dir, sprintf $self->filename_fmt => '*' ) )
    ];
}

# private utils ...

sub _store_results {
    my ($self, $dir, $filename, $results) = @_;
    my $file = File::Spec->catfile( $dir, $filename );
    my $fh   = IO::File->new( $file, '>' ) or die "Could not open file($file) for writing because: $!";
    $fh->print( $self->serializer->( $results ) );
    $fh->close;
}

sub _load_results {
    my ($self, $dir, $filename) = @_;
    my $file = File::Spec->catfile( $dir, $filename );
    my $fh   = IO::File->new( $file, '<' ) or die "Could not open file($file) for reading because: $!";
    my $results = $self->deserializer->( join '' => <$fh> ) ;
    $fh->close;
    $results;
}


1;

__END__

=pod

=head1 NAME

Plack::Debugger::Storage - The storage manager for debugging data

=head1 VERSION

version 0.01

=head1 DESCRIPTION

This module handles the loading and storing of the debugging data that is 
generated by the L<Plack::Debugger> during a web request.

=head1 METHODS

=over 4

=item C<new (%args)>

This expects to find a C<data_dir> key in the C<%args> which is basically 
a writable directory that exists. It also expects a pair of callbacks 
under the C<serializer> and C<deserializer> keys to handle the serialization 
needs for the data. It optionally can take a C<filename_fmt> argument which 
allows you to specify how the debugger data files names are generated. 

=item C<data_dir>

This is an acccessor for the C<data_dir> key specified in the constructor.

=item C<serializer>

This is an acccessor for the C<serializer> key specified in the constructor.

=item C<deserializer>

This is an acccessor for the C<deserializer> key specified in the constructor.

=item C<filename_fmt>

This is an acccessor for the C<filename_fmt> key which was optionally specified 
in the constructor.

=item C<store_request_results ($request_uid, $results)>

Given a C<$request_uid> this will write the C<$results> to a file into the 
C<data_dir>.

=item C<store_subrequest_results ($request_uid, $subrequest_uid, $results)>

Given a C<$request_uid> and C<$subrequest_uid> this will write the C<$results> 
to a file in the appropriate sub-folder in the C<data_dir>.

=item C<load_request_results ($request_uid)>

Given a C<$request_uid> this will load the corresponding set of results
from a file in the C<data_dir>.

=item C<load_subrequest_results ($request_uid, $subrequest_uid)>

Given a C<$request_uid> and C<$subrequest_uid> this will load a specific set
of results from the appropriate sub-folder in the C<data_dir>.

=item C<load_all_subrequest_results ($request_uid)>

Given a C<$request_uid> this will load all the associated sub-request results 
from the appropriate sub-folder in the C<data_dir>.

=item C<load_all_subrequest_results_modified_since ($request_uid, $epoch)>

Given a C<$request_uid> this will load all the associated sub-request results 
from the appropriate sub-folder in the C<data_dir> that have been created 
since the C<$epoch>.

=back

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
