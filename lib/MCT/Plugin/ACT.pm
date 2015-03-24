package MCT::Plugin::ACT;
use Mojo::Base 'Mojolicious::Plugin';
use constant DEBUG => $ENV{ACT_MODEL_DEBUG} || 0;

our $VERSION = '0.01';

sub register {
  my ($self, $app, $config) = @_;
  my $base = Mojo::URL->new($config->{url});
  my $remote_path = $base->path->to_string;
  my $local_path = $config->{path} || $remote_path;
  my $domain = $base->host;

  $remote_path =~ s!/+$!!;
  $local_path =~ s!/+$!/!;
  $base = $base->clone->host('act.yapc.eu');

  for my $alias (@{$config->{alias}||[]}) {
    $alias =~ s!/+$!/!;
    $app->routes->any("$alias/*whatever", {whatever => ''})->to(cb => sub {
      my $c = shift;
      my $query = $c->req->url->query->to_string;
      $c->redirect_to(sprintf '%s/%s%s', $local_path, $c->param('whatever'), $query ? "?$query" : "");
    });
  }

  $app->routes->any("$local_path/*whatever", {whatever => ''})->to(cb => sub {
    my $c = shift;
    my $whatever = $c->stash('whatever');
    my $ua = Mojo::UserAgent->new;
    my $tx = Mojo::Transaction::HTTP->new;

    $c->delay(
      sub {
        my ($delay) = @_;
        warn "[ACT] GET $base/$whatever (Host: $domain)\n" if DEBUG;
        $tx->req($c->tx->req->clone);
        $tx->req->url->scheme('http')->host($base->host)->path("$remote_path/$whatever");
        $tx->req->headers->host($domain);
        $ua->start($tx, $delay->begin);
      },
      sub {
        my ($delay, $tx) = @_;
        my $ct = $tx->res->headers->content_type || '';

        if ($ct =~ /html/) {
          my $dom = $tx->res->dom;
          my $url = $c->tx->req->url->to_abs;
          my $host_port = $url->host_port;
          my $scheme = $url->scheme;

          $_->{href} =~ s!^$remote_path!$scheme://$host_port$local_path! for $dom->find('[href]')->each;
          $_->{src} =~ s!^$remote_path!$scheme://$host_port$local_path! for $dom->find('[src]')->each;

          $c->tx->res->headers($tx->res->headers);
          $c->render(text => $dom->to_string, status => $tx->res->code);
        }
        else {
          $c->res->headers->content_type($ct || 'text/plain');
          $c->tx->res($tx->res);
          $c->rendered;
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
