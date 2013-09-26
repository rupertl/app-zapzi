#!perl
use Test::Most;
use Test::Output;

use lib qw(t/lib);
use ZapziTestDatabase;

use App::Zapzi;
use File::Slurp;

test_init();

my ($test_dir, $app) = ZapziTestDatabase::get_test_app();

test_config();
test_list();
test_list_folders();
test_make_folder();
test_delete_folder();
test_export();
test_add();
test_delete_article();
test_publish();
test_publish_archive();
test_help_version();

done_testing();

sub get_test_app
{
    my $dir = $app->zapzi_dir;

    my $clean_app = App::Zapzi->new(zapzi_dir => $dir, test_database => 1);
    return $clean_app;
}

sub test_init
{
    ZapziTestDatabase::test_init();
}

sub test_config
{
    my $app = get_test_app();

    # get all
    stdout_like( sub { $app->process_args(qw(config get)) },
                 qr/# Format to publish.*publish_format = /s,
                 'config get' );
    ok( ! $app->run, 'config get run' );

    # get single
    $app = get_test_app();
    stdout_like( sub { $app->process_args(qw(config get publish_format)) },
                 qr/MOBI/,
                 'config get single' );
    ok( ! $app->run, 'config get single run' );

    # get nonesuch
    stdout_like( sub { $app->process_args(qw(config get nonesuch)) },
                 qr/Config variable 'nonesuch' does not exist/,
                 'config get nonesuch' );
    ok( $app->run, 'config get nonesuch run' );

    # set valid
    $app = get_test_app();
    stdout_like( sub { $app->process_args(qw(config set publish_format epub)) },
                 qr/Set 'publish_format' = 'EPUB'/,
                 'config set valid' );
    ok( ! $app->run, 'config set valid run' );

    # set invalid
    $app = get_test_app();
    stdout_like( sub { $app->process_args(qw(config set publish_format XXX)) },
                 qr/Invalid/,
                 'config set invalid' );
    ok( $app->run, 'config set invalid run' );

    # set nonesuch
    $app = get_test_app();
    stdout_like( sub { $app->process_args(qw(config set nonesuch xxx)) },
                 qr/Invalid/,
                 'config set nonesuch' );
    ok( $app->run, 'config set nonesuch run' );

    # set wrong number of args
    $app = get_test_app();
    stdout_like( sub { $app->process_args(qw(config set)) },
                 qr/Invalid config set command/,
                 'config set wrong number of args 0' );
    ok( $app->run, 'config set wrong number of args 0 run' );
    $app = get_test_app();
    stdout_like( sub { $app->process_args(qw(config set publish_format)) },
                 qr/Invalid config set command/,
                 'config set wrong number of args 1' );
    ok( $app->run, 'config set wrong number of args 1 run' );

    # get previously set
    $app = get_test_app();
    stdout_like( sub { $app->process_args(qw(config get publish_format)) },
                 qr/EPUB/,
                 'config get previously set' );
    ok( ! $app->run, 'config previously set run' );

    # set valid change
    $app = get_test_app();
    stdout_like( sub { $app->process_args(qw(config set publish_format mobi)) },
                 qr/Set 'publish_format' = 'MOBI'/,
                 'config set valid change' );
    ok( ! $app->run, 'config set valid change run' );

    # get previously changed
    $app = get_test_app();
    stdout_like( sub { $app->process_args(qw(config get publish_format)) },
                 qr/MOBI/,
                 'config get previously changed' );
    ok( ! $app->run, 'config previously changed run' );
}

sub test_list
{
    my $app = get_test_app();

    stdout_like( sub { $app->process_args('list') }, qr/Inbox/, 'list' );
    ok( ! $app->run, 'list run' );

    $app = get_test_app();
    stdout_like( sub { $app->process_args(qw(ls -l)) },
                 qr/Folder:\s+Inbox/, 'ls -l' );
    ok( ! $app->run, 'ls -l run' );

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
    ok( ! $app->run, 'mkf run' );

    stdout_like( sub { $app->process_args(qw(md Qux)) },
                 qr/Qux/, 'md' );
    ok( ! $app->run, 'md run' );

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
    ok( ! $app->run, 'rmf run' );

    stdout_like( sub { $app->process_args(qw(rd Qux)) },
                 qr/Qux/, 'rd' );
    ok( ! $app->run, 'rd run' );

    stdout_like( sub { $app->process_args(qw(delete-folder Inbox)) },
                 qr/by the system/, 'delete-folder for system folder' );
    ok( ! $app->run, 'delete-folder run' );

    stdout_like( sub { $app->process_args(qw(delete-folder Nonesuch)) },
                 qr/does not exist/, 'delete-folder for non-existent folder' );
    ok( ! $app->run, 'make-folder run' );
}

sub test_export
{
    my $app = get_test_app();

    stdout_like( sub { $app->process_args(qw(export 1)) },
                 qr/<html>.*Welcome to/s,
                 'show' );
    ok( ! $app->run, 'show run' );

    stdout_like( sub { $app->process_args(qw(cat 1)) }, qr/Welcome to/,
                 'cat' );
    ok( ! $app->run, 'cat run' );

    stdout_like( sub { $app->process_args(qw(cat)) }, qr/Need to provide/,
                 'show missing article' );
    ok( $app->run, 'show error run' );

    stdout_like( sub { $app->process_args(qw(cat 0)) }, qr/Could not/,
                 'show error' );
    ok( $app->run, 'show error run' );
}

sub test_add
{
    my $app = get_test_app();

    stdout_like( sub { $app->process_args(qw(add t/testfiles/sample.txt)) },
                 qr/Added article/,
                 'add' );
    ok( ! $app->run, 'add run' );

    stdout_like( sub { $app->process_args(qw(add t/testfiles/sample.html)) },
                 qr/Added article/,
                 'add html' );
    ok( ! $app->run, 'add html run' );

    stdout_like( sub { $app->process_args(
                          qw(add --transformer HTML t/testfiles/sample.html)) },
                 qr/Added article/,
                 'add html with transformer' );
    ok( ! $app->run, 'add html with transformer run' );

    stdout_like( sub { $app->process_args(
                          qw(add File::Basename)) },
                 qr/Added article/,
                 'add POD' );
    ok( ! $app->run, 'add POD with transformer run' );

    # Try adding an article and immediately exporting it
    stdout_like( sub { $app->process_args(
                           qw(add --cat t/testfiles/sample.txt)) },
                 qr/This is a sample text file/,
                 'add+cat' );
    ok( ! $app->run, 'add+cat run' );

    $app = get_test_app();
    stdout_like( sub { $app->process_args(qw(add)) },
                 qr/Need to provide/,
                 'add missing article' );
    ok( $app->run, 'add run' );

    stdout_like( sub { $app->process_args(qw(add t/testfiles/nonesuch.txt)) },
                 qr/Could not get/,
                 'get error' );
    ok( $app->run, 'add run' );

    $app = get_test_app();
    stdout_like( sub { $app->process_args(
                           qw(add -t Nonesuch t/testfiles/sample.txt)) },
                 qr/Could not transform/,
                 'transform error' );
    ok( $app->run, 'add run' );
}

sub test_delete_article
{
    my $app = get_test_app();

    stdout_like( sub { $app->process_args(qw(rm 2)) },
                 qr/Deleted article/,
                 'delete article' );
    ok( ! $app->run, 'rm run' );

    stdout_like( sub { $app->process_args(qw(delete)) },
                 qr/Need to provide/,
                 'delete article missing ID' );
    ok( $app->run, 'rm run' );

    stdout_like( sub { $app->process_args(qw(rm 0)) },
                 qr/Could not/,
                 'delete article error' );
    ok( $app->run, 'rm run' );
}

sub test_publish
{
    my $app = get_test_app();

    stdout_like( sub { $app->process_args(qw(publish)) },
                 qr/5 articles.*Published.*\.mobi$/s,
                 'publish' );
    ok( ! $app->run, 'publish run' );

    stdout_like( sub { $app->process_args(qw(pub)) },
                 qr/No articles/,
                 'pub archives OK and rerun gives 0 articles' );
    ok( $app->run, 'pub again run' );

    $app = get_test_app();
    $app->process_args(qw(add t/testfiles/sample.txt));
    stdout_like( sub { $app->process_args(qw(publish --format HTML)) },
                 qr/Published .*\.html$/,
                 'publish as different format' );
    ok( ! $app->run, 'pub format run' );

    $app = get_test_app();
    $app->process_args(qw(add t/testfiles/sample.txt));
    $app->process_args(qw(config set publish_format epub));
    $app = get_test_app();
    stdout_like( sub { $app->process_args(qw(publish)) },
                 qr/Published .*\.epub$/,
                 'publish as different format by config' );
    ok( ! $app->run, 'pub format by config run' );

    $app = get_test_app();
    $app->process_args(qw(add t/testfiles/sample.txt));
    stdout_like( sub { $app->process_args(qw(publish --encoding UTF-8)) },
                 qr/Published /,
                 'publish in different encoding' );
    ok( ! $app->run, 'pub encoding run' );

    $app = get_test_app();
    $app->process_args(qw(add t/testfiles/sample.txt));
    $app->process_args(qw(config set publish_encoding ISO-8859-1));
    $app->process_args(qw(config set publish_format HTML));
    $app = get_test_app();
    my $stdout = Test::Output::stdout_from(sub
                                           { $app->process_args(qw(publish)) });
    like( $stdout,
          qr/Published .*\.html$/,
          'publish as different encoding by config' );
    if ($stdout =~ /Published (.+)$/)
    {
        my $published_file = $1;
        my $contents = read_file($published_file);
        like( $contents, qr/<meta charset="ISO-8859-1">/,
              'Contents encoded correctly for ISO-8859-1' );
    }
    else
    {
        fail('Could not read published file');
    }
    ok( ! $app->run, 'pub encoding by config run' );

    $app->process_args(qw(add t/testfiles/sample.txt));

    $app = get_test_app();
    stdout_like( sub { $app->process_args(qw(publish -f Nonesuch)) },
                 qr/does not exist/,
                 'publish error' );
    ok( $app->run, 'publish error run' );

    $app = get_test_app();
    stdout_like( sub { $app->process_args(qw(publish --format XXXX)) },
                 qr/Failed to publish/,
                 'publish format error' );
    ok( $app->run, 'publish format error run' );

    $app = get_test_app();
    stdout_like( sub { $app->process_args(qw(publish --encoding XXXX)) },
                 qr/Failed to publish/,
                 'publish encoding error' );
    ok( $app->run, 'publish encoding error run' );
}

sub test_publish_archive
{
    my $app = get_test_app();

    $app->process_args(qw(mkf frob));
    $app->process_args(qw(add -f frob t/testfiles/sample.txt));
    $app->process_args(qw(add -f frob t/testfiles/sample.html));
    stdout_like( sub { $app->process_args('lsf') }, qr/frob\s+2/,
                 'added 2 docs to new folder' );

    $app = get_test_app();
    stdout_like( sub { $app->process_args(qw(pub -f frob --noarchive)) },
                 qr/2 articles.*Published/s,
                 'pub' );
    ok( ! $app->run, 'pub run' );

    stdout_like( sub { $app->process_args('lsf') }, qr/frob\s+2/,
                 'Articles not archived with --noarchive' );
}

sub test_help_version
{
    my $app = get_test_app();

    stdout_like( sub { $app->process_args(qw(help)) },
                 qr/Shows this help text/s,
                 'help' );

    stdout_like( sub { $app->process_args(qw(version)) },
                 qr/App::Zapzi .* and Perl/s,
                 'version' );

    $app = get_test_app();
    stdout_like( sub { $app->process_args(qw(unknown_command)) },
                 qr/Shows this help text/s,
                 'unknown command shows help' );
}
