package Mojolicious::Plugin::Connect::User;
use Mojo::Base 'Mojo::JSON::Pointer';
use Mojo::Util;

our $VERSION = '0.01';

has provider => sub { die "provider is required" };
has token => '';

sub avatar_url {
  my $self = shift;

  if (my $avatar_url = $self->data->{avatar_url}) { # github
    return $avatar_url;
  }
  if (my $email = $self->email) { # fallback
    return sprintf 'http://www.gravatar.com/avatar/%s', Mojo::Util::md5_sum($email);
  }

  return '';
}

sub email {
  my $self = shift;
  my $email;

  if ($self->provider eq 'eventbrite') {
    if (my $emails = $self->data->{emails}) {
      ($email) = map { $_->{email} } grep { $_->{verified} } @$emails;
    }
  }

  return $email || $self->data->{email} || '';
}

sub address { $_[0]->data->{location} || '' } # github
sub id { $_[0]->data->{id} || '' } # github
sub name { $_[0]->data->{name} || '' } # github
sub username { $_[0]->data->{login} || '' } # github
sub web_page { $_[0]->data->{blog} || '' } # github

sub new { Mojo::Base::new(@_) }

sub TO_JSON {
  my $self = shift;

  return {
    address => $self->address,
    avatar_url => $self->avatar_url,
    email => $self->email,
    name => $self->name,
    username => $self->username,
    web_page => $self->web_page,
  };
}

1;
__END__

=head1 NAME

Mojolicious::Plugin::Connect::User - Connected OAuth2 user information

=head1 VERSION

0.01

=head1 DESCRIPTION

L<Mojolicious::Plugin::Connect::User> is an object that represent the
data for a user. It holds all the information retrieved from the OAuth2
provider, but also has accessors to extract standard information.

This class is a subclass of L<Mojo::JSON::Pointer>.

=head1 SYNOPSIS

  use Mojolicious::Plugin::Connect::User;
  my $user = Mojolicious::Plugin::Connect::User->new(
               provider => "google",
               data => $json_data,
             );
  print $user->email;

=head1 ATTRIBUTES

=head2 provider

=head2 token

=head1 METHODS

=head2 email

=head2 id

=head2 new

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut
