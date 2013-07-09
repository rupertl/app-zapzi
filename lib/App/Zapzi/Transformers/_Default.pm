package App::Zapzi::Transformers::_Default;
# ABSTRACT: default text transformer

=head1 DESCRIPTION

This module is the default choice where no other transformer can be
found. It calls Text::Markdown.

=cut

use utf8;
use strict;
use warnings;

# VERSION

use Carp;
use Encode;
use Text::Markdown;
use Moo;

extends 'App::Zapzi::Transformers::TextMarkdown';

=method name

Name of transformer visible to user.

=cut

sub name
{
    return 'Default';
}

=method handles($content_type)

Returns true if this module handles the given content-type

=cut

sub handles
{
    # This is the default for any text not handled by other modules
    return 1;
}

1;
