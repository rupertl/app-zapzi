package App::Zapzi::Database::Schema::Config;
# ABSTRACT: zapzi config table

use strict;
use warnings;

# VERSION

use base 'DBIx::Class::Core';

=head1 DESCRIPTION

This module defines the schema for the config table in the Zapzi
database.

=cut

__PACKAGE__->table("config");

=head1 ACCESSORS

=head2 name

  Unique ID for this config item
  data_type: 'text'
  is_nullable: 0

=head2 value

  Value of this config item
  data_type: 'text'
  default_value: ''
  is_nullable: 0

=cut

__PACKAGE__->add_columns
(
    "name",
    { data_type => "text", is_nullable => 0 },
    "value",
    { data_type => "text", default_value => '', is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->set_primary_key("name");

=head1 UNIQUE CONSTRAINTS

None

=cut

=head1 RELATIONSHIPS

None

=cut

1;
