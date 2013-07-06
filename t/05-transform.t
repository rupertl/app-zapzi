#!perl
use Test::Most;

use lib qw(t/lib);
use ZapziTestDatabase;

use App::Zapzi;
use App::Zapzi::FetchArticle;
use App::Zapzi::Transform;

test_can();

my ($test_dir, $app) = ZapziTestDatabase::get_test_app();

test_text();
test_html();
done_testing();

sub test_can
{
    can_ok( 'App::Zapzi::Transform',
            qw(raw_article to_readable readable_text) );
}

sub test_text
{
    my $f = App::Zapzi::FetchArticle->new(source => 't/testfiles/sample.txt');
    ok( $f->fetch, 'Fetch text' );
    my $tx = App::Zapzi::Transform->new(raw_article => $f);
    isa_ok( $tx, 'App::Zapzi::Transform' );
    ok( $tx->to_readable, 'Transform sample text file' );
    like( $tx->readable_text, qr/<p>This is a/, 'Contents of text file OK' );
}

sub test_html
{
    my $f = App::Zapzi::FetchArticle->new(source => 't/testfiles/sample.html');
    ok( $f->fetch, 'Fetch HTML' );
    my $tx = App::Zapzi::Transform->new(raw_article => $f);
    isa_ok( $tx, 'App::Zapzi::Transform' );
    ok( $tx->to_readable, 'Transform sample HTML file' );
    like( $tx->readable_text, qr/<h1>Lorem/, 'Contents of HTML file OK' );
}
