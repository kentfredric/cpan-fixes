#!perl
use strict;
use warnings;

use experimental "signatures";
use Path::Tiny qw( path );
use Path::Iterator::Rule qw();

my $data = get_data(
    my $root = path(__FILE__)->parent,
    {
        tar   => qr/\.tar\.gz$/,
        patch => qr/\.patch$/,
    },
);

print render_style();
print render_data($data);
exit 0;

sub get_data ( $dir, $rules ) {
    my %struct = ();
    for my $package ( get_packages($dir) ) {
        $struct{$package} = classify_files( [ get_files($package) ], $rules );
    }
    return \%struct;
}

sub get_packages( $dir ) {
    my $rule = Path::Iterator::Rule->new();
    $rule->skip_vcs;
    $rule->dir;
    $rule->min_depth(2);
    return $rule->all($dir);
}

sub get_files( $dir ) {
    my $frule = Path::Iterator::Rule->new();
    $frule->file();
    $frule->not( $frule->new->name('index.html') );
    $frule->not( $frule->new->name('mkindex.pl') );
    return $frule->all($dir);
}

sub classify_files ( $file_list, $rules ) {
    my %struct = ();
    for my $file ( @{$file_list} ) {
        my $basename = path($file)->basename;
        my $matched;
        for my $rule ( keys %{$rules} ) {
            if ( $basename =~ $rules->{$rule} ) {
                $matched = 1;
                push @{ $struct{$rule} ||= [] }, $file;
                next;
            }
        }
        push @{ $struct{other} ||= [] }, $file unless $matched;
    }
    return \%struct;
}

sub render_data( $data ) {
    return join q[],
      map { render_structure( $_, $data->{$_} ) } sort keys %{$data};
}

sub render_style() {
    <<'STYLE';
<style>
  div, span { font-family: monospace; whitespace: pre }
  div.package { font-size: 110%; font-weight: bold }
  span.size { display: inline-block; width: 50px; text-align: right }
  span.dash { display: inline-block; min-width: 10px; text-align: center; padding: 0 4px; color: #999 }
  div.patch { margin-left: 30px; font-size: 80% }
  .patch a { color: #999 }
</style>
STYLE

}

sub render_structure ( $name, $structure ) {
    my $rel_dir = path($name)->relative($root);
    my $out = render_element( 'div', $rel_dir, { class => "package" } );
    for my $archive ( @{ $structure->{tar} || [] } ) {
        my $relpath      = path($archive)->relative($root);
        my $display_path = $relpath->basename;
        $out .= render_element(
            'div',
            [
                render_element(
                    'span',
                    path($archive)->stat->size,
                    { class => 'size' }
                ),
                render_element( 'span', '-', { class => 'dash' } ),
                render_ahref( $display_path, { href => "./$relpath" } ),
            ],
            { class => "file tar" }
        );
    }
    for my $patch ( @{ $structure->{patch} || [] } ) {
        my $relpath      = path($patch)->relative($root);
        my $display_path = $relpath->basename;
        $out .= render_element(
            'div',
            [
                render_element(
                    'span',
                    path($patch)->stat->size,
                    { class => 'size' }
                ),
                render_element( 'span', '-', { class => 'dash' } ),
                render_ahref( $display_path, { href => "./$relpath" } ),
            ],
            { class => "file patch" }
        );
    }

    return $out;
}

sub render_element ( $name, $content, $attributes ) {
    my $attrs = join q[ ], map { sprintf "%s=\"%s\"", $_, $attributes->{$_} }
      sort keys %{$attributes};
    my $pad = "";
    if ( $name eq 'div' ) { $pad = "\n" }
    if ( ref $content eq 'ARRAY' ) { $content = join q[], @{$content} }
    return sprintf "<%s %s>%s</%s>%s", $name, $attrs, $content, $name, $pad;
}

sub render_ahref ( $content, $attributes ) {
    return render_element( 'a', $content, $attributes );
}

