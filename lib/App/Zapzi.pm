package App::Zapzi;
# ABSTRACT: store articles and publish them to read later

use utf8;
use strict;
use warnings;

# VERSION

binmode(STDOUT, ":encoding(UTF-8)");

use Getopt::Lucid 1.05 qw( :all );
use File::HomeDir;
use App::Zapzi::Database;
use App::Zapzi::Folders;
use App::Zapzi::Articles;
use App::Zapzi::FetchArticle;
use App::Zapzi::Transform;
use App::Zapzi::Publish;
use Moo 1.003000;
use Carp;

=head1 DESCRIPTION

This class implements the application functions for Zapzi. See the
page for the L<zapzi> command for details on how to run it.

=attr run

The current state of the application, -1 means nothing has been done,
0 OK, otherwise an error code. Used for exit code when the process
terminates.

=cut

has run => (is => 'rw', default => -1);

=attr force

Option to force processing of the init command. Default is unset.

=cut

has force => (is => 'rw', default => 0);

=attr noarchive

Option to not archive articles on publication

=cut

has noarchive => (is => 'rw', default => 0);

=attr folder

Folder to work on. Default is 'Inbox'

=cut

has folder => (is => 'rw', default => 'Inbox');

=attr transformer

Transformer to extract text from the article. Default is '', which
means Zapzi will automatically the best option based on the content
type of the text.

=cut

has transformer => (is => 'rw', default => '');

=method get_app
=method BUILD

At construction time, a copy of the application object is stored and
can be retrieved later via C<get_app>.

=cut

our $_the_app;
sub BUILD { $_the_app = shift; }
sub get_app
{
    croak 'Must create an instance of App::Zapzi first' unless $_the_app;
    return $_the_app;
}

=attr zapzi_dir

The folder where Zapzi files are stored.

=cut

has zapzi_dir =>
(
    is => 'ro',
    default => sub
    {
        return $ENV{ZAPZI_DIR} // File::HomeDir->my_home . "/.zapzi";
    }
);

=attr zapzi_ebook_dir

The folder where Zapzi published eBook files are stored.

=cut

has zapzi_ebook_dir =>
(
    is => 'ro',
    default => sub
    {
        my $self = shift;
        return $self->zapzi_dir . '/ebooks';
    }
);

=attr database

The instance of App:Zapzi::Database used by the application.

=cut

has database =>
(
    is => 'ro',
    default => sub
    {
        my $self = shift;
        return App::Zapzi::Database->new(app => $self);
    }
);

=attr test_database

If set, use an in-memory database. Used to speed up testing only.

=cut

has test_database =>
(
    is => 'ro',
    default => 0
);

=method process_args(@args)

Read the arguments C<@args> (normally you'd pass in C<@ARGV> and
process them according to the command line specification for the
application.

=cut

sub process_args
{
    my $self = shift;
    my @args = @_;

    my @specs =
    (
        Switch("help|h"),
        Switch("version|v"),
        Switch("init"),
        Switch("add"),
        Switch("list|ls"),
        Switch("list-folders|lsf"),
        Switch("make-folder|mkf|md"),
        Switch("delete-folder|rmf|rd"),
        Switch("delete-article|delete|rm"),
        Switch("show|cat"),
        Switch("publish|pub"),

        Param("folder|f"),
        Param("transformer|t"),
        Switch("force"),
        Switch("noarchive"),
    );

    my $options = Getopt::Lucid->getopt(\@specs, \@args)->validate;

    $self->force($options->get_force);
    $self->noarchive($options->get_noarchive);
    $self->folder($options->get_folder // $self->folder);
    $self->transformer($options->get_transformer // $self->transformer);

    $self->help if $options->get_help;
    $self->version if $options->get_version;
    $self->init if $options->get_init;

    # For any further operations we need a database
    if (! -r $self->database->database_file && ! $self->test_database)
    {
        print "Zapzi database does not exist; did you run 'zapzi init'?\n";
        $self->run(1);
        return;
    }

    # Upgrade the DB, if needed
    $self->database->upgrade
        unless $self->database->check_version || $self->run == 0;

    unless ($options->get_make_folder)
    {
        if (! $self->validate_folder($self->folder))
        {
            $self->run(1);
            return;
        }
    }

    $self->list if $options->get_list;
    $self->list_folders if $options->get_list_folders;
    $self->make_folder(@args) if $options->get_make_folder;
    $self->delete_folder(@args) if $options->get_delete_folder;
    $self->delete_article(@args) if $options->get_delete_article;
    $self->add(@args) if $options->get_add;
    $self->show(@args) if $options->get_show;
    $self->publish if $options->get_publish;

    # Fallthrough if no valid commands given
    $self->help if $self->run == -1;
}

=method init

Creates the database. Will only do so if the database does not exist
already or if the L<force> attribute is set.

=cut

sub init
{
    my $self = shift;
    my $dir = $self->zapzi_dir;

    if (! $dir || $dir eq '')
    {
        print "Zapzi directory not supplied\n";
        $self->run(1);
    }
    elsif (-d $dir && ! $self->force)
    {
        print "Zapzi directory $dir already exists\n";
        print "To force recreation, run with the --force option\n";
        $self->run(1);
    }
    else
    {
        $self->database->init;
        print "Created Zapzi directory $dir\n";
        $self->run(0);
    }
}

=method validate_folder

Determines if the folder specified exists.

=cut

sub validate_folder
{
    my $self = shift;

    if (! App::Zapzi::Articles::get_folder($self->folder))
    {
        printf("Folder '%s' does not exist\n", $self->folder);
        $self->run(1);
        return;
    }
    else
    {
        return 1;
    }
}

=method list

Lists out the articles in L<folder>.

=cut

sub list
{
    my $self = shift;
    my $summary = App::Zapzi::Articles::articles_summary($self->folder);
    foreach (@$summary)
    {
        my $article = $_;
        printf("%s %4d %s %-45s\n", $self->folder,
               $article->{id}, $article->{created}->strftime('%d-%b-%Y'),
               $article->{title});
    }
    $self->run(0);
}

=method list_folders

List folder names and article counts.

=cut

sub list_folders
{
    my $self = shift;
    my $summary = App::Zapzi::Folders::folders_summary();
    foreach (sort keys %$summary)
    {
        printf("%-10s %3d\n", $_, $summary->{$_});
    }

    $self->run(0);
}

=method make_folder

Create one or more new folders. Will ignore any folders that already
exist.

=cut

sub make_folder
{
    my $self = shift;
    my @args = @_;

    if (! @args)
    {
        print "Need to provide folder names to create\n";
        $self->run(1);
        return;
    }

    $self->run(0);
    for (@args)
    {
        my $folder = $_;
        if (App::Zapzi::Folders::get_folder($folder))
        {
            print "Folder '$folder' already exists\n";
        }
        else
        {
            App::Zapzi::Folders::add_folder($folder);
            print "Created folder '$folder'\n";
        }
    }
}

=method delete_folder

Remove one or more new folders. Will not allow removal of system
folders ie Inbox and Archive, but will ignore removal of folders that
do not exist.

=cut

sub delete_folder
{
    my $self = shift;
    my @args = @_;

    if (! @args)
    {
        print "Need to provide folder names to delete\n";
        $self->run(1);
        return;
    }

    $self->run(0);
    for (@args)
    {
        my $folder = $_;
        if (App::Zapzi::Folders::is_system_folder($folder))
        {
            print "Can't remove '$folder' as it is needed by the system\n";
        }
        elsif (! App::Zapzi::Folders::get_folder($folder))
        {
            print "Folder '$folder' does not exist\n";
        }
        else
        {
            App::Zapzi::Folders::delete_folder($folder);
            print "Deleted folder '$folder'\n";
        }
    }
}

=method delete_article

Remove an article from the database

=cut

sub delete_article
{
    my $self = shift;
    my @args = @_;

    if (! @args)
    {
        print "Need to provide article IDs\n";
        $self->run(1);
        return;
    }

    $self->run(0);
    for (@args)
    {
        my $id = $_;
        my $art_rs = App::Zapzi::Articles::get_article($id);
        if ($art_rs)
        {
            if (App::Zapzi::Articles::delete_article($id))
            {
                print "Deleted article $id\n";
            }
            else
            {
                print "Could not delete article $id\n";
            }
        }
        else
        {
            print "Could not get article $id\n";
            $self->run(1);
        }
    }
}

=method add

Add an article to the database for later publication.

=cut

sub add
{
    my $self = shift;
    my @args = @_;

    if (! @args)
    {
        print "Need to provide articles names to add\n";
        $self->run(1);
        return;
    }

    $self->run(0);
    for (@args)
    {
        my $source = $_;
        print "Working on $source\n";
        my $f = App::Zapzi::FetchArticle->new(source => $source);
        if (! $f->fetch)
        {
            print "Could not get article: ", $f->error, "\n\n";
            $self->run(1);
            next;
        }

        my $tx = App::Zapzi::Transform->new(raw_article => $f,
                                            transformer => $self->transformer);
        if (! $tx->to_readable)
        {
            print "Could not transform article\n\n";
            $self->run(1);
            next;
        }

        printf("Got '%s' (%.1fkb)\n", $tx->title,
               length($tx->readable_text) / 1024);

        my $rs = App::Zapzi::Articles::add_article(title => $tx->title,
                                                   text => $tx->readable_text,
                                                   folder => $self->folder);
        printf("Added article %d to folder '%s'\n\n", $rs->id, $self->folder);
    }
}

=method show

Outputs text of an article

=cut

sub show
{
    my $self = shift;
    my @args = @_;

    if (! @args)
    {
        print "Need to provide article IDs\n";
        $self->run(1);
        return;
    }

    $self->run(0);
    for (@args)
    {
        my $art_rs = App::Zapzi::Articles::get_article($_);
        if ($art_rs)
        {
            print "<html><head><meta charset=\"utf-8\">\n";
            printf("<title>%s</title>\n", $art_rs->title);
            print("</head><body>\n");
            print $art_rs->article_text->text, "\n";
            print("</body></html>\n\b");
        }
        else
        {
            print "Could not get article $_\n\n";
            $self->run(1);
        }
    }
}

=method publish

Publish a folder of articles to an eBook

=cut

sub publish
{
    my $self = shift;
    $self->run(0);

    my $articles = App::Zapzi::Articles::get_articles($self->folder);
    my $count  = $articles->count;

    if ($count == 0)
    {
        print "No articles in '", $self->folder, "' to publish\n";
        $self->run(1);
        return;
    }

    printf("Publishing '%s' - %d articles\n", $self->folder, $count);

    my $pub = App::Zapzi::Publish->
        new(folder => $self->folder,
            archive_folder => $self->noarchive ? undef : 'Archive');

    if (! $pub->publish())
    {
        print "Failed to publish ebook\n";
        $self->run(1);
        return;
    }

    print "Published ", $pub->filename, "\n";
}

=method help

Displays help text.

=cut

sub help
{
    my $self = shift;

    print << 'EOF';
  $ zapzi help|h
    Shows this help text

  $ zapzi version|v
    Show version information

  $ zapzi init [--force]
    Initialises new zapzi database. Will not create a new database
    if one exists already unless you set --force.

  $ zapzi add [-t TRANSFORMER] FILE | URL
    Adds article to database. Accepts multiple file names or URLs.
    TRANSFORMER determines how to extract the text from the article
    and can be HTML, HTMLExtractMain, POD or TextMarkdown
    If not specified, Zapzi will choose the best option based on the
    content type of the article.

  $ zapzi list | ls [-f FOLDER]
    Lists articles in FOLDER.

  $ zapzi list-folders | lsf
    Lists a summary of all folders.

  $ zapzi make-folder | mkf | md FOLDER
    Make a new folder.

  $ zapzi delete-folder | rmf | rd FOLDER
    Remove a folder and all articles in it.

  $ zapzi delete-article | delete | rm ID
    Removes article ID.

  $ zapzi show | cat ID
    Prints content of article to STDOUT

  $ zapzi publish | pub [-f FOLDER] [--noarchive]
    Publishes articles in FOLDER to an eBook. Will archive articles unless
    --noarchive is set.
EOF

    $self->run(0);
}

=method version

Displays version information.

=cut

sub version
{
    my $self = shift;

    my $v = "dev";
    no strict 'vars'; ## no critic - $VERSION does not exist in dev
    $v = "$VERSION" if defined $VERSION;

    print "App::Zapzi $v and Perl $]\n";
    print "Database schema version ", $self->database->get_version, "\n";
    $self->run(0);
}

1;
