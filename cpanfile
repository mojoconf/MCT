# You can install this projct with curl -L http://cpanmin.us | perl - https://github.com/jhthorsen/mct/archive/master.tar.gz
requires 'DBD::Pg'                     => '3.4.2';
requires 'Mojolicious'                 => '6.00';
requires 'Mojo::Pg'                    => '1.10';
requires 'Mojolicious::Plugin::OAuth2' => '1.51';
requires 'Mojolicious::Plugin::AssetPack' => '0.39';
requires 'Mojolicious::Plugin::Ical'   => '0.02';
requires 'Mojolicious::Plugin::StripePayment' => '0.02';
requires 'Text::Markdown'              => '1.0';
test_requires 'Test::More' => '0.88';
