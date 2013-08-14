package App::Zapzi::Articles;
# ABSTRACT: routines to access Zapzi articles

=head1 DESCRIPTION

These routines allow access to Zapzi articles via the database.

=cut

use utf8;
use strict;
use warnings;

# VERSION

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(get_articles get_article articles_summary add_article
                    move_article delete_article export_article);

use Carp;
use App::Zapzi;
use App::Zapzi::Folders qw(get_folder);

=method get_articles(folder)

Returns a resultset of articles that are in C<$folder>.

=cut

sub get_articles
{
    my ($folder) = @_;

    my $folder_rs = get_folder($folder);
    croak "Folder $folder does not exist" if ! $folder_rs;

    my $rs = _articles()->search({folder => $folder_rs->id},
                                 {prefetch => [qw(folder article_text)] });

    return $rs;
}

=method get_article(id)

Returns the resultset for the article identified by C<id>.

=cut

sub get_article
{
    my ($id) = @_;

    my $rs = _articles()->find({id => $id});
    return $rs;
}

=method articles_summary(folder)

Return a summary of articles in C<folder> as a list of articles, each
item being a hash ref with keys id, created and title.

=cut

sub articles_summary
{
    my ($folder) = @_;

    my $rs = get_articles($folder);
    my $summary = [];

    while (my $article = $rs->next)
    {
        push $summary, {id => $article->id,
                        created => $article->created,
                        title => $article->title};
    }

    return $summary;
}

=method add_article(args)

Adds a new article. C<args> is a hash that must contain

=over 4

=item * C<title> - title of the article

=item * C<folder> - name of the folder to store it in

=item * C<text> - text of the article

=back

The routine will croak if the wrong args are provided,  if the folder
does not exist or if the article can't be created in the database.

=cut

sub add_article
{
    my %args = @_;

    croak 'Must provide title and folder'
        unless $args{title} && $args{folder};

    my $folder_rs = get_folder($args{folder});
    croak "Folder $args{folder} does not exist" unless $folder_rs;

    my $new_article = _articles()->create({title => $args{title},
                                           folder => $folder_rs->id,
                                           article_text =>
                                               {text => $args{text}}});

    croak "Could not create article" unless $new_article;

    return $new_article;
}

=method move_article(id, new_folder)

Move the given article to folder C<new_folder>. Will croak if the
folder or article does not exist.

=cut

sub move_article
{
    my ($id, $new_folder) = @_;

    my $article = get_article($id);
    croak 'Article does not exist' unless $article;

    my $new_folder_rs = get_folder($new_folder);
    croak "Folder $new_folder does not exist" unless $new_folder_rs;

    if (! $article->update({folder => $new_folder_rs->id}))
    {
        croak 'Could not move article';
    }

    return 1;
}

=method delete_article(id)

Deletes article C<id> if it exists. Returns the DB result status for
the deletion.

=cut

sub delete_article
{
    my ($id) = @_;
    my $article = get_article($id);

    # Ignore if the article does not exist
    return 1 unless $article;

    return $article->delete;
}

=method export_article(id)

Returns the text of article C<id> if it exists, else undef. Text will
be wrapped in a HTML header so it can be viewed separately.

=cut

sub export_article
{
    my $id = shift;

    my $rs = get_article($id);
    return unless $rs;

    my $html = sprintf("<html><head><meta charset=\"utf-8\">\n" .
                       "<title>%s</title></head><body>%s</body></html>\n",
                       $rs->title, $rs->article_text->text);

    return $html;
}

# Convenience function to get the DBIx::Class::ResultSet object for
# this table.

sub _articles
{
    return App::Zapzi::get_app()->database->schema->resultset('Article');
}

1;
