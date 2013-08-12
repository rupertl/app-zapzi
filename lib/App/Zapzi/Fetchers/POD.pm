package App::Zapzi::Fetchers::POD;
# ABSTRACT: fetch article from a named POD module

=head1 DESCRIPTION

This class reads POD from a given module name, eg 'Foo::Bar'

=cut

use utf8;
use strict;
use warnings;

# VERSION

use Carp;
use File::Slurp;
use Pod::Find;
use Moo;

with 'App::Zapzi::Roles::Fetcher';

=method name

Name of transformer visible to user.

=cut

sub name
{
    return 'POD';
}

=method handles($content_type)

Returns a valid filenam if this module handles the given content-type.
For POD this means it will search C<@INC> for a matching file.

=cut

sub handles
{
    my $self = shift;
    my $source = shift;

    return Pod::Find::pod_where({ -inc => 1 }, $source);
}

=method fetch

Reads the POD file into the application.

=cut

sub fetch
{
    my $self = shift;

    my $pod = read_file($self->source);
    $self->_set_text($pod);

    $self->_set_content_type('text/pod');

    return 1;
}

1;
