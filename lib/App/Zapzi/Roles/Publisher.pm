package App::Zapzi::Roles::Publisher;
# ABSTRACT: role definition for publisher modules

=head1 DESCRIPTION

This defines the publisher role for Zapzi. Publishers take a folder
and create an eBook or collection file containing articles in the
folder.

=cut

use utf8;
use strict;
use warnings;

# VERSION

use Carp;
use Moo::Role;

=head1 ATTRIBUTES

=attr folder

Folder of articles to publish.

=cut

has folder => (is => 'ro', required => 1);

=attr encoding

Encoding to use when publishing.

=cut

has encoding => (is => 'rwp', required => 1);

=attr collection_title

Title of collection, eg eBook name.

=cut

has collection_title => (is => 'ro', required => 1);

=attr filename

File that the published ebook is stored in.

=cut

has filename => (is => 'ro', required => 1);

=attr collection_data

Returns the raw data (eg combined HTML) produced by the publisher -
for testing.

=cut

has collection_data => (is => 'rwp');

=head1 REQUIRED METHODS

=head2 name

Name of publisher visible to user.

=cut

=head2 start_publication($folder, $encoding)

Starts a new publication for the given folder in the given encoding.

=cut

=head2 add_article($article)

Adds an article to the publication.

=cut

=head2 finish_publication()

Finishes publication and returns the filename created.

=cut

requires qw(name start_publication add_article finish_publication);

1;
