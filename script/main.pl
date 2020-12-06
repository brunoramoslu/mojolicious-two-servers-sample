#!/usr/bin/env perl

use Mojo::Base -strict, -signatures;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Mojo::Log;

use MyServer::Server;

my $server = MyServer::Server->new();

$server->set_templates_folder("$FindBin::Bin/../templates");
$server->run();
