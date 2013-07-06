#!perl
use Test::Most;
use Test::Output;

use lib qw(t/lib);
use ZapziTestDatabase;

use App::Zapzi;
use App::Zapzi::Publish;

test_can();

my ($test_dir, $app) = ZapziTestDatabase::get_test_app();

test_publish();
done_testing();

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
