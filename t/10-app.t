#!perl
use Test::Most;
use File::Temp ();
use Test::Output;

use App::Zapzi;

my $test_dir = get_test_dir();

test_init($test_dir);
test_list();
test_list_folders();
test_make_folder();
test_delete_folder();
test_show();
test_add();
test_delete_article();

done_testing();

sub get_test_dir
{
    return File::Temp->newdir("zapzi-XXXXX", TMPDIR => 1);
}

sub get_test_app
{
    my $dir = "$test_dir/zapzi";
    
    my $app = App::Zapzi->new(zapzi_dir => $dir);
    return $app;
}

sub test_init
{
    my $test_dir = shift;
    my $dir = "$test_dir/zapzi";

    my $app = App::Zapzi->new(zapzi_dir => $dir);
    $app->process_args('init');
    ok( ! $app->run, 'init' );

    $app->process_args('init');
    ok( $app->run, 'init cannot be run twice' );

    $app->process_args('init', '--force');
    ok( ! $app->run, 'init can be re-run with force option' );
}

sub test_list
{
    my $app = get_test_app();

    stdout_like( sub { $app->process_args('list') }, qr/Inbox/, 'list' );
    ok( ! $app->run, 'list run' );

    stdout_like( sub { $app->process_args(qw(list -f Nonesuch)) }, 
                 qr/does not exist/, 'list for non-existent folder' );
    ok( $app->run, 'list error run' );
}

sub test_list_folders
{
    my $app = get_test_app();

    stdout_like( sub { $app->process_args('list-folders') }, qr/Archive\s+0/, 
                 'list-folders' );
    ok( ! $app->run, 'list-folders run' );
}

sub test_make_folder
{
    my $app = get_test_app();

    stdout_like( sub { $app->process_args('make-folder') }, 
                 qr/Need to provide/, 'make-folder with no arg' );
    ok( $app->run, 'make-folder error run' );

    stdout_like( sub { $app->process_args(qw(make-folder Foo)) }, 
                 qr/Created folder/, 'make-folder one arg' );
    ok( ! $app->run, 'make-folder run' );

    stdout_like( sub { $app->process_args(qw(mkf Bar Baz)) }, 
                 qr/Baz/, 'mkf two args' );
    ok( ! $app->run, 'make-folder run' );

    stdout_like( sub { $app->process_args(qw(make-folder Inbox)) }, 
                 qr/already exists/, 'make-folder for existing folder' );
    ok( ! $app->run, 'make-folder run' );
}

sub test_delete_folder
{
    my $app = get_test_app();

    stdout_like( sub { $app->process_args('delete-folder') }, 
                 qr/Need to provide/, 'delete-folder with no arg' );
    ok( $app->run, 'delete-folder error run' );

    stdout_like( sub { $app->process_args(qw(delete-folder Foo)) }, 
                 qr/Deleted folder/, 'delete-folder one arg' );
    ok( ! $app->run, 'delete-folder run' );

    stdout_like( sub { $app->process_args(qw(rmf Bar Baz)) }, 
                 qr/Baz/, 'rmf two args' );
    ok( ! $app->run, 'delete-folder run' );

    stdout_like( sub { $app->process_args(qw(delete-folder Inbox)) }, 
                 qr/by the system/, 'delete-folder for system folder' );
    ok( ! $app->run, 'make-folder run' );

    stdout_like( sub { $app->process_args(qw(delete-folder Nonesuch)) }, 
                 qr/does not exist/, 'delete-folder for non-existent folder' );
    ok( ! $app->run, 'make-folder run' );
}

sub test_show
{
    my $app = get_test_app();

    stdout_like( sub { $app->process_args(qw(show 1)) }, qr/Welcome to/, 
                 'show' );
    ok( ! $app->run, 'show run' );

    stdout_like( sub { $app->process_args(qw(show 0)) }, qr/Could not/, 
                 'show error' );
    ok( $app->run, 'make-folder run' );
}

sub test_add
{
    my $app = get_test_app();

    stdout_like( sub { $app->process_args(qw(add t/testfiles/sample.txt)) }, 
                 qr/Added article/, 
                 'add' );
    ok( ! $app->run, 'add run' );

    stdout_like( sub { $app->process_args(qw(add t/testfiles/nonesuch.txt)) }, 
                 qr/Could not/, 
                 'add error' );
    ok( $app->run, 'add run' );
}

sub test_delete_article
{
    my $app = get_test_app();

    stdout_like( sub { $app->process_args(qw(rm 2)) }, 
                 qr/Deleted article/, 
                 'delete article' );
    ok( ! $app->run, 'rm run' );

    stdout_like( sub { $app->process_args(qw(rm 0)) }, 
                 qr/Could not/, 
                 'delete article error' );
    ok( $app->run, 'rm run' );
}

