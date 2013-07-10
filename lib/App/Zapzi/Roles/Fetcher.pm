package App::Zapzi::Roles::Fetcher;
# ABSTRACT: role definition for fetcher modules

=head1 DESCRIPTION

This defines the fetcher role for Zapzi. Fetchers take a source, such
as a filename or URL, and return raw article text.

=cut

use utf8;
use strict;
use warnings;

# VERSION

use Carp;
use Moo::Role;

=attr source

Pass in the source of the article - either a filename or a URL.

=cut

has source => (is => 'ro', default => '');

=attr text

Holds the raw text of the article

=cut

has text => (is => 'rwp', default => '');

=attr content_type

MIME content type for text.

=cut

has content_type => (is => 'rwp', default => 'text/plain');

=attr error

Holds details of any errors encountered while retrieving the article;
will be blank if no errors.

=cut

has error => (is => 'rwp', default => '');

=head1 REQUIRED METHODS

=head2 name

Name of fetcher visible to user.

=cut

=head2 handles($source)

Returns true if this implementation handles the specified
article source

=head2 fetch

Fetch the article

=cut

requires qw(name handles fetch);

1;
