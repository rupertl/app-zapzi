package App::Zapzi::Fetchers::File;
# ABSTRACT: fetch article from a file

=head1 DESCRIPTION

This class reads an article from a local file.

=cut

use utf8;
use strict;
use warnings;

# VERSION

use Carp;
use File::MMagic 1.30;
use Moo;

with 'App::Zapzi::Roles::Fetcher';

=method name

Name of transformer visible to user.

=cut

sub name
{
    return 'File';
}

=method handles($content_type)

Returns a valide filename if this module handles the given content-type

=cut

sub handles
{
    my $self = shift;
    my $source = shift;

    return -r $source ? $source : undef;
}

=method fetch

Downloads an article

=cut

sub fetch
{
    my $self = shift;

    my $file;
    if (! open $file, '<', $self->source)
    {
        $self->_set_error("Failed to open " . $self->source . ": $!");
        return;
    }

    my $file_text;
    while (<$file>)
    {
        $file_text .= $_;
    }
    $self->_set_text($file_text);

    close $file;

    my $content_type;

    # Try extension first
    $content_type = 'text/plain' if $self->source =~ /\.(text|md|mkdn)$/;
    $content_type = 'text/html' if $self->source =~ /\.(html)$/;

    # Try file magic
    $content_type //= File::MMagic->new()->checktype_contents($self->text);

    # Default to plain text
    $content_type //= 'text/plain';

    $self->_set_content_type($content_type);

    return 1;
}

1;
