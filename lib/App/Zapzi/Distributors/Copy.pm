package App::Zapzi::Distributors::Copy;
# ABSTRACT: distribute a published eBook by copying the file somewhere

=head1 DESCRIPTION

This class copies a published eBook. The destination passed in can
either be a directory, in which case the file will be copied there
with the same filename as the original, or a filename, in which case
the file will be copied to that name.

=cut

use utf8;
use strict;
use warnings;

# VERSION

use Carp;
use Moo;
use App::Zapzi;
use File::Copy;

with 'App::Zapzi::Roles::Distributor';

=method name

Name of distributor visible to user.

=cut

sub name
{
    return 'Copy';
}

=head2 distribute

Distribute the file. Returns 1 if OK, undef if failed.

=cut

sub distribute
{
    my $self = shift;

    my $rc = copy($self->file, $self->destination);
    if ($rc)
    {
        $self->_set_completion_message("File copied to '" .
                                       $self->destination .
                                       "' successfully.");
        return 1;
    }
    else
    {
        $self->_set_completion_message("Error copying file to '" .
                                       $self->destination .
                                       "': $!.");
        return 0;
    }
}

1;
