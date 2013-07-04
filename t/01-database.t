#!perl
use Test::Most;
use File::Temp ();
use Test::DBIx::Class::Schema;

BEGIN { use_ok( 'App::Zapzi' ) }
my $test_dir = File::Temp->newdir("zapzi-XXXXX", TMPDIR => 1);

test_can();
test_create();
my $app = test_init($test_dir);
test_schema($app);

done_testing();

sub test_can
{
    can_ok( 'App::Zapzi', qw(init) );
}

sub test_create
{
    my $app = App::Zapzi->new();
    isa_ok( $app, 'App::Zapzi' );
}

sub test_init
{
    my $test_dir = shift;
    my $dir = "$test_dir/zapzi";

    my $app = App::Zapzi->new(zapzi_dir => $dir);
    $app->init;
    ok( ! $app->run, 'init' );

    return $app;
}

sub test_schema
{
    my $app = shift;
    
    my $schema = $app->database->schema;
    isa_ok( $schema, 'App::Zapzi::Database::Schema' );

    # ZapziSchemaTest is a wrapper for Test::DBIx::Class::Schema
    # and is defined at the end of this script.
    subtest 'Article' => sub 
    {
        ZapziSchemaTest->test($schema, 'Article', 
                              [ qw(id title folder created) ],
                              [ qw(folder article_text) ]);
    };
                             
    subtest 'ArticleText' => sub 
    {
        ZapziSchemaTest->test($schema, 'ArticleText', 
                              [ qw(id text) ],
                              [ qw(article) ]);
    };

    subtest 'Folder' => sub 
    {
        ZapziSchemaTest->test($schema, 'Folder', 
                              [ qw(id name) ],
                              [ qw(articles) ]);
    };
}


package ZapziSchemaTest;

sub test
{
    my ($self, $schema, $table, $columns, $relations) = @_;
    
    # Create a new test object
    my $schematest = Test::DBIx::Class::Schema->new(
        {
            schema    => $schema,
            namespace => 'App::Zapzi::Database::Schema',
            moniker   => $table,
            test_missing => 1,
        }
        );

    # Tell it what to test
    $schematest->methods(
        {
            columns => $columns,
            relations => $relations,
            custom => [],
            resultsets => []
        }
        );

    # Run the tests
    $schematest->run_tests();
}

1;
