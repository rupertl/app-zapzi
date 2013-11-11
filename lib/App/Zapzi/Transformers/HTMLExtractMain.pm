package App::Zapzi::Transformers::HTMLExtractMain;
# ABSTRACT: transform text using HTMLExtractMain

=head1 DESCRIPTION

This class takes HTML and returns readable HTML using HTML::ExtractMain.

=cut

use utf8;
use strict;
use warnings;

# VERSION

use HTML::ExtractMain 0.63;
use Moo;

extends "App::Zapzi::Transformers::HTML";

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

# transform and _extract_title inherited from parent

sub _extract_html
{
    my $self = shift;
    my ($raw_html) = @_;

    my $tree = HTML::ExtractMain::extract_main_html($raw_html,
                                                    output_type => 'tree' );

    # Remove any font attributes as they rarely work as expected on
    # eReaders - eg colours do not make sense on monochrome displays,
    # font families will probably not exist.
    for my $font ($tree->look_down(_tag => "font"))
    {
        $font->attr($_, undef) for $font->all_external_attr_names;
    }

    return $tree;
}

1;
