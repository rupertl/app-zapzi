package App::Zapzi::Transformers::TextMarkdown;
# ABSTRACT: transform text using Markdown

=head1 DESCRIPTION

This class takes text and returns readable HTML using Text::Markdown

=cut

use utf8;
use strict;
use warnings;

# VERSION

use Carp;
use Encode;
use Text::Markdown;
use Moo;

with 'App::Zapzi::Roles::Transformer';

=method name

Name of transformer visible to user.

=cut

sub name
{
    return 'TextMarkdown';
}

=method handles($content_type)

Returns true if this module handles the given content-type

=cut

sub handles
{
    my $self = shift;
    my $content_type = shift;

    return 1 if $content_type =~ m|text/plain|;
}

=method transform

Converts L<input> to readable text. Returns true if converted OK.

=cut

sub transform
{
    my $self = shift;

    my $raw = Encode::decode_utf8($self->input->text);

    # Chop off any blank lines at the top
    $raw =~ s/^\n+//s;

    # We take the first line as the title, or up to 80 bytes
    $self->_set_title( (split /\n/, $raw)[0] );
    $self->_set_title(substr($self->title, 0, 80));

    # We push plain text through Markdown to convert URLs to links etc
    my $md = Text::Markdown->new;
    $self->_set_readable_text($md->markdown($raw));

    # In case of unbalanced tags etc Text::Markdown may set $@ so
    # treat that as an error.
    return if $@;

    return 1;
}

1;
