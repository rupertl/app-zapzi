#!perl
use Test::Most;
use File::Temp ();
use Test::Output;

use App::Zapzi;
use App::Zapzi::Publish;

test_can();

my $test_dir = get_test_dir();
my $app = get_test_app($test_dir);

test_publish();
done_testing();

sub get_test_dir
{
    return File::Temp->newdir("zapzi-XXXXX", TMPDIR => 1);
}

sub get_test_app
{
    my $test_dir = shift;
    my $dir = "$test_dir/zapzi";
    
    my $app = App::Zapzi->new(zapzi_dir => $dir);
    $app->init();

    # Set up some sample documents via the app interface
    stdout_like( sub { $app->process_args(qw(add t/testfiles/sample.txt)) }, 
                 qr/Added article/, 
                 'add' );
    ok( ! $app->run, 'add run' );

    stdout_like( sub { $app->process_args(qw(add t/testfiles/sample.html)) }, 
                 qr/Added article/, 
                 'add html' );
    ok( ! $app->run, 'add html run' );

    return $app;
}

sub test_can
{
    can_ok( 'App::Zapzi::Publish', qw(filename publish) );
}

sub test_publish
{
    my $pub = App::Zapzi::Publish->new(folder => 'Inbox');
    
    ok( $pub->publish(), 'publish' );
    ok( -s $pub->filename, 'file created' );
}
