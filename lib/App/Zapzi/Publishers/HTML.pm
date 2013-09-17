package App::Zapzi::Publishers::HTML;
# ABSTRACT: publishes articles to a HTML file

=head1 DESCRIPTION

This class creates a single HTML file from a collection of articles.

=cut

use utf8;
use strict;
use warnings;

# VERSION

use Carp;
use File::Slurp;
use Moo;
use App::Zapzi;

with 'App::Zapzi::Roles::Publisher';

=attr file

Returns the output file handle created.

=cut

has file => (is => 'rwp');

=method name

Name of publisher visible to user.

=cut

sub name
{
    return 'HTML';
}

=head2 start_publication($folder, $encoding)

Starts a new publication for the given folder in the given encoding.

=cut

sub start_publication
{
    my $self = shift;

    $self->_set_encoding('UTF-8') unless $self->encoding;

    open my $file, '>', $self->filename
            or croak "Can't open output HTML file: $!\n";

    my $html = sprintf("<html><head><meta charset=\"%s\">\n" .
                       "<title>%s</title></head><body>\n",
                       $self->encoding, $self->collection_title);
    print {$file} $html;

    $self->_set_file($file);
}

=head2 add_article($article, $index)

Adds an article, sequence number index,  to the publication.

=cut

sub add_article
{
    my $self = shift;
    my ($article, $index) = @_;

    print {$self->file} "\n<hr>\n" unless $index == 0;
    print {$self->file} $article->{encoded_title};
    print {$self->file} $article->{encoded_text};
}

=head2 finish_publication()

Finishes publication and returns the filename created.

=cut

sub finish_publication
{
    my $self = shift;

    print {$self->file} "</body></html>\n";
    close $self->file;

    $self->_set_collection_data(scalar read_file($self->filename));

    return $self->filename;
}

1;
