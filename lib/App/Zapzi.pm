use utf8;
use strict;
use warnings;

package App::Zapzi;
use Getopt::Lucid qw( :all );
use File::HomeDir;
use App::Zapzi::Database;
use App::Zapzi::Folders;
use App::Zapzi::Articles;
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
        Switch("list"),
        Switch("list-folders|lsf"),
        Switch("make-folder|mkf"),
        Switch("delete-folder|rmf"),
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

    print "add...\n" if $options->get_add;
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
    else
    {
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
}
1;
