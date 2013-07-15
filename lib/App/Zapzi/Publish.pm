package App::Zapzi::Publish;
# ABSTRACT: create eBooks from Zapzi articles

=head1 DESCRIPTION

This class takes a collection of cleaned up HTML articles and creates eBooks.

This interface is temporary to get the initial version of Zapzi
working and will be replaced with a more flexible role based system
later.

=cut

use utf8;
use strict;
use warnings;

# VERSION

use Carp;
use Encode;
use App::Zapzi;
use DateTime;
use EBook::MOBI 0.65;
use HTML::Entities;
use Moo;

=attr folder

Folder of articles to publish

=cut

has folder => (is => 'ro', required => 1);

=attr archive_folder

Folder to move articles to after publication - undef means don't move.

=cut

has archive_folder => (is => 'ro', required => 0, default => 'Archive');

=attr filename

File that the published ebook is stored in.

=cut

has filename => (is => 'rwp');

=method publish

Publish an eBook in MOBI format to the ebook directory.

=cut

sub publish
{
    my $self = shift;

    $self->_make_filename();
    unlink($self->filename);

    my $book = EBook::MOBI->new();
    $book->set_filename($self->filename);
    $book->set_title($self->_get_title);
    $book->set_author('Zapzi');
    $book->set_encoding(':encoding(UTF-8)');
    $book->add_toc_once();
    $book->add_mhtml_content("<hr>\n");

    my $articles = App::Zapzi::Articles::get_articles($self->folder);
    while (my $article = $articles->next)
    {
        $book->add_mhtml_content("<h1>" .
                                 HTML::Entities::encode($article->title) .
                                 "</h1>\n");
        $book->add_mhtml_content(encode_utf8($article->article_text->text));
        $book->add_pagebreak();

        $self->_archive_article($article);
    }

    $book->make();
    $book->save();

    return -s $self->filename;
}

sub _get_title
{
    my $self = shift;

    my $dt = DateTime->now;
    return sprintf("%s - %s", $self->folder, $dt->strftime('%d-%b-%Y'));
}


sub _make_filename
{
    my $self = shift;
    my $app = App::Zapzi::get_app();

    my $base = sprintf("Zapzi - %s.mobi", $self->_get_title);

    $self->_set_filename($app->zapzi_ebook_dir . "/" . $base);
}

sub _archive_article
{
    my $self = shift;
    my ($article) = @_;

    if (defined($self->archive_folder) &&  $self->folder ne 'Archive')
    {
        App::Zapzi::Articles::move_article($article->id, $self->archive_folder);
    }
}

1;
