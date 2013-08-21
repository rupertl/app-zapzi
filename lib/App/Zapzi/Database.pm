package App::Zapzi::Database;
# ABSTRACT: database access for Zapzi

=head1 DESCRIPTION

This class provides access to the Zapzi database.

=cut

use utf8;
use strict;
use warnings;

# VERSION

use Moo;
use SQL::Translator;
use App::Zapzi::Database::Schema;
use App::Zapzi::Config;

=attr app

Link to the App::Zapzi application object.

=cut

has app => (is => 'ro');

=method database_file

The SQLite file where the database is stored.

=cut

sub database_file
{
    my $self = shift;
    if ($self->app->test_database)
    {
        return ':memory:';
    }
    else
    {
        return $self->app->zapzi_dir . "/zapzi.db";
    }
}

=method dsn

The DSN used to connect to the SQLite database.

=cut

sub dsn
{
    my $self = shift;
    return "dbi:SQLite:dbname=" . $self->database_file;
}

our $_schema;

=method schema

The DBIx::Class::Schema object for the application.

=cut

sub schema
{
    my $self = shift;
    $_schema //= App::Zapzi::Database::Schema->connect({
        dsn =>$self->dsn,
        sqlite_unicode => 1,
        on_connect_do => 'PRAGMA foreign_keys = ON'});
    return $_schema;
}

=method init

Initialise the database to a new state.

=cut

sub init
{
    my $self = shift;
    my ($ddl) = @_;

    mkdir $self->app->zapzi_dir;
    die "Can't access ", $self->app->zapzi_dir
        if ! -d $self->app->zapzi_dir;
    mkdir $self->app->zapzi_ebook_dir;

    $self->schema->storage->disconnect if $self->app->force;
    unlink $self->database_file unless $self->app->test_database;
    $_schema = undef;

    # Adjust the page size to match the expected blob size for articles
    # http://www.sqlite.org/intern-v-extern-blob.html
    $self->schema->storage->dbh->do("PRAGMA page_size = 8192");

    if (defined($ddl))
    {
        # Create a special version of the database from the supplied DDL
        # Used for testing upgrades
        my @commands = split(/;\n/, $ddl);
        for (@commands)
        {
            $self->schema->storage->dbh->do($_);
        }

        return;
    }

    $self->schema->deploy();

    my @folders = ({id => 100, name => 'Inbox'},
                   {name => 'Archive'});
    $self->schema->populate('Folder', \@folders);

    my @articles = ({title => 'Welcome to Zapzi', folder => 100,
                     article_text =>
                         { text => '<p>Welcome to Zapzi! Please run <pre>zapzi -h</pre> to see documentation.</p>'}});
    $self->schema->populate('Article', \@articles);

    my @config = ({name => 'schema_version',
                   value => $self->schema->schema_version});
    $self->schema->populate('Config', \@config);
}

=method get_version

Returns the version of the schema defined in the database

=cut

sub get_version
{
    my $self = shift;
    my $schema = $self->schema;

    my $version;

    # If the eval fails, there's no config table, so this must be
    # schema version 0.
    eval { $version = App::Zapzi::Config::get('schema_version') };
    return $@ ? 0 : $version;
}


=method check_version

Compares the version of the schema in the database to that in the
code. Return true if they match, undef if not.

=cut

sub check_version
{
    my $self = shift;

    return $self->get_version == $self->schema->schema_version;
}

=method upgrade

Upgrades the database to the current schema version.

=cut

sub upgrade
{
    my $self = shift;
    my $schema = $self->schema;

    my $from = $self->get_version;
    my $to = $self->schema->schema_version;

    print "Upgrading database from version $from to $to\n";

    if ($from < 1)
    {
        $self->schema->storage->dbh->do("CREATE TABLE config ( " .
                                        "   name text NOT NULL, " .
                                        "   value text NOT NULL DEFAULT '', " .
                                        "   PRIMARY KEY (name) ".
                                        ")");
        App::Zapzi::Config::set('schema_version', 1);
    }

    if ($from < 2)
    {
        $self->schema->storage->dbh->do("ALTER TABLE articles " .
                                        "ADD COLUMN " .
                                        "   source NOT NULL DEFAULT '' ");
        App::Zapzi::Config::set('schema_version', 2);
    }
}

1;
