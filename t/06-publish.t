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
test_pagebreak();
test_encoding();
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

sub test_pagebreak
{
    # Test for pagebreaks after last article
    stdout_like( sub { $app->process_args(qw(add t/testfiles/sample.txt)) },
                 qr/Added article/,
                 'add sample text' );

    my $pub = App::Zapzi::Publish->new(folder => 'Inbox',
                                       archive_folder => undef);
    $pub->publish();
    unlike( $pub->collection_data, qr/<mbp:pagebreak/,
          'No pagebreak in single article collection' );

    stdout_like( sub { $app->process_args(qw(add t/testfiles/sample.txt)) },
                 qr/Added article/,
                 'add second sample text' );
    $pub = App::Zapzi::Publish->new(folder => 'Inbox',
                                    archive_folder => undef);
    $pub->publish();
    like( $pub->collection_data, qr/<mbp:pagebreak/,
          'Single pagebreak in two article collection' );
}

sub test_encoding
{
    # Test UTF-8
    stdout_like( sub { $app->process_args(qw(add t/testfiles/html-utf8.html)) },
                 qr/Added article/,
                 'add utf8 html' );

    my $pub = App::Zapzi::Publish->new(folder => 'Inbox',
                                       encoding => 'UTF-8',
                                       archive_folder => undef);
    $pub->publish();
    like( $pub->collection_data,
          qr/This is a test of 雜誌 encoding. Viele Grüße!/,
          'Encoded as UTF8 OK' );

    # Test ISO-8859-1
    $pub = App::Zapzi::Publish->new(folder => 'Inbox',
                                    encoding => 'ISO-8859-1',
                                    archive_folder => undef);
    $pub->publish();
    like( $pub->collection_data,
          qr/This is a test of &#x96DC;&#x8A8C; encoding/,
          'Encoded UTF-8 high chars as HTML entities in ISO-8859-1 OK' );
    like( $pub->collection_data,
          qr/Viele Gr\x{FC}\x{DF}e!/,
          'Encoded as ISO-8859-1 OK' );
}
