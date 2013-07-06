package App::Zapzi::Database::Schema;
# VERSION
# ABSTRACT: database schema for zapzi

use utf8;
use strict;
use warnings;

use base 'DBIx::Class::Schema';

# Load Result classes under this schema
__PACKAGE__->load_classes(qw/Article ArticleText Folder/);

1;
