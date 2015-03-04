package MCT::Plugin::ACT;
use Mojo::Base 'Mojolicious::Plugin';
use constant DEBUG => $ENV{ACT_DEBUG} || 0;

our $VERSION = '0.01';

sub register {
  my ($self, $app, $config) = @_;
  my $url = Mojo::URL->new($config->{url});
  my $path = $url->path->to_string;
  my $domain = $url->host;

  $path =~ s!/+$!!;
  $url = $url->clone->host('act.yapc.eu');

  $app->routes->any("$path/*whatever", {whatever => ''})->to(cb => sub {
    my $c = shift;
    my $whatever = $c->stash('whatever');
    my $ua = Mojo::UserAgent->new;

    $c->delay(
      sub {
        my ($delay) = @_;
        warn "[ACT] GET $url/$whatever (Host: $domain)\n" if DEBUG;
        $ua->on(start => sub { pop->req->headers->host($domain) });
        $ua->get("$url/$whatever", $delay->begin);
      },
      sub {
        my ($delay, $tx) = @_;
        my $ct = $tx->res->headers->content_type || '';

        if ($ct =~ /html/) {
          my $dom = $tx->res->dom;
          my $host_port = $c->tx->req->url->to_abs->host_port;

          $_->{href} =~ s!^/!http://$host_port/! for $dom->find('[href]')->each;
          $_->{src} =~ s!^/!http://$host_port/! for $dom->find('[src]')->each;

          $c->render(text => $dom->to_string, status => $tx->res->code);
        }
        else {
          $c->res->headers->content_type($ct || 'text/plain');
          $c->render(data => $tx->res->body, status => $tx->res->code);
        }

        return $ua; # keep the object around so it does not go out of scope
      }
    );
  });
}

1;
__END__

=head1 NAME

MCT::Plugin::ACT - Description

=head1 VERSION

0.01

=head1 DESCRIPTION

L<MCT::Plugin::ACT> is a ...

=head1 SYNOPSIS

  use MCT::Plugin::ACT;
  my $obj = MCT::Plugin::ACT->new;

=head1 METHODS

=head2 register

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut
