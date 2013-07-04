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

=attr source

Object of type App::Zapzi::FetchArticle to get original text from.

=cut

has source => (is => 'ro', isa => sub 
               {
                   croak 'Source must be an App::Zapzi::FetchArticle'
                       unless ref($_[0]) eq 'App::Zapzi::FetchArticle';
               });

=attr readable_text

Holds the readable text of the article

=cut

has readable_text => (is => 'ro', default => '');

=method to_readable

Converts L<source> to readable text. Returns true if converted OK.

=cut

sub to_readable
{
    my $self = shift;

    if ($self->source->content_type =~ m|text/html|)
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

    my $raw_html = Encode::decode_utf8($self->source->text);

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

    # We push plain text through Markdown to convert URLs to links etc
    my $md = Text::Markdown->new;
    $self->readable_text = $md->markdown($self->source->text);

    return 1;
}



1;
