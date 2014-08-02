package App::Zapzi::Transformers::HTMLExtractMain;
# ABSTRACT: transform text using HTMLExtractMain

=head1 DESCRIPTION

This class takes HTML and returns readable HTML using
HTML::ExtractMain. It attempts to remove text that is not part of the
main article body, eg menus or headers.

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

    $self->_remove_fonts($tree);
    $self->_optionally_deactivate_links($tree);

    return $tree;
}

sub _remove_fonts
{
    my ($self, $tree) = @_;

    # Remove any font attributes as they rarely work as expected on
    # eReaders - eg colours do not make sense on monochrome displays,
    # font families will probably not exist.
    for my $font ($tree->look_down(_tag => "font"))
    {
        $font->attr($_, undef) for $font->all_external_attr_names;
    }
}

sub _optionally_deactivate_links
{
    my ($self, $tree) = @_;

    # Turn links into text if option was requested.

    my $option = App::Zapzi::UserConfig::get('deactivate_links');

    if ($option && $option =~ /^Y/i)
    {
        for my $a ($tree->find_by_tag_name('a'))
        {
            if ($a->attr('href') !~ /^#/)
            {
                $a->replace_with_content($a->as_text);
            }
        }
    }
}

1;
