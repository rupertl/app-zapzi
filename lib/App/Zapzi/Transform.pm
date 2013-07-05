use utf8;
use strict;
use warnings;

package App::Zapzi::Transform;
# VERSION
# ABSTRACT: routines to transform Zapzi articles to readble HTML

=head1 SYNOPSIS

This class takes text or HTML and returns readable HTML.

This interface is temporary to get the initial version of Zapzi
working and will be replaced with a more flexible role based system
later.

=cut

use Carp;
use Encode;
use HTML::ExtractMain;
use HTML::Element;
use Text::Markdown;
use App::Zapzi;
use App::Zapzi::FetchArticle;
use Moo;

=attr raw_article

Object of type App::Zapzi::FetchArticle to get original text from.

=cut

has raw_article => (is => 'ro', isa => sub 
                    {
                        croak 'Source must be an App::Zapzi::FetchArticle'
                            unless ref($_[0]) eq 'App::Zapzi::FetchArticle';
                    });

=attr readable_text

Holds the readable text of the article

=cut

has readable_text => (is => 'ro', default => '');

=attr title

Title extracted from the article

=cut

has title => (is => 'ro', default => '');

=method to_readable

Converts L<raw_article> to readable text. Returns true if converted OK.

=cut

sub to_readable
{
    my $self = shift;

    if ($self->raw_article->content_type =~ m|text/html|)
    {
        return $self->_html_to_readable;
    }
    else
    {
        return $self->_text_to_readable;
    }
}

sub _html_to_readable
{
    my $self = shift;

    my $encoding = 'utf8';
    if ($self->raw_article->content_type =~ m/charset=([\w-]+)/)
    {
        $encoding = $1;
    }
    my $raw_html = Encode::decode($encoding, $self->raw_article->text);

    # Get the title from the HTML raw text - a regexp is not ideal and
    # we'd be better off using HTML::Tree but that means we'd have to
    # call it twice, once here and once in HTML::ExtractMain.
    if ($raw_html =~ m/<title>(\w[^>]+)<\/title>/si)
    {
        $self->title = $1;
    }
    else
    {
        $self->title = $self->raw_article->source;
    }

    my $tree = HTML::ExtractMain::extract_main_html($raw_html, 
                                                    output_type => 'tree' );

    return unless $tree;

    # Delete some elements we don't need
    for my $element ($tree->find_by_tag_name(qw{img script noscript object}))
    {
        $element->delete;
    }
    
    $self->readable_text = $tree->as_HTML;
    return 1;
}

sub _text_to_readable
{
    my $self = shift;

    my $raw_html = Encode::decode_utf8($self->raw_article->text);

    # We take the first line as the title, or up to 50 bytes
    $self->title = (split /\n/, $raw_html)[0];
    $self->title = substr($self->title, 0, 80);

    # We push plain text through Markdown to convert URLs to links etc
    my $md = Text::Markdown->new;
    $self->readable_text = $md->markdown($raw_html);

    return 1;
}



1;
