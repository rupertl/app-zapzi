use utf8;
use strict;
use warnings;
package App::Zapzi::Database::Schema::ArticleText;
# VERSION

use base 'DBIx::Class::Core';

=head1 SYNOPSIS

This module defines the schema for the article_text table in the Zapzi
database.

=cut

__PACKAGE__->table("article_text");

=head1 ACCESSORS

=head2 id

  FK to articles
  data_type: 'integer'
  is_nullable: 0

=head2 text

  Body of the article
  data_type: 'blob'
  default_value: ''
  is_nullable: 0

=cut

__PACKAGE__->add_columns
(
    "id",
    { data_type => "integer", is_nullable => 0 },
    "text",
    { data_type => "blob", default_value => "", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</article_id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONSHIPS

=head2 Has one

=over 4

=item * article (-> Article)

=back

=cut

__PACKAGE__->belongs_to(article => 'App::Zapzi::Database::Schema::Article', 
                        'id');

1;
