package App::Zapzi::Transform;
# ABSTRACT: routines to transform Zapzi articles to readble HTML

=head1 DESCRIPTION

This class takes text or HTML and returns readable HTML.

=cut

use utf8;
use strict;
use warnings;

# VERSION

use Module::Find 0.11;
our @_plugins;
BEGIN { @_plugins = sort(Module::Find::useall('App::Zapzi::Transformers')); }

use Carp;
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

=attr transformer

Name of the transformer to use. If not specified it will choose the
best option based on the content type of the raw article and set this
field.

=cut

has transformer => (is => 'rw', default => '');

=attr readable_text

Holds the readable text of the article

=cut

has readable_text => (is => 'rwp', default => '');

=attr title

Title extracted from the article

=cut

has title => (is => 'rwp', default => '');

=method to_readable

Converts L<raw_article> to readable text. Returns true if converted OK.

=cut

sub to_readable
{
    my $self = shift;

    my $module;
    for (@_plugins)
    {
        my $selected;

        $selected = $_ if $self->transformer &&
                       lc($self->transformer) eq lc($_->name);

        $selected = $_ if !$self->transformer &&
                          ($_->handles($self->raw_article->content_type));

        if ($selected)
        {
            $module = $selected->new(input => $self->raw_article);
            $self->transformer($selected->name);
            last;
        }
    }

    return unless defined $module;

    my $rc = $module->transform;
    if ($rc)
    {
        $self->_set_title($module->title);
        $self->_set_readable_text($module->readable_text);
    }

    return $rc;
}

1;
