package App::Zapzi::Database;
# VERSION
# ABSTRACT: database access for Zapzi

=head1 DESCRIPTION

This class provides access to the Zapzi database.

=cut

use utf8;
use strict;
use warnings;

use Moo;
use SQL::Translator;
use App::Zapzi::Database::Schema;

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
    return $self->app->zapzi_dir . "/zapzi.db";
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
    mkdir $self->app->zapzi_dir;
    die "Can't access ", $self->app->zapzi_dir 
        if ! -d $self->app->zapzi_dir;
    mkdir $self->app->zapzi_ebook_dir;

    $self->schema->storage->disconnect if $self->app->force;
    unlink $self->database_file;

    # Adjust the page size to match the expected blob size for articles
    # http://www.sqlite.org/intern-v-extern-blob.html
    $self->schema->storage->dbh->do("PRAGMA page_size = 8192");

    $self->schema->deploy();

    my @folders = ({id => 100, name => 'Inbox'},
                   {name => 'Archive'});
    $self->schema->populate('Folder', \@folders);

    my @articles = ({title => 'Welcome to Zapzi', folder => 100,
                     article_text => 
                         { text => '<p>Welcome to Zapzi! Please run <pre>zapzi -h</pre> to see documentation.</p>'}});
    $self->schema->populate('Article', \@articles);
}

1;
