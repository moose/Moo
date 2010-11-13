use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'Moo',
  VERSION_FROM => 'lib/Moo.pm',
  ABSTRACT_FROM => 'lib/Moo.pm',
  AUTHOR => 'Matt S Trout <mst@shadowcat.co.uk>',
  LICENSE => 'perl',
);
