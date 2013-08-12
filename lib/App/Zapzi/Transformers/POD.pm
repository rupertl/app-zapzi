package App::Zapzi::Transformers::POD;
# ABSTRACT: transform POD to HTML

=head1 DESCRIPTION

This class takes POD and returns readable HTML using pod2html

=cut

use utf8;
use strict;
use warnings;

# VERSION

use Pod::Html;
use File::Basename;
use File::Temp ();
use File::Slurp;
use Carp;
use Moo;

extends "App::Zapzi::Transformers::HTML";

=method name

Name of transformer visible to user.

=cut

sub name
{
    return 'POD';
}

=method handles($content_type)

Returns true if this module handles the given content-type

=cut

sub handles
{
    my $self = shift;
    my $content_type = shift;

    return 1 if $content_type =~ m|text/pod|;
}

=method transform

Converts L<input> to readable text. This is done by passing the POD
through pod2html to get HTML then calling the HTML transformer.

Returns true if converted OK.

=cut

sub transform
{
    my $self = shift;

    my $tempdir = File::Temp->newdir("zapzi-pod-XXXXX", TMPDIR => 1);

    # pod2html requires files for input and output
    my $infile = "$tempdir/in.pod";
    open my $infh, '>', $infile or croak "Can't open temporary file: $!";
    print {$infh} $self->input->text;
    close $infh;

    my $outfile = "$tempdir/out.html";

    my $title = basename($self->input->source);

    # --quiet will supress warnings on missing links etc
    pod2html("$infile", "--quiet", "--cachedir=$tempdir",
             "--title=$title",
             "--infile=$infile", "--outfile=$outfile");
    croak('Could not transform POD') unless -s $outfile;

    my $html = read_file($outfile);

    return $self->SUPER::transform($html);
}

# _extract_title and _extract_text inherited from parent

1;
