use utf8;
use strict;
use warnings;

package App::Zapzi::Folders;
# VERSION
# ABSTRACT: routines to access Zapzi folders

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(get_folder add_folder delete_folder);

use App::Zapzi;
use Carp;

=method get_folder(name)

Returns the database resultset for the folder called C<name>.

=cut

sub get_folder
{
    my ($name) = @_;

    my $rs = _folders()->find({name => $name});
    return $rs;
}

=method get_folder(name)

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

# Convenience function to get the DBIx::Class::ResultSet object for
# this table.

sub _folders
{
    return App::Zapzi::get_app()->database->schema->resultset('Folder');
}

1;
