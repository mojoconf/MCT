package Mojo::Eventbrite;

use Mojo::Base -base;
use Mojo::UserAgent;

our $VERSION = '0.01';

has token => sub { die '"token" is required in constructor' };
has ua => sub { Mojo::UserAgent->new };

sub user {
  my $cb = pop;
  my $self = shift;
  my $id = shift || 'me';

  Mojo::IOLoop->delay(
    sub {
      $self->ua->get($self->_url("/v3/users/$id"), shift->begin);
    },
    sub {
      my ($delay, $tx) = @_;
      my $err = $tx->res->error;
      return $self->$cb($err->{message}, undef) if $err;
      return $self->$cb('', $tx->res->json);
    },
  );
}

sub _url {
  Mojo::Eventbrite::MOCKED() ? "/mocked/eventbrite$_[1]" : "https://www.eventbriteapi.com$_[1]";
}

sub MOCKED { 0 }

1;

=head1 NAME

Mojo::Eventbrite - API for eventbrite.com

=head1 VERSION

0.01

=head1 DESCRIPTION

L<Mojo::Eventbrite> is a L<Mojolicious> module which can talk to
L<http://eventbrite.com>.

See L<http://developer.eventbrite.com/> for more details.

=head1 SYNOPSIS

  use Mojo::Eventbrite;
  my $eventbrite = Mojo::Eventbrite->new;

  $eventbrite->token($secret_token);

=head1 ATTRIBUTES

=head2 token

=head2 ua

=head1 METHODS

=head2 user

  $self->user($id, sub {
    my ($self, $err, $user) = @_;
  });

Default C<$id> is "me". C<$user> is a Perl data structure. See also
L<http://developer.eventbrite.com/docs/user-details/>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut
