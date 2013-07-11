package App::Zapzi::Transformers::HTMLExtractMain;
# ABSTRACT: transform text using HTMLExtractMain

=head1 DESCRIPTION

This class takes HTML and returns readable HTML using HTML::ExtractMain.

=cut

use utf8;
use strict;
use warnings;

# VERSION

use Carp;
use Encode;
use HTML::ExtractMain 0.63;
use HTML::Element;
use HTML::Entities ();
use Moo;

with 'App::Zapzi::Roles::Transformer';

=method name

Name of transformer visible to user.

=cut

sub name
{
    return 'HTMLExtractMain';
}

=method handles($content_type)

Returns true if this module handles the given content-type

=cut

sub handles
{
    my $self = shift;
    my $content_type = shift;

    return 1 if $content_type =~ m|text/html|;
}

=method transform

Converts L<input> to readable text. Returns true if converted OK.

=cut

sub transform
{
    my $self = shift;

    my $encoding = 'utf8';
    if ($self->input->content_type =~ m/charset=([\w-]+)/)
    {
        $encoding = $1;
    }
    my $raw_html = Encode::decode($encoding, $self->input->text);

    # Get the title from the HTML raw text - a regexp is not ideal and
    # we'd be better off using HTML::Tree but that means we'd have to
    # call it twice, once here and once in HTML::ExtractMain.
    my $title;
    if ($raw_html =~ m/<title>(\w[^>]+)<\/title>/si)
    {
        $title = HTML::Entities::decode($1);
    }
    else
    {
        $title = $self->raw_article->source;
    }

    $self->_set_title($title);

    my $tree = HTML::ExtractMain::extract_main_html($raw_html,
                                                    output_type => 'tree' );

    return unless $tree;

    # Delete some elements we don't need
    for my $element ($tree->find_by_tag_name(qw{img script noscript object}))
    {
        $element->delete;
    }

    # Set up options to extract the HTML from the tree
    my $entities_to_encode = '';
    my $indent = ' ' x 4;
    my $optional_end_tags = {};

    $self->_set_readable_text($tree->as_HTML($entities_to_encode, $indent,
                                             $optional_end_tags));
    return 1;
}

1;
