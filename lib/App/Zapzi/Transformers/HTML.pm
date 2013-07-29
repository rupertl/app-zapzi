package App::Zapzi::Transformers::HTML;
# ABSTRACT: transform text using HTMLExtractMain

=head1 DESCRIPTION

This class takes HTML and returns the body without doing additional
readable transforms.

=cut

use utf8;
use strict;
use warnings;

# VERSION

use Carp;
use Encode;
use HTML::Element;
use HTML::Entities ();
use Moo;

with 'App::Zapzi::Roles::Transformer';

=method name

Name of transformer visible to user.

=cut

sub name
{
    return 'HTML';
}

=method handles($content_type)

Returns true if this module handles the given content-type

=cut

sub handles
{
    # By default HTMLExtractMain will handle HTML, not this
    return 0;
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

    $self->_extract_title($raw_html);

    my $tree = $self->_extract_html($raw_html);
    return unless $tree;

    # Delete some elements we don't need
    for my $element ($tree->find_by_tag_name(qw{img script noscript object}))
    {
        $element->delete;
    }

    # Set up options to extract the HTML from the tree
    my $entities_to_encode = '<>&\'"';
    my $indent = ' ' x 4;
    my $optional_end_tags = {};

    my $text = $tree->as_HTML($entities_to_encode, $indent,
                              $optional_end_tags);
    $text =~ s|<[/]*body>||sg;
    $self->_set_readable_text($text);
    return 1;
}

sub _extract_title
{
    my $self = shift;
    my ($raw_html) = @_;
    my $title;

    # Try finding the <title> tag first
    my $tree = eval { HTML::TreeBuilder->new_from_content($raw_html) };
    if ($tree)
    {
        my $tag = $tree->find_by_tag_name('title');
        my $content;
        $content = ($tag->content_list)[0] if $tag;

        # Strip surrounding whitespace and decode HTML entities
        $content =~ s/^\s+|\s+$//g if $content;
        $title = HTML::Entities::decode($content) if $content;
    }

    # Use the URL/filename if no title could be found or parsed from
    # the HTML
    if (! $title)
    {
        $title = $self->input->source;
    }

    $self->_set_title($title);
}

sub _extract_html
{
    my $self = shift;
    my ($raw_html) = @_;

    my $tree = eval { HTML::TreeBuilder->new_from_content($raw_html)
                          ->find_by_tag_name('body') };

    return $tree;
}

1;
