#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Plack::Builder;

use Plack::Test::Debugger;    
use Plack::Test::Debugger::ResultGenerator;    
use HTTP::Request::Common qw[ GET PUT ];
use Path::Class           qw[ dir ];
use JSON::XS;

BEGIN {
    use_ok('Plack::Debugger');
    use_ok('Plack::Debugger::Storage');

    use_ok('Plack::App::Debugger');
}

my $DATA_DIR = dir('./t/050-tmp-app-debugger/');
my $JSON     = $Plack::Test::Debugger::ResultGenerator::JSON;

# create tmp dir if needed
mkdir $DATA_DIR unless -e $DATA_DIR;

# cleanup tmp dir
{ ((-f $_ && $_->remove) || (-d $_ && $_->rmtree)) foreach $DATA_DIR->children( no_hidden => 1 ) }

my $debugger = Plack::Debugger->new(
    storage => Plack::Debugger::Storage->new(
        data_dir     => $DATA_DIR,
        serializer   => sub { $JSON->encode( shift ) },
        deserializer => sub { $JSON->decode( shift ) },
        filename_fmt => $Plack::Test::Debugger::ResultGenerator::FILENAME_FMT,
    )
);

my $app = Plack::App::Debugger->new( debugger => $debugger )->to_app;

test_psgi($app, sub {
        my $cb  = shift;

        # test some errors

        is($cb->(PUT '/1234')->code, 405, '... got the expected (Method Not Allowed) error');
        is($cb->(GET '/')->code, 400, '... got the expected (Bad Request) error');

    }
);

# cleanup tmp dir
{ ((-f $_ && $_->remove) || (-d $_ && $_->rmtree)) foreach $DATA_DIR->children( no_hidden => 1 ) }

done_testing;







