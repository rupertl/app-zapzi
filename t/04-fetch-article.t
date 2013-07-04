#!perl
use Test::Most;
use File::Temp ();

use App::Zapzi;
use App::Zapzi::FetchArticle;

test_can();

my $test_dir = get_test_dir();
my $app = get_test_app($test_dir);

test_get_file();
test_get_url();
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

    return $app;
}

sub test_can
{
    can_ok( 'App::Zapzi::FetchArticle', qw(text source error fetch) );
}

sub test_get_file
{
    my $f = App::Zapzi::FetchArticle->new(source => 't/testfiles/sample.txt');
    isa_ok( $f, 'App::Zapzi::FetchArticle' );

    ok( $f->fetch, 'Fetch sample text file' );
    like( $f->text, qr/sample text file/, 'Contents of text file OK' );

    $f = App::Zapzi::FetchArticle->new(source => 't/testfiles/nosuchfile.txt');
    isa_ok( $f, 'App::Zapzi::FetchArticle' );

    ok( ! $f->fetch, 'Detects file that does not exist' );
    like( $f->error, qr/Failed/, 'Error reported' );
}

sub test_get_url
{
    my $f = App::Zapzi::FetchArticle->new(source => 'http://example.com/');
    isa_ok( $f, 'App::Zapzi::FetchArticle' );

    ok( $f->fetch, 'Fetch sample URL' );
    like( $f->text, qr/Example Domain/, 'Contents of test URL OK' );

    $f = App::Zapzi::FetchArticle->new(source => 
                                       'http://example.iana.org/nonesuch');
    isa_ok( $f, 'App::Zapzi::FetchArticle' );

    ok( ! $f->fetch, 'Detects URL 404' );
    like( $f->error, qr/404/, 'Error reported' );

    $f = App::Zapzi::FetchArticle->new(source => 
                                       'http://no-such-domain-really.com/');
    isa_ok( $f, 'App::Zapzi::FetchArticle' );

    ok( ! $f->fetch, 'Detects host that does not exist' );
    like( $f->error, qr/Failed/, 'Error reported' );
}

