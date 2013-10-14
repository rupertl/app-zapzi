package App::Zapzi::Roles::Distributor;
# ABSTRACT: role definition for distributor modules

=head1 DESCRIPTION

This defines the distributor role for Zapzi. Distributors take a
published eBook and send it somewhere else, eg copy to a reader, send
by email, run a script on it.

=cut

use utf8;
use strict;
use warnings;

# VERSION

use Carp;
use Moo::Role;

=head1 ATTRIBUTES

=attr file

eBook file to distribute.

=cut

has file => (is => 'ro', required => 1);

=attr destination

Where to send the file, eg another directory or an email address

=cut

has destination => (is => 'ro', required => 1);

=attr completion_message

Message from the distributer after completion - should be set in both
error and success cases.

=cut

has completion_message => (is => 'rwp', default => '');

=head1 REQUIRED METHODS

=head2 name

Name of distributor visible to user.

=cut

=head2 distribute

Distribute the file. Returns 1 if OK, undef if failed.

=cut

requires qw(name distribute);

1;
