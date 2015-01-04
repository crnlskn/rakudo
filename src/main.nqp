use Perl6::Grammar;
use Perl6::Actions;
use Perl6::Compiler;

# Initialize Rakudo runtime support.
nqp::p6init();

# Create and configure compiler object.
my $comp := Perl6::Compiler.new();
$comp.language('perl6');
$comp.parsegrammar(Perl6::Grammar);
$comp.parseactions(Perl6::Actions);
$comp.addstage('syntaxcheck', :before<ast>);
$comp.addstage('optimize', :after<ast>);
hll-config($comp.config);
nqp::bindhllsym('perl6', '$COMPILER_CONFIG', $comp.config);

# Add extra command line options.
my @clo := $comp.commandline_options();
@clo.push('parsetrace');
@clo.push('setting=s');
@clo.push('n');
@clo.push('p');
@clo.push('doc=s?');
@clo.push('optimize=s?');
@clo.push('c');
@clo.push('I=S');
@clo.push('M=S');

# Bump up recursion limit, for VMs that have one.
$comp.recursion_limit(100000);

# Set up END block list, which we'll run at exit.
nqp::bindhllsym('perl6', '@END_PHASERS', []);

# In an embedding environment, let @*ARGS be empty instead of crashing
nqp::bindhllsym('perl6', '$!ARGITER', 0);

#?if parrot
sub MAIN(@ARGS) {
#?endif
#?if jvm
sub MAIN(*@ARGS) {
#?endif
#?if moar
sub MAIN(@ARGS) {
#?endif
    # Enter the compiler.
    my $result := $comp.command_line(@ARGS, :encoding('utf8'), :transcode('ascii iso-8859-1'));
    if !nqp::isnull($result) && nqp::isconcrete($result) && nqp::can($result, 'sink') {
        $result.sink();
    }

    # Run any END blocks before exiting.
    my @END := nqp::gethllsym('perl6', '@END_PHASERS');
    while +@END {
        $result := (@END.shift)();
        nqp::can($result, 'sink') && $result.sink();
        CATCH { $comp.handle-exception($_); }
        CONTROL { $comp.handle-control($_); }
    }
}
