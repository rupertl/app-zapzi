package App::Zapzi::Fetchers::URL;
# ABSTRACT: fetch article via URL

=head1 DESCRIPTION

This class downloads an article over HTTP via the given URL.

=cut

use utf8;
use strict;
use warnings;

# VERSION

use Carp;
use Data::Validate::URI 0.06;
use HTTP::Tiny;
use HTTP::CookieJar;
use Moo;

with 'App::Zapzi::Roles::Fetcher';

=method name

Name of transformer visible to user.

=cut

sub name
{
    return 'URL';
}

=method handles($content_type)

Returns a validated URL if this module handles the given content-type

=cut

sub handles
{
    my $self = shift;
    my $source = shift;

    my $v = Data::Validate::URI->new();
    my $url = $v->is_web_uri($source) || $v->is_web_uri('http://' . $source);
    return $url;
}

=method fetch

Downloads an article

=cut

sub fetch
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

    return {headers => {
                           'User-agent' => $ua,
                           # Don't gzip encode the response
                           'Accept-encoding' => 'identity'
                       }};
}

1;
