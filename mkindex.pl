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
  next if $path->basename =~ qr/\A(mkindex[.]pl|index[.]html)\z/;
  next if $root->child('.git')->subsumes($path);
  next if $path->is_dir;
  my $relpath =$path->relative($root);
  my $size = $path->stat->size;

  my $sz = sprintf "%20s", $size;
  $sz =~ s/ /&nbsp;/g;
  my $decor = "font-family: monospace;";
  my $a_decor = "";
  if ( $path->basename !~ /\.tar.gz$/ ) {
    $a_decor .= "color: #999";
  } elsif (  $path !~ /5\.25\.1/  ) {
    $a_decor .= "color: #955";
  }
  if ( length $a_decor ) {
    $a_decor = " style=\"$a_decor\"";
  }
  printf "<div style=\"$decor\">%s - <a href=\"./%s\"${a_decor}>%s</a></div>\n", $sz, $relpath, $relpath;
}


