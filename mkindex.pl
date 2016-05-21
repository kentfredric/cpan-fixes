#!perl
use strict;
use warnings;

use Path::Tiny qw( path );

my $root = path(__FILE__)->parent;

my $iter = $root->iterator({
  recurse => 1,
  follow_symlinks => 0,
});

while ( my $path = $iter->() ) {
  next if $path->basename eq 'mkindex.pl';
  next if $root->child('.git')->subsumes($path);
  next if $path->is_dir;
  my $relpath =$path->relative($root);
  my $size = $path->stat->size;

  my $sz = sprintf "%5s", $size;
  $sz =~ s/ /&nbsp;/g;
  printf "<div style=\"font-family: monospace\">%s - <a href=\"./%s\">%s</a></div>\n", $sz, $relpath, $relpath;
}


