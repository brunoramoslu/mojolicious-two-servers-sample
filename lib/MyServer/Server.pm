package MyServer::Server;

use Mojo::Base -strict, -signatures;
use Mojo::IOLoop;
use Mojo::Log;

use Mojolicious;
use Mojo::Server::Daemon;

use Time::HiRes qw(usleep);

use Data::Dumper;

sub new($class, $log = Mojo::Log->new()) {
    my $self = {
        'log'      => $log,
        'sessions' => {},
        'state'    => {
            'time' => {},
        },
    };
    return bless $self, $class;
}

sub send_welcome($self, $stream) {
    my $log = $self->{'log'};
    $log->debug("Sending welcome message ...");
    $stream->write("Welcome to the server");
}

sub process($self, $session, $bytes) {
    my $log = $self->{'log'};
    $log->debug("Sending echo for '$bytes'");
    my $own_id = $session;
    for my $id (sort keys %{$self->{'sessions'}}) {
        $self->{'sessions'}->{$id}->{'stream'}->write($bytes);
    }
}

sub set_templates_folder($self,$path) {
    $self->{'templates_folder'} = $path;
}

sub run($self) {
    my $log = $self->{'log'};
    my $sessions = $self->{'sessions'};

    $log->debug("Starting server ...");
    $log->debug("Protocol Handler Callbacks: " . Dumper($self->{callbacks}));

    # Listen on port 3000
    Mojo::IOLoop->server({ port => 3000 } => sub {
        my ($loop, $stream, $id) = @_;
        $log->debug("Connection ID: $id");
        $log->debug("Setting stream timeout ...");
        $stream->timeout(60);
        $log->debug("Setting timer for ping_request (25s) ...");
        $loop->timer(5 => sub {
            $self->send_welcome($stream);
        });
        $log->debug("Can Write: : " . $stream->can_write);

        $log->debug("Creating session ...");

        my $session = {};

        $log->debug("Storing session in global sessions list...");

        $sessions->{$id} = $session;

        $log->debug(Dumper($sessions));

        $session->{'stream'} = $stream;

        $stream->on(read => sub {
            my ($stream, $bytes) = @_;
            $log->debug("bytes read: " . length($bytes));
            $self->process($session, $bytes);
        });

        $stream->on(close => sub {
            my $stream = shift;
            $log->debug("Removing session '$id' ...");
            if (exists $sessions->{$id}) {
                $log->debug("Deleting session ...");
                delete $sessions->{$id};
            }
            else {
                $log->error("Cannot find session '$id' in sessions list!");
            }
        });
    });

    # Perform operation every x seconds

    my $TIMER_SECONDS = 1;

    Mojo::IOLoop->recurring($TIMER_SECONDS => sub {
        my $loop = shift;
        $log->debug("********************************************************************************");
        $log->debug("Timer $TIMER_SECONDS SECOND(s)");
        $log->debug(join("|"), keys %$sessions);
        for my $id (sort keys %$sessions) {
            my $session = $sessions->{$id};

            my $time = time();
            my $minutes = ($time / 60) % 360;
            $log->debug("Minutes: $minutes");
            $log->debug("Time: " . int($minutes / 60) . ":" . $minutes % 60);
            $log->debug("Seconds: " . $time % 60);

            if ($time % 60 == 0) {
                $log->debug("New minute");
                $log->debug("Better do something ...");
            }
        }
        $log->debug("********************************************************************************");
    });

    my $app = Mojolicious->new;

    # TODO: better handle template location
    $log->debug("PATH before custom path append: " . join(" | ", @{$app->renderer->paths}));
    push @{$app->renderer->paths}, $self->{'templates_folder'};
    $log->debug("PATH after custom path append: " . join(" | ", @{$app->renderer->paths}));

    $app->routes->get('/' => sub($c) {
        $c->render(template => 'sessions', sessions => $sessions);
    });

    my $daemon = Mojo::Server::Daemon->new(app => $app)->listen([ 'http://127.0.0.1:3001' ])->start;

    # Start event loop if necessary
    Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

    $log->debug("Done.");
}

1;