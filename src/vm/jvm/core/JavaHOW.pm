my class Metamodel::JavaHOW
    does Metamodel::Naming
    does Metamodel::Stashing
    does Metamodel::TypePretense
    does Metamodel::AttributeContainer
{
    has %!methods;
    has %!cache;

    my $archetypes := Perl6::Metamodel::Archetypes.new( );
    method archetypes() {
        $archetypes
    }
    
    method is_composed($obj) {
        1
    }

    method methods($obj) {
        .say for %!methods;
        say %!methods.^name;
        my @methods;
        for %!methods -> (:key($methname), :value($coderef)) {
            @methods.push: $coderef;
        }
        @methods;
    }

    method find_method($obj, $name) {
        for %!methods -> (:key($methname), :value($coderef)) {
            if $methname eq $name {
                return $coderef;
            }
            say "$methname isn't $name";
        }
        Nil
    }

    # Add a method.
    method add_method($obj, $name, $code_obj) {
        # We may get VM-level subs in here during BOOTSTRAP; the try is to cope
        # with them.
        my $method_type := "Method";
        try { $method_type := $code_obj.HOW.name($code_obj) };

        # Ensure we haven't already got it.
        if nqp::existskey(%!methods, $name) {
            nqp::die("Package '"
              ~ self.name($obj)
              ~ "' already has a "
              ~ $method_type
              ~ " '"
              ~ $name
              ~ "' (did you mean to declare a multi-method?)");
        }

        %!methods{$name} := $code_obj;

        # Adding a method means any cache is no longer authoritative.
        nqp::setmethcacheauth($obj, 0);
        %!cache := {};
    }

}

nqp::p6setjavahow(Metamodel::JavaHOW);

Metamodel::JavaHOW.pretend_to_be(nqp::list(Any, Mu));
