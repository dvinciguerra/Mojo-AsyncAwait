use Test::More;
use Test::Mojo;

use Mojo::AsyncAwait;
use Mojolicious::Lite;

my @hooks;

app->hook(
  after_build_tx => sub {
    my ($tx, $app) = @_;
    push @hooks, $tx;
  }
);

app->hook(
  around_dispatch => sub {
    my ($next, $c) = @_;
    push @hooks, $c;
    $next->();
    push @hooks, 'after_dispatch';
  }
);

app->hook(
  around_action => sub {
    my ($next, $c) = @_;
    push @hooks, 'before_action';
    my $res = $next->();
    $res->then(sub{ push @hooks, shift });
  }
);

get '/' => async sub {
  my $c       = shift;
  $c->render_later;
  my $promise = Mojo::Promise->new;
  Mojo::IOLoop->timer(1 => sub { $promise->resolve("hello world") });
  my $text = await $promise;
  $c->render(text => $text);
  return "action done";
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is("hello world");

#warn Data::Dumper::Dumper(\@hooks);
isa_ok($hooks[0], 'Mojo::Transaction');
isa_ok($hooks[1], 'Mojolicious::Controller');
is($hooks[2], 'before_action');
is($hooks[3], 'after_dispatch');
is($hooks[4], 'action done');

done_testing;
