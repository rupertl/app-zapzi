use utf8;
use strict;
use warnings;

binmode(STDOUT, ":utf8"); 

package App::Zapzi;
use Getopt::Lucid qw( :all );
use File::HomeDir;
use App::Zapzi::Database;
use App::Zapzi::Folders;
use App::Zapzi::Articles;
use App::Zapzi::FetchArticle;
use App::Zapzi::Transform;
use Moo;
use Carp;

# VERSION
# ABSTRACT: store articles and publish them to read later

=attr run

The current state of the application, 0 being OK. Used for exit code
when the process terminates.

=cut

has run => (is => 'rw', default => 0);

=attr force

Option to force processing of the init command. Default is unset. 

=cut

has force => (is => 'rw', default => 0);

=attr folder

Folder to work on. Default is 'Inbox'

=cut

has folder => (is => 'rw', default => 'Inbox');

=method get_app
=method BUILD

At construction time, a copy of the application object is stored and
can be retrieved later via C<get_app>.

=cut

our $the_app;
sub BUILD { $the_app = shift; }
sub get_app 
{ 
    croak 'Must create an instance of App::Zapzi first' unless $the_app; 
    return $the_app; 
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

=method process_args(@args)

Read the arguments C<@args> (normally you'd pass in C<@ARGV> and
process them according to the command line specification for the
application.

=cut

sub process_args
{
    my $self = shift;
    my @args = @_;

    $self->run = 0;

    my @specs =
    (
        Switch("init"),
        Switch("add"),
        Switch("list|ls"),
        Switch("list-folders|lsf"),
        Switch("make-folder|mkf"),
        Switch("delete-folder|rmf"),
        Switch("delete-article|delete|rm"),
        Switch("show"),
        Switch("publish"),

        Param("folder|f"),
        Switch("force"),
    );
    
    my $options = Getopt::Lucid->getopt(\@specs, \@args)->validate;
    
    $self->force = $options->get_force;
    $self->folder = $options->get_folder // $self->folder;

    unless ($options->get_make_folder || $options->get_init)
    {
        if (! $self->validate_folder($self->folder))
        {
            $self->run = 1;
            return;
        }
    }
    
    $self->init if $options->get_init;
    $self->list if $options->get_list;
    $self->list_folders if $options->get_list_folders;
    $self->make_folder(@args) if $options->get_make_folder;
    $self->delete_folder(@args) if $options->get_delete_folder;
    $self->delete_article(@args) if $options->get_delete_article;
    $self->add(@args) if $options->get_add;
    $self->show(@args) if $options->get_show;

    print "publish...\n" if $options->get_publish;
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
        $self->run = 1;
    }
    elsif (-d $dir && ! $self->force)
    {
        print "Zapzi directory $dir already exists\n";
        print "To force recreation, run with the --force option\n";
        $self->run = 1;
    }
    else
    {
        $self->database->init;
        print "Created Zapzi directory $dir\n";
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
        $self->run = 1;
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
    App::Zapzi::Articles::list_articles($self->folder);
}

=method list_folders

List a summary of folders in the database.

=cut

sub list_folders
{
    App::Zapzi::Folders::list_folders();
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
        $self->run = 1;
    }
    else
    {
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
        $self->run = 1;
    }

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
        $self->run = 1;
        return;
    }

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
            $self->run = 1;
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
        $self->run = 1;
        return;
    }

    for (@args)
    {
        my $source = $_;
        print "Working on $source\n";
        my $f = App::Zapzi::FetchArticle->new(source => $source);
        if (! $f->fetch)
        {
            print "Could not get article: ", $f->error, "\n\n";
            $self->run = 1;
            next;
        }

        my $tx = App::Zapzi::Transform->new(raw_article => $f);
        if (! $tx->to_readable)
        {
            print "Could not transform article\n\n";
            $self->run = 1;
            next;
        }
        
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
        $self->run = 1;
        return;
    }

    for (@args)
    {
        my $art_rs = App::Zapzi::Articles::get_article($_);
        if ($art_rs)
        {
            print $art_rs->article_text->text, "\n\n";
        }
        else
        {
            print "Could not get article $_\n\n";
            $self->run = 1;
        }
    }
}

1;
