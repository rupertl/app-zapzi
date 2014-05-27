package App::Zapzi::Distributors::Email;
# ABSTRACT: distribute a published eBook by sending an email

=head1 DESCRIPTION

This class sends an email with the completed eBook as an attachment.
The destination is used as the recipient and sender address. Transport
options can be overriden as per Email::Sender options.

=cut

use utf8;
use strict;
use warnings;

# VERSION

use App::Zapzi;
use Carp;
use Email::MIME 1.924;
use Email::Sender::Simple 1.300006 qw(sendmail);
use Email::Simple::Creator;
use Email::Simple;
use Path::Tiny;
use IO::All;
use Moo;
use Try::Tiny;

with 'App::Zapzi::Roles::Distributor';

=method name

Name of distributor visible to user.

=cut

sub name
{
    return 'Email';
}

=head2 distribute

Distribute the file. Returns 1 if OK, undef if failed.

=cut

sub distribute
{
    my $self = shift;

    unless ($self->destination)
    {
        $self->_set_completion_message("Email recipient does not exist");
        return 0;
    }

    my $email = $self->_create_message();

    try
    {
        sendmail($email);
        $self->_set_completion_message("Emailed to " . $self->destination);
        return 1;
    }
    catch
    {
        my $message = (split /\n/, $_)[0] // "unknown error";
        $self->_set_completion_message($message);
        return;
    };
}

sub _create_message
{
    my $self = shift;
    my $base = path($self->file)->basename;

    my @parts =
    (
        Email::MIME->create(
            attributes =>
            {
                content_type  => "text/plain",
            },
            body => 'Zapzi published eBook attached.',
        ),
        Email::MIME->create
        (
            attributes =>
            {
                filename      => $base,
                content_type  => "application/octet-stream",
                encoding      => "base64",
                disposition   => "attachment",
                Name          => $base
            },
            body => io( $self->file )->all,
        ),
    );

    my $message = Email::MIME->create
    (
        header =>
        [
            To      => $self->destination,
            From    => $ENV{EMAIL_SENDER_TRANSPORT_from} // $self->destination,
            Subject => "Zapzi distributed ebook",
            content_type   => 'multipart/mixed'
        ],
        parts  => [ @parts ],
    );

    return $message;
}

1;
