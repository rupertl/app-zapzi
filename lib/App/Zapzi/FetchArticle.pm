package App::Zapzi::FetchArticle;
# ABSTRACT: routines to get articles for Zapzi

=head1 DESCRIPTION

These routines get articles, either via HTTP or from the file system
and returns the raw HTML or text.

=cut

use utf8;
use strict;
use warnings;

# VERSION

use Module::Find 0.11;
our @_plugins;
BEGIN { @_plugins = sort(Module::Find::useall('App::Zapzi::Fetchers')); }

use Carp;
use App::Zapzi;
use Moo;

=attr source

Pass in the source of the article - either a filename or a URL.

=cut

has source => (is => 'ro', default => '');

=attr text

Holds the raw text of the article

=cut

has text => (is => 'rwp', default => '');

=attr content_type

MIME content type for text.

=cut

has content_type => (is => 'rwp', default => 'text/plain');

=attr error

Holds details of any errors encountered while retrieving the article;
will be blank if no errors.

=cut

has error => (is => 'rwp', default => '');

=method fetch

Retrieves the article and returns 1 if OK. Text of the article can
then be found in L<text>.

=cut

sub fetch
{
    my $self = shift;

    my $module;
    for (@_plugins)
    {
        my $plugin = $_;
        my $valid_source = $plugin->handles($self->source);
        if (defined $valid_source)
        {
            $module = $plugin->new(source => $valid_source);
            last;
        }
    }

    if (!defined $module)
    {
        $self->_set_error("Failed to fetch article - can't find or handle");
        return;
    }

    my $rc = $module->fetch;
    if ($rc)
    {
        $self->_set_text($module->text);
        $self->_set_content_type($module->content_type);
    }
    else
    {
        $self->_set_error($module->error);
    }

    return $rc;
}

1;
