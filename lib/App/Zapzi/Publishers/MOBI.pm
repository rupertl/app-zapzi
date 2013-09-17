package App::Zapzi::Publishers::MOBI;
# ABSTRACT: publishes articles to a MOBI eBook file

=head1 DESCRIPTION

This class creates a MOBI file from a collection of articles.

=cut

use utf8;
use strict;
use warnings;

# VERSION

use Carp;
use Moo;
use App::Zapzi;
use EBook::MOBI 0.65;

with 'App::Zapzi::Roles::Publisher';

=attr mobi

Returns the EBook::MOBI object created.

=cut

has mobi => (is => 'rwp');

=method name

Name of publisher visible to user.

=cut

sub name
{
    return 'MOBI';
}

=head2 start_publication($folder, $encoding)

Starts a new publication for the given folder in the given encoding.

=cut

sub start_publication
{
    my $self = shift;

    # Default encoding is ISO-8859-1 as early Kindles have issues with
    # UTF-8. Characters that cannot be encoded will be replaced with
    # their HTML entity equivalents.
    $self->_set_encoding('ISO-8859-1') unless $self->encoding;

    my $book = EBook::MOBI->new();
    $book->set_filename($self->filename);
    $book->set_title($self->collection_title);
    $book->set_author('Zapzi');
    $book->set_encoding(':encoding(' . $self->encoding . ')');
    $book->add_toc_once();
    $book->add_mhtml_content("<hr>\n");

    $self->_set_mobi($book);
}

=head2 add_article($article, $index)

Adds an article, sequence number index,  to the publication.

=cut

sub add_article
{
    my $self = shift;
    my ($article, $index) = @_;

    $self->mobi->add_pagebreak() unless $index == 0;
    $self->mobi->add_mhtml_content($article->{encoded_title});
    $self->mobi->add_mhtml_content($article->{encoded_text});
}

=head2 finish_publication()

Finishes publication and returns the filename created.

=cut

sub finish_publication
{
    my $self = shift;

    $self->mobi->make();
    $self->_set_collection_data($self->mobi->print_mhtml('noprint'));

    $self->mobi->save();
    return $self->filename;
}

1;
