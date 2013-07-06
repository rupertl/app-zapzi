package App::Zapzi::Folders;
# ABSTRACT: routines to access Zapzi folders

=head1 DESCRIPTION

These routines allow access to Zapzi folders via the database.

=cut

use utf8;
use strict;
use warnings;

# VERSION

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(is_system_folder get_folder add_folder delete_folder
                    list_folders);

use App::Zapzi;
use Carp;

=method is_system_folder(name)

Returns true if the folder is used by the system eg Inbox.

=cut

sub is_system_folder
{
    my ($name) = @_;

    return $name eq 'Inbox' || $name eq 'Archive';
}

=method get_folder(name)

Returns the database resultset for the folder called C<name>.

=cut

sub get_folder
{
    my ($name) = @_;

    my $rs = _folders()->find({name => $name});
    return $rs;
}

=method add_folder(name)

Adds a new folder called C<name>. Will return false if it exists
already, otherwise the result of the DB add function.

=cut

sub add_folder
{
    my ($name) = @_;
    croak 'New folder name not provided' unless $name;

    if (get_folder($name) || ! _folders()->create({name => $name}))
    {
        croak("Could not add folder $name");
    }
}

=method delete_folder(name)

Deletes folder C<name> if it exists. Returns the DB result status for
the deletion.

=cut

sub delete_folder
{
    my ($name) = @_;
    my $folder = get_folder($name);

    # Ignore if the folder does not exist
    return 1 unless $folder;

    return $folder->delete;
}

=method list_folders

Print a summary of all folders in the database showing name and count
of articles.

=cut

sub list_folders
{
    my $rs = _folders()->search(undef, {prefetch => [qw(articles)]});

    while (my $folder = $rs->next)
    {
        printf("%-10s %3d\n", $folder->name, $folder->articles->count);
    }
}

# Convenience function to get the DBIx::Class::ResultSet object for
# this table.

sub _folders
{
    return App::Zapzi::get_app()->database->schema->resultset('Folder');
}

1;
