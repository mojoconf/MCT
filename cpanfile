# You can install this projct with curl -L http://cpanmin.us | perl - https://github.com/jhthorsen/mct/archive/master.tar.gz
requires 'DBD::Pg'                     => '3.4.2';
requires 'Mojolicious'                 => '6.00';
requires 'Mojo::Pg'                    => '1.10';
requires 'Mojolicious::Plugin::OAuth2' => '1.50';
test_requires 'Test::More' => '0.88';
