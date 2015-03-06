package Mojo::Github;

use Mojo::Base -base;
use Mojo::UserAgent;

our $VERSION = '0.01';

has token => sub { die '"token" is required in constructor' };
has ua => sub { Mojo::UserAgent->new };

sub user {
  my $cb = pop;
  my $self = shift;
  my $id = shift;
  my %headers = (Authorization => sprintf 'token %s', $self->token);

  Mojo::IOLoop->delay(
    sub {
      $self->ua->get($self->_url($id ? "/users/$id" : "/user"), \%headers, shift->begin);
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
  Mojo::Github::MOCKED() ? "/mocked/github$_[1]" : "https://api.github.com$_[1]";
}

sub MOCKED { 0 }

1;

=head1 NAME

Mojo::Github - API for github.com

=head1 VERSION

0.01

=head1 DESCRIPTION

L<Mojo::Github> is a L<Mojolicious> module which can talk to
L<https://api.github.com>.

See L<https://developer.github.com/> for more details.

=head1 SYNOPSIS

  use Mojo::Github;
  my $github = Mojo::Github->new;

  $github->token($secret_token);

=head1 ATTRIBUTES

=head2 token

=head2 ua

=head1 METHODS

=head2 user

  $self->user(sub { my ($self, $err, $user) = @_; });

C<$user> is a Perl data structure. See also
L<https://developer.github.com/v3/users/#get-the-authenticated-user>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut
