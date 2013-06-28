use utf8;
use strict;
use warnings;

package App::Zapzi::Database::Schema::Article;
# VERSION
# ABSTRACT: zapzi article table

use base 'DBIx::Class::Core';

=head1 SYNOPSIS

This module defines the schema for the articles table in the Zapzi
database.

=cut

__PACKAGE__->table("articles");

=head1 ACCESSORS

=head2 id

  Unique ID for this article
  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 title

  Title of this book.
  data_type: 'text'
  default_value: 'Unknown'
  is_nullable: 0

=head2 folder

  FK to folders
  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns
(
    "id",
    { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
    "title",
    { data_type => "text", default_value => "Unknown", is_nullable => 0 },
    "folder",
    { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONSHIPS

=head2 Belongs to

=over 4

=item * folder (-> Folder)

=back

=head2 Might have

=over 4

=item * article_text (-> ArticleText)

=back

=cut

__PACKAGE__->belongs_to(folder => 'App::Zapzi::Database::Schema::Folder', 
                        'folder');

__PACKAGE__->might_have(article_text => 
                        'App::Zapzi::Database::Schema::ArticleText', 
                        'id');
1;
