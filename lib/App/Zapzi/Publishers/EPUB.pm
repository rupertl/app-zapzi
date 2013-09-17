package App::Zapzi::Publishers::EPUB;
# ABSTRACT: publishes articles to a EPUB eBook file

=head1 DESCRIPTION

This class creates a EPUB file from a collection of articles.

=cut

use utf8;
use strict;
use warnings;

# VERSION

use Carp;
use Moo;
use App::Zapzi;
use EBook::EPUB 0.6;
use HTML::TreeBuilder;
use HTML::Entities;

with 'App::Zapzi::Roles::Publisher';

=attr epub

Returns the EBook::EPUB object created.

=cut

has epub => (is => 'rwp');

=method name

Name of publisher visible to user.

=cut

sub name
{
    return 'EPUB';
}

=head2 start_publication($folder, $encoding)

Starts a new publication for the given folder in the given encoding.

=cut

sub start_publication
{
    my $self = shift;

    # add_xhtml seems to use UTF-8 internally
    $self->_set_encoding('UTF-8');

    my $book = EBook::EPUB->new();
    $book->add_title($self->collection_title);
    $book->add_author('Zapzi');

    $self->_set_collection_data("");
    $self->_set_epub($book);
}

=head2 add_article($article, $index)

Adds an article, sequence number index,  to the publication.

=cut

sub add_article
{
    my $self = shift;
    my ($article, $index) = @_;

    my $article_filename = "Article-$index";
    my $article_xhtml = $self->_extract_xhtml($article->{encoded_title} .
                                              $article->{text});
    my $id = $self->epub->add_xhtml($article_filename,
                                    $article_xhtml);

    # Add top-level nav-point
    my $navpoint = $self->epub->add_navpoint(
        label       => $article->{title},
        id          => $id,
        content     => $article_filename,
        play_order  => $index+1); # start at 1

    $self->_set_collection_data($self->collection_data . $article_xhtml);
}

sub _extract_xhtml
{
    # Convert the HTML to XHTML as required by EBook::EPUB

    my $self = shift;
    my ($input) = @_;

    my $tree = eval { HTML::TreeBuilder->new_from_content($input) };
    if ($tree)
    {
        return $tree->as_XML();
    }
}


=head2 finish_publication()

Finishes publication and returns the filename created.

=cut

sub finish_publication
{
    my $self = shift;

    $self->epub->pack_zip($self->filename);

    return $self->filename;
}

1;
