package App::Zapzi::Distributors::Script;
# ABSTRACT: distribute a published eBook by running a script

=head1 DESCRIPTION

This class runs a script on a completed eBook. The filename is passed
to the script as the first parameter. The script should return 0 on
success or any other code as failure. Any output from the script will
be passed back to the caller in the completion message.

=cut

use utf8;
use strict;
use warnings;

# VERSION

use Carp;
use Moo;
use App::Zapzi;

with 'App::Zapzi::Roles::Distributor';

=method name

Name of distributor visible to user.

=cut

sub name
{
    return 'Script';
}

=head2 distribute

Distribute the file. Returns 1 if OK, undef if failed.

=cut

sub distribute
{
    my $self = shift;

    unless (-x $self->destination)
    {
        $self->_set_completion_message("Script does not exist");
        return 0;
    }

    open my $pipe, '-|', $self->destination, $self->file
        or return 0;

    my $message;
    while (<$pipe>)
    {
        $message .= $_;
    }

    $self->_set_completion_message($message);
    close $pipe;
    return $? == 0 ? 1 : undef;
}

1;
