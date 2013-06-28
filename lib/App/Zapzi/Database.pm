use utf8;
use strict;
use warnings;

package App::Zapzi::Database;
# VERSION
# ABSTRACT: database access for zapzi

use Moo;
use SQL::Translator;
use App::Zapzi::Database::Schema;

has app => (is => 'ro');

sub database_file
{
    my $self = shift;
    return $self->app->zapzi_dir . "/zapzi.db";
}

sub dsn
{
    my $self = shift;
    return "dbi:SQLite:dbname=" . $self->database_file;
}

our $_schema;

sub schema
{
    my $self = shift;
    $_schema //= App::Zapzi::Database::Schema->connect({
        dsn =>$self->dsn, 
        on_connect_do => 'PRAGMA foreign_keys = ON'});
    return $_schema;
}

sub init
{
    my $self = shift;
    mkdir $self->app->zapzi_dir;
    die "Can't access ", $self->app->zapzi_dir 
        if ! -d $self->app->zapzi_dir;

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
                         { text => '<h1>Welcome to Zapzi!</h1>'}});
    $self->schema->populate('Article', \@articles);
}


1;
