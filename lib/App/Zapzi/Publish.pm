package App::Zapzi::Publish;
# ABSTRACT: create eBooks from Zapzi articles

=head1 DESCRIPTION

This class takes a collection of cleaned up HTML articles and creates
eBooks. It will find the best publisher module that matches the
required publication type.

=cut

use utf8;
use strict;
use warnings;

# VERSION

use Module::Find 0.11;
our @_plugins;
BEGIN { @_plugins = sort(Module::Find::useall('App::Zapzi::Publishers')); }

use App::Zapzi;
use Carp;
use DateTime;
use Encode;
use HTML::Entities;
use Moo;

=attr format

Format to publish eBook in.

=cut

has format => (is => 'ro', default => 'MOBI');

=attr folder

Folder of articles to publish.

=cut

has folder => (is => 'ro', required => 1);

=attr encoding

Encoding to use when publishing. Options are ISO-8859-1 and UTF-8,
default depends on the publisher.

=cut

has encoding => (is => 'ro', required => 0);

=attr archive_folder

Folder to move articles to after publication - undef means don't move.

=cut

has archive_folder => (is => 'ro', required => 0, default => 'Archive');

=attr filename

Returns the file that the published ebook is stored in.

=cut

has filename => (is => 'rwp');

=attr collection_data

Returns the raw data (eg combined HTML) produced by the publisher -
for testing.

=cut

has collection_data => (is => 'rwp');

=method publish

Publish an eBook in the specified format to the ebook directory. Returns the
size of the eBook or 0 on failure.

=cut

sub publish
{
    my $self = shift;

    return unless ! $self->encoding
        || $self->encoding =~ /utf-8/i
        || $self->encoding =~ /iso-8859-1/i;

    my $module = $self->_find_module();
    return unless defined $module;

    $module->start_publication($self->folder, $self->encoding);

    my $index = 0;
    for my $article (@{App::Zapzi::Articles::articles_summary($self->folder)})
    {
        $article->{encoded_text} =
            $self->_encode_text($article->{text}, $module->encoding);
        $article->{encoded_title} =
            "<h1>" . HTML::Entities::encode($article->{title}) . "</h1>\n";

        $module->add_article($article, $index++);
        $self->_archive_article($article);
    }

    $self->_set_filename($module->finish_publication());
    $self->_set_collection_data($module->collection_data);

    return -s $self->filename;
}

sub _find_module
{
    my $self = shift;

    for (@_plugins)
    {
        if (lc($self->format) eq lc($_->name))
        {
            my $title = $self->_get_title();
            $self->_make_filename($title, lc($_->name));

            return $_->new(folder => $self->folder,
                           encoding => $self->encoding,
                           collection_title => $title,
                           filename => $self->filename);
        }
    }

    return;
}

sub _get_title
{
    my $self = shift;

    my $dt = DateTime->now;
    return sprintf("%s - %s", $self->folder, $dt->strftime('%d-%b-%Y'));
}

sub _make_filename
{
    my $self = shift;
    my ($title, $extension) = @_;
    my $app = App::Zapzi::get_app();

    my $base = sprintf("Zapzi - %s.%s", $title, $extension);

    $self->_set_filename($app->zapzi_ebook_dir . "/" . $base);
}


sub _encode_text
{
    my $self = shift;
    my ($text, $encoding) = @_;

    if ($encoding =~ /utf-8/i)
    {
        return encode_utf8($text);
    }
    elsif ($encoding =~ /iso-8859-1/i)
    {
        # Transform chars outside the ISO-8859 range into HTML entities
        no warnings 'utf8';     # for warning on range below in perl 5.10
        my $encode_high = encode_entities($text,
                                          "[\x{FF}-\x{10FFFF}]");
        return encode("iso-8859-1", $encode_high);
    }
    else
    {
        croak("Unsupported encoding");
    }
}

sub _archive_article
{
    my $self = shift;
    my ($article) = @_;

    if (defined($self->archive_folder) && $self->folder ne 'Archive')
    {
        App::Zapzi::Articles::move_article($article->{id},
                                           $self->archive_folder);
    }
}

1;
