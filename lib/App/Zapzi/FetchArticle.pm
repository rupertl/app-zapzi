package App::Zapzi::FetchArticle;
# ABSTRACT: routines to get articles for Zapzi

=head1 DESCRIPTION

These routines get articles, either via HTTP or from the file system
and returns the raw HTML or text.

This interface is temporary to get the initial version of Zapzi
working and will be replaced with a more flexible role based system
later.

=cut

use utf8;
use strict;
use warnings;

# VERSION

use Carp;
use App::Zapzi;
use Moo;
use HTTP::Tiny;
use HTTP::CookieJar;
use File::MMagic 1.30;

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

    return -e $self->source ? $self->_fetch_file : $self->_fetch_url;
}

sub _fetch_file
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

    my $mm = new File::MMagic;
    $self->_set_content_type($mm->checktype_contents($self->text) 
                             // 'text/plain');

    return 1;
}

sub _fetch_url
{
    my $self = shift;

    my $jar = HTTP::CookieJar->new;
    my $http = HTTP::Tiny->new(cookie_jar => $jar);

    my $url = $self->source;
    my $response = $http->get($url, $self->_http_request_headers());

    if (! $response->{success} || ! length($response->{content}))
    {
        my $error = "Failed to fetch $url: ";
        if ($response->{status} == 599)
        {
            # Internal exception to HTTP::Tiny
            $error .= $response->{content};
        }
        else
        {
            # Error details from remote server
            $error .= $response->{status} . " ";
            $error .= $response->{reason};
        }
        $self->_set_error($error);
        return;
    }

    $self->_set_text($response->{content});
    $self->_set_content_type($response->{headers}->{'content-type'});

    return 1;
}

sub _http_request_headers
{
    my $self = shift;

    my $ua = "App::Zapzi";

    no strict 'vars'; ## no critic - $VERSION does not exist in dev
    $ua .= "/$VERSION" if defined $VERSION;

    return {headers => {'User-agent' => $ua}};
}

1;
