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
sub get_app { die 'unbuilt' unless $the_app; return $the_app; }

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

    my @specs =
    (
        Switch("init"),
        Switch("add"),
        Switch("list"),
        Switch("publish"),

        Param("folder|f"),
        Switch("force"),
    );
    
    my $options = Getopt::Lucid->getopt(\@specs, \@args)->validate;
    
    $self->force = $options->get_force;
    $self->folder = $options->get_folder // $self->folder;
    
    $self->init if $options->get_init;
    $self->list if $options->get_list;

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
        return;
    }

    if (-d $dir && ! $self->force)
    {
        print "Zapzi directory $dir already exists\n";
        print "To force recreation, run with the --force option\n";
        $self->run = 1;
        return;
    }

    $self->database->init;
    print "Created Zapzi directory $dir\n";
    return 1;
}

=method list

Lists out the articles in L<folder>.

=cut

sub list
{
    my $self = shift;
    
    if (! App::Zapzi::Articles::get_folder($self->folder))
    {
        printf("Folder '%s' does not exist\n", $self->folder);
        $self->run = 1;
        return;
    }
    
    App::Zapzi::Articles::list_articles($self->folder);
}

1;
