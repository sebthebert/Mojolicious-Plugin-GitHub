use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::GitHub',
  VERSION_FROM => 'lib/Mojolicious/Plugin/GitHub.pm',
  AUTHOR       => 'A Good Programmer <nospam@cpan.org>',
  PREREQ_PM    => {'Mojolicious' => '4.99'},
  test         => {TESTS => 't/*.t'}
);
