#!perl
use Test::Most;

use lib qw(t/lib);
use ZapziTestDatabase;

use App::Zapzi;
use App::Zapzi::Config;

test_can();

my ($test_dir, $app) = ZapziTestDatabase::get_test_app();

test_get();
test_set();
test_get_keys();
test_delete();
test_get_doc();
test_validate();

done_testing();

sub test_can
{
    can_ok( 'App::Zapzi::Config',
            qw(get set get_keys delete get_doc validate) );
}

sub test_get
{
    ok( App::Zapzi::Config::get('schema_version'),
        'Can read a defined config value' );

    is( App::Zapzi::Config::get('no_such_key'), undef,
        'An non-existent config key gives undef as value' );

    eval { App::Zapzi::Config::get() };
    like( $@, qr/Key not provided/, 'Key has to be provided to get' );

    eval { App::Zapzi::Config::get('') };
    like( $@, qr/Key not provided/, 'Non-empty key has to be provided to get' );
}

sub test_set
{
    ok( App::Zapzi::Config::set('foo', 'bar'), 'Can set a new key' );
    is( App::Zapzi::Config::get('foo'), 'bar',
        'Can get a config value after setting it' );

    ok( App::Zapzi::Config::set('foo', 'baz'), 'Can update a key' );
    is( App::Zapzi::Config::get('foo'), 'baz',
        'Can get a config value after updating it' );

    ok( App::Zapzi::Config::set('xyz', ''), 'Can set a value to blank' );
    is( App::Zapzi::Config::get('xyz'), '',
        'Can get a blank config value' );

    eval { App::Zapzi::Config::set() };
    like( $@, qr/need to be provided/, 'Key has to be provided to set' );

    eval { App::Zapzi::Config::set('abc') };
    like( $@, qr/need to be provided/, 'Value has to be provided to set' );
}

sub test_get_keys
{
    my @keys = App::Zapzi::Config::get_keys();
    ok( scalar(@keys) >= 3, 'get_keys returns a list of keys' );
    ok( grep(/foo/, @keys), 'Can find a key we set' );
}

sub test_delete
{
    ok( App::Zapzi::Config::set('option_x', 'abc'), 'Can set a key' );

    is( App::Zapzi::Config::get('option_x'), 'abc',
        'Can get a config value after setting it' );

    ok( App::Zapzi::Config::delete('option_x'),
        'Can delete a defined config value' );

    is( App::Zapzi::Config::get('option_x'), undef,
        'Key is really deleted after delete' );

    eval { App::Zapzi::Config::delete() };
    like( $@, qr/Key not provided/, 'Key has to be provided to delete' );
}

sub test_get_doc
{
    like( App::Zapzi::Config::get_doc('schema_version'),
          qr/# Version of database schema to use/,
          'Got documentation for a user config variable' );

    is( App::Zapzi::Config::get_doc('nosuch'), undef,
        'Non-user config variables have no documentation' );

    eval { App::Zapzi::Config::get_doc() };
    like( $@, qr/Key not provided/, 'Key has to be provided to get_doc' );
}

sub test_validate
{
    ok( App::Zapzi::Config::validate('publish_format', 'MOBI'),
        'Can set publish_format to a valid value' );

    ok( App::Zapzi::Config::validate('publish_encoding', 'UTF-8'),
        'Can set publish_encoding to a valid value' );

    is( App::Zapzi::Config::validate('publish_format', 'mobi'), 'MOBI',
        'Validate canonicalises inputs' );

    is( App::Zapzi::Config::validate('publish_format', 'invalid'), undef,
        'Cannot set publish_format to an invalid value' );

    is( App::Zapzi::Config::validate('nonesuch', 'abc'), undef,
        'Undefined keys lead to undef output' );

    eval { App::Zapzi::Config::validate() };
    like( $@, qr/need to be provided/, 'Key has to be provided to validate' );

    eval { App::Zapzi::Config::validate('abc') };
    like( $@, qr/need to be provided/, 'Value has to be provided to validate' );
}
