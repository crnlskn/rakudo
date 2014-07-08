class CompUnitRepo::Local::File does CompUnitRepo::Locally {
    has Hash $!potentials;

    my $precomp := $*VM.precomp-ext;
    my %extensions =
      Perl6 => [$precomp,'pm6','pm'],
      Perl5 => [$precomp,'pm5','pm'],
      NQP   => [$precomp,'nqp'],
      JVM   => [$precomp];
    my $anyextensions = any($precomp,<pm6 pm5 pm nqp>);

    method install($source, $from?) { ... }
    method files($file, :$name, :$auth, :$ver) { ... }

    method candidates($name = /./, :$from = 'Perl6', :$file, :$auth, :$ver) {
        my @extensions := %extensions{$from};

        my @candidates;
        for ( $!potentials //= self.potentials ).keys -> $root {
            next unless $root ~~ $name;             # not right name

            my $candidate := $!potentials{$root};
            for @extensions -> $extension {
                if $candidate{$extension} -> $sig { # use this extension
                    @candidates.push: CompUnit.new(|$sig, :$extension);
                    last;
                }
            }
        }
        @candidates;
    }

    method short-id() { 'file' }

    submethod potentials {
        my Hash $potentials = {};

        for $!path.contents -> $path {
            my $file = ~$path;

            # We loop over one element to be able to 'last' out ot if.
            for $file.rindex(".") -> $i {
                last unless $i.defined;               # could not find any ext

                my $ext = $file.substr($i + 1);
                last unless $ext ~~ $anyextensions;   # not right ext

                my $root = $file.substr(0,$i);
                my $j := $root.rindex(IO::Spec.rootdir);
                $root = $root.substr($j + 1) if $j.defined;

                $potentials{$root}{$ext} := \($file, :name($root) );
            }
        }
        $potentials;
    }
}
