package App::Zapzi::Distribute;
# ABSTRACT: distribute published eBooks to a destination

=head1 DESCRIPTION

This class takes a published eBook and distributes it. The
distribution method can either be set in the class attributes (eg
coming from the command line) or via config variables. Default if
neither is set is to not distribute the eBook further.

=cut

use utf8;
use strict;
use warnings;

# VERSION

use Module::Find 0.11;
our @_plugins;
BEGIN { @_plugins = sort(Module::Find::useall('App::Zapzi::Distributors')); }

use App::Zapzi;
use Carp;
use Moo;

=attr file

Completed eBook file to distribute.

=cut

has file => (is => 'ro', required => 1);

=attr method

Method to distribute file. If set, must be one of the defined
Distributer roles.

=cut

has method => (is => 'ro');

=attr destination

Where to send the file to. The distribution role will validate this.

=cut

has destination => (is => 'ro');

=attr completion_message

Message from the distributer after completion - should be set in both
error and success cases, but blank if no distributer has been invoked.

=cut

has completion_message => (is => 'rwp', default => "");

=method distribute

Distributes the file according to the method set on the class or the
default configured distribution. Returns 1 if OK (including no
distributor defined), undef on failure.

=cut

sub distribute
{
    my $self = shift;

    # Do nothing if no distributor defined
    return 1 if ! $self->method;

    my $module = $self->_find_module();
    if (! defined $module)
    {
        $self->_set_completion_message(
            "Distribution method '" . $self->method . "' not defined");
        return;
    }

    my $rc = $module->distribute();
    $self->_set_completion_message($module->completion_message);
    return $rc;
}

sub _find_module
{
    my $self = shift;

    for (@_plugins)
    {
        if (lc($self->method) eq lc($_->name))
        {
            return $_->new(file => $self->file,
                           destination => $self->destination);
        }
    }

    return;
}

1;
