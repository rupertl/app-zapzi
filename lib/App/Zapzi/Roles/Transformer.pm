package App::Zapzi::Roles::Transformer;
# ABSTRACT: role definition for transformer modules

=head1 DESCRIPTION

This defines the transformer role for Zapzi. Transformers take
articles in their native format and transform it to 'simple HTML' for
consumption by an eReader.

=cut

use utf8;
use strict;
use warnings;

# VERSION

use Carp;
use App::Zapzi::FetchArticle;
use Moo::Role;

=attr input

Object of type App::Zapzi::FetchArticle to get original text from.

=cut

has input => (is => 'ro', isa => sub
              {
                  croak 'Source must be an App::Zapzi::FetchArticle'
                      unless ref($_[0]) eq 'App::Zapzi::FetchArticle';
              });

=attr readable_text

Holds the readable text of the article

=cut

has readable_text => (is => 'rwp', default => '');

=attr title

Title extracted from the article

=cut

has title => (is => 'rwp', default => '');

=head1 REQUIRED METHODS

=head2 name

Name of transformer visible to user.

=cut

=head2 handles($content_type)

Returns true if this implementation handles the specified
content_type, eg 'text/html'.

=head2 transform

Transform input to readable text and title.

=cut

requires qw(name handles transform);

1;
