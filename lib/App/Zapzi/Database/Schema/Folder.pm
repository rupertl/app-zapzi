package App::Zapzi::Database::Schema::Folder;
# VERSION
# ABSTRACT: zapzi folder table

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 DESCRIPTION

This module defines the schema for the folders table in the Zapzi
database.

=cut

__PACKAGE__->table("folders");

=head1 ACCESSORS

=head2 id

  Unique ID for this folder
  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  Name of this folder
  data_type: 'text'
  default_value: 'Unknown'
  is_nullable: 0

=cut

__PACKAGE__->add_columns
(
    "id",
    { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
    "name",
    { data_type => "text", default_value => "Unknown", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<name_unique>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("name_unique", ["name"]);

=head1 RELATIONSHIPS

=head2 Has many

=over 4

=item * articles (-> Article)

=back

=cut

__PACKAGE__->has_many(articles =>
                      'App::Zapzi::Database::Schema::Article',
                      'folder');

1;
