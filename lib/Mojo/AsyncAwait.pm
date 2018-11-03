package Mojo::AsyncAwait;

use Carp ();
use Mojo::Loader;
use Import::Into;

sub import {
  my $backend = $ENV{MOJO_ASYNCAWAIT_BACKEND} // $_[1] // '+Coro';
  $backend =~ s/^\+/Mojo::AsyncAwait::Backend::/;
  if(my $e = Mojo::Loader::load_class($backend)) {
    Carp::croak(ref $e ? $e : "Could not find backend $backend. Perhaps you need to install it?");
  }
  $backend->import::into(scalar caller);
}

1;


=encoding utf8

=head1 NAME

Mojo::AsyncAwait - An Async/Await implementation for Mojolicious

=head1 SYNOPSIS

  use Mojolicious::Lite -signatures;
  use Mojo::AsyncAwait;

  get '/' => async sub ($c) {

    my $mojo = await $c->ua->get_p('https://mojolicious.org');
    my $cpan = await $c->ua->get_p('https://metacpan.org');

    $c->render(json => {
      mojo => $mojo->result->code,
      cpan => $cpan->result->code
    });
  };

  app->start;

=head1 DESCRIPTION

Async/await is a language-independent pattern that allows nonblocking
asynchronous code to be structured simliarly to blocking code. This is done by
allowing execution to be suspended by the await keyword and returning once the
promise passed to await has been fulfilled.

This pattern simplies the use of both promises and nonblocking code in general
and is therefore a very exciting development for writing asynchronous systems.

If you are going to use this module to create async controllers actions in
L<Mojolicious> applications (as seen in the L</SYNOPSIS>), you are highly
encouraged to also use L<Mojolicious::Plugin::PromiseActions> in order to
properly handle exceptions in your action.

=head1 GOALS

The primary goal of this module is to provide a useful Async/Await
implementation for users of the Mojolicious ecosystem. It is for this reason
that L<Mojo::Promise> is used when new promises are created. Because this is
the primary goal, the intention is for it to remain useful even as other goals
are considered.

Secondarily, it is intended to be a testbed for early implementations of
Async/Await in the Perl 5 language. It is for this reason that the
implementation details are intended to be replaceable. This may manifest as a
pluggable backend or rather as wholesale rewrites of the internals. The result
should hopefully be backwards compatible, mostly because the interface is so
simple, just two keywords.

Of course, I always intend as much as possible that Mojolicious-focused code is
as useful as practically possible for the broader Perl 5 ecosystem. It is for
this reason that while this module returns L<Mojo::Promise>s, it can accept any
then-able (read: promise) which conforms enough to the Promises/A+ standard.
The Promises/A+ standard is intended to increase the interoperability of
promises, and while that line becomes more gray in Perl 5 where we don't have a
single ioloop implementation, we try our best.

As implementations stabilze, or change, certain portions may be spun off. The
initial implementation depends on L<Coro>. Should that change, or should users
want to use it with other promise implementations, perhaps that implementation
will be spun off to be used apart from L<Mojolicious> and/or L<Mojo::Promise>,
perhaps not.

Finally the third goal is to improve the mobility of the knowledge of this
pattern between languages. Users of Javascript probably are already familiar
with this patthern; when coming to Perl 5 they will want to continue to use it.
Likewise, as Perl 5 users take on new languages, if they are familiar with
common patterns in their new language, they will have an easier time learning.
Having a useable Async/Await library in Perl 5 is key to keeping Perl 5
relevent in moderning coding.

=head1 CAVEATS

First and foremost, this is all a little bit crazy. Please consider carefully
before using this code in production.

While many languages have async/await as a core language feature, currently in
Perl we must rely on modules that provide the mechanism of suspending and
resuming execution.

The default implementation relies on L<Coro> which does some very magical
things to the Perl interpreter. Other less magical implementations are in the
works however none are available yet. In the future if additional
implementations are available, this module might well be made pluggable. Please
do not rely on L<Coro> being the implmementation of choice.

Also note that while a L<Coro>-based implementation need not rely on L</await>
being called directly from an L</async> function, it is currently prohibitied
because it is likely that other/future implementations will rely on that
behavior and thus it should not be relied upon.

=head1 KEYWORDS

L<Mojo::AsyncAwait> provides two keywords (i.e. functions), both exported by
default.

=head2 async

  my $sub = async sub { ... };

The async keyword wraps a subroutine as an asynchronous subroutine which is
able to be suspended via L</await>. The return value(s) of the subroutine, when
called, will be wrapped in a L<Mojo::Promise>.

The async keyword must be called with a subroutine reference, which will be the
body of the async subroutine.

Note that the returned subroutine reference is not invoked for you.
If you want to immediately invoke it, you need to so manually.

  my $promise = async(sub{ ... })->();

If called with a preceding name, the subroutine will be installed into the current package with that name.

  async installed_sub => sub { ... };
  installed_sub();

If called with key-value arguments starting with a dash, the following options are available.

=over

=item -install

If set to a true value, the subroutine will be installed into the current package.
Default is false.
Setting this value to true without a C<-name> is an error.

=item -name

If C<-install> is false, this is a diagnostic name to be included in the subname for debugging purposes.
This name is seen in diagnostic information, like stack traces.

  my $named_sub = async -name => my_name => sub { ... };
  $named_sub->();

Otherwise this is the name that will be installed into the current package.

=back

Therefore, passing a bare name as is identical to setting both C<-name> and C<< -install => 1 >>.

  async -name => installed_sub, -install => 1 => sub { ... };
  installed_sub();

If the subroutine is installed, whether by passing a bare name or the C<-install> option, nothing is returned.
Otherwise the return value is the wrapped async subroutine reference.

=head2 await

  my $tx = await Mojo::UserAgent->new->get_p('https://mojolicious.org');
  my @results = await (async sub { ...; return @async_results })->();

The await keyword suspends execution of an async sub until a promise is
fulfilled, returning the promise's results. In list context all promise results
are returned. For ease of use, in scalar context the first promise result is
returned and the remainder are discarded.

If the value passed to await is not a promise (defined as having a C<then>
method>), it will be wrapped in a Mojo::Promise for consistency. This is mostly
inconsequential to the user.

Note that await can only take one promise as an argument. If you wanted to
await multiple promises you probably want L<Mojo::Promise/all> or less likely
L<Mojo::Promise/race>.

  my $results = await Mojo::Promise->all(@promises);

=head1 AUTHORS

Joel Berger <joel.a.berger@gmail.com>

Marcus Ramberg <mramberg@cpan.org>

=head1 CONTRIBUTORS

Sebastian Riedel <kraih@mojolicious.org>

=head1 ADDITIONAL THANKS

Matt S Trout (mst)

Paul Evans (LeoNerd)

John Susek

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018, L</AUTHORS> and L</CONTRIBUTORS>.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojo::Promise>

L<Mojolicious::Plugin::PromiseActions>

L<MDN Async/Await|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/async_function>

L<Coro::State>

L<Future::AsyncAwait>

L<PerlX::AsyncAwait>

=cut

