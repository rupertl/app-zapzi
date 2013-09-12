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

=attr article_count

Number of articles added to the collection.

=cut

has article_count => (is => 'rwp', default => 0);

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

    $self->_make_filename($self->folder);
    unlink($self->filename);

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

sub _make_filename
{
    my $self = shift;
    my ($folder) = @_;
    my $app = App::Zapzi::get_app();

    my $base = sprintf("Zapzi - %s.mobi", $self->collection_title);

    $self->_set_filename($app->zapzi_ebook_dir . "/" . $base);
}

=head2 add_article($article)

Adds an article to the publication.

=cut

sub add_article
{
    my $self = shift;
    my ($article) = @_;

    $self->mobi->add_pagebreak() unless $self->article_count == 0;
    $self->mobi->add_mhtml_content("<h1>" .
                             HTML::Entities::encode($article->{title}) .
                             "</h1>\n");

    $self->mobi->add_mhtml_content($article->{encoded_text});
    $self->_set_article_count($self->article_count + 1);
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
