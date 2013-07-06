#!perl
use Test::Most;
use Test::DBIx::Class::Schema;

use lib qw(t/lib);
use ZapziTestDatabase;
use ZapziTestSchema;
use App::Zapzi;

my ($test_dir, $app) = ZapziTestDatabase::get_test_app();

test_schema($app);

done_testing();

sub test_schema
{
    my $app = shift;

    my $schema = $app->database->schema;
    isa_ok( $schema, 'App::Zapzi::Database::Schema' );

    # ZapziSchemaTest is a wrapper for Test::DBIx::Class::Schema
    subtest 'Article' => sub
    {
        ZapziTestSchema->test($schema, 'Article',
                              [ qw(id title folder created) ],
                              [ qw(folder article_text) ]);
    };

    subtest 'ArticleText' => sub
    {
        ZapziTestSchema->test($schema, 'ArticleText',
                              [ qw(id text) ],
                              [ qw(article) ]);
    };

    subtest 'Folder' => sub
    {
        ZapziTestSchema->test($schema, 'Folder',
                              [ qw(id name) ],
                              [ qw(articles) ]);
    };
}
