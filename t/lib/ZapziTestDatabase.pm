#!perl
package ZapziTestDatabase;

use Test::Most;
use File::Temp ();
use App::Zapzi;

sub get_test_app
{
    # Get a temporary database in a temp directory

    my $test_dir = _get_test_dir();
    my $dir = "$test_dir/zapzi";

    my $app = App::Zapzi->new(zapzi_dir => $dir);
    $app->init();
    ok( ! $app->run, 'Created test Zapzi instance' );

    return ($test_dir, $app);
}

sub test_init
{
    my ($test_dir, $app) = @_;
    my $dir = "$test_dir/zapzi";

    $app->process_args('init');
    ok( $app->run, 'init cannot be run twice' );

    $app->process_args('init', '--force');
    ok( ! $app->run, 'init can be re-run with force option' );
}

sub _get_test_dir
{
    return File::Temp->newdir("zapzi-XXXXX", TMPDIR => 1);
}

1;
