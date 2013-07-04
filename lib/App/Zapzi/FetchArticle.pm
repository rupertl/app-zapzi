use utf8;
use strict;
use warnings;

package App::Zapzi::FetchArticle;
# VERSION
# ABSTRACT: routines to get articles for Zapzi

=head1 SYNOPSIS

These routines get articles, either via HTTP or from the file system
and returns the raw HTML or text.

This interface is temporary to get the initial version of Zapzi
working and will be replaced with a more flexible role based system
later.

=cut

use Carp;
use App::Zapzi;
use Moo;
use HTTP::Tiny;
use HTTP::CookieJar;

=attr source

Pass in the source of the article - either a filename or a URL.

=cut

has source => (is => 'ro', default => '');

=attr text

Holds the raw text of the article

=cut

has text => (is => 'ro', default => '');

=attr error

Holds details of any errors encountered while retrieving the article;
will be blank if no errors.

=cut

has error => (is => 'ro', default => '');

=method fetch

Retrieves the article and returns 1 if OK. Text of the article can
then be found in L<text>.

=cut

sub fetch
{
    my $self = shift;

    if (-e $self->source)
    {
        return $self->_fetch_file;
    }
    else
    {
        return $self->_fetch_url;
    }

    return 1;
}

sub _fetch_file
{
    my $self = shift;
    
    my $file;
    if (! open $file, '<', $self->source)
    {
        $self->error = "Failed to open " . $self->source . ": $!";
        return;
    }
    
    while (<$file>)
    {
        $self->text .= $_;
    }

    close $file;
    return 1;
}

sub _fetch_url
{
    my $self = shift;

    my $jar = HTTP::CookieJar->new;
    my $http = HTTP::Tiny->new(cookie_jar => $jar);

    my $url = $self->source;
    my $response = $http->get($url);

    if (! $response->{success} || ! length($response->{content}))
    {
        $self->error = "Failed to fetch $url: ";
        if ($response->{status} == 599)
        {
            # Internal exception to HTTP::Tiny
            $self->error .= $response->{content};
        }
        else
        {
            # Error details from remote server
            $self->error .= $response->{status} . " ";
            $self->error .= $response->{reason};
        }
        return;
    }

    $self->text = $response->{content};
    return 1;
}

1;
