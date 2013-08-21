package App::Zapzi::Database::Schema;
# ABSTRACT: database schema for zapzi

use utf8;
use strict;
use warnings;

# VERSION

use base 'DBIx::Class::Schema';

# Load Result classes under this schema
__PACKAGE__->load_classes(qw/Article ArticleText Config Folder/);

=method schema_version

The version of the database schema that the code expects

=cut

sub schema_version
{
    return 2;
}

1;
