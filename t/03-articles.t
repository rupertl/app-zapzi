#!perl
use Test::Most;
use Test::Output;

use lib qw(t/lib);
use ZapziTestDatabase;

use App::Zapzi;
use App::Zapzi::Articles qw(get_article get_articles add_article move_article
                            delete_article list_articles);

test_can();

my ($test_dir, $app) = ZapziTestDatabase::get_test_app();

test_get();
test_add();
test_move();
test_delete();
test_list();

done_testing();

sub test_can
{
    can_ok( 'App::Zapzi::Articles', qw(get_article get_articles add_article
                                       move_article delete_article
                                       list_articles) );
}

sub test_get
{
    my $first = get_article(1);
    ok( $first, 'Can read Inbox first article' );
    is( $first->id, 1, 'Inbox first article ID is 1' );
    is( $first->created->delta_days(DateTime->now)->days, 0,
        'Date inflated in articles OK' );

    my $false_article = get_article(0);
    ok( ! $false_article, 'Can detect articles that do not exist' );
}

sub test_add
{
    my $art = add_article(title => 'Foo',
                          folder => 'Inbox',
                          text => 'This is the text for the Foo article');
    my $foo = get_article($art->id);
    ok( $foo, 'Can add articles' );

    my $inbox = get_articles('Inbox');
    is( $inbox->count, 2, 'Two articles in Inbox as expected' );

    eval { add_article(); };
    like( $@, qr/Must provide/, 'Detects missing args to add_article' );

    eval { add_article(title => 'Foo2', folder => 'Does not exist'); };
    like( $@, qr/does not exist/,
          'Detects non-existent folder to add_article' );
}

sub test_move
{
    my $art = add_article(title => 'Baz',
                          folder => 'Inbox',
                          text => 'This is the text for the Baz article');
    my $baz = get_article($art->id);
    ok( move_article($baz->id, 'Archive'), 'Move article' );
    my $baz2 = get_article($art->id);
    is( $baz2->folder->name, 'Archive', 'Can move articles OK');

    eval { move_article(); };
    like( $@, qr/does not exist/, 'Detects missing args to move_article' );
}

sub test_delete
{
    my $art = add_article(title => 'Bar',
                          folder => 'Inbox',
                          text =>
                          'This is the text for the Bar article');
    my $bar = get_article($art->id);
    my $bar_id = $bar->id;
    ok( delete_article($bar_id), 'Can delete articles' );

    my $bar2 = get_article($bar_id);
    ok( ! $bar2, 'Can delete articles OK' );

    ok( delete_article(0), 'Will skip delete for articles that do not exist' );
}

sub test_list
{
    stdout_like( sub { list_articles('Inbox') },
                 qr/Foo/, 'Can list articles' );

    eval { list_articles('No such folder'); };
    like( $@, qr/does not exist/, 'Can detect non-existent folders' );
}
