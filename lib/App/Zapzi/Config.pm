package App::Zapzi::Config;
# ABSTRACT: routines to access Zapzi configuration

=head1 DESCRIPTION

These routines allow access to Zapzi configuration via the database.

=cut

use utf8;
use strict;
use warnings;

# VERSION

use App::Zapzi;
use Carp;

=method get(key)

Returns the value of C<key> or undef if it does not exist.

=cut

sub get
{
    my ($key) = @_;
    croak 'Key not provided' unless $key;

    my $rs = _config()->find({name => $key});
    return $rs ? $rs->value : undef;
}

=method set(key, value)

Set the config parameter C<key> to C<value>.

=cut

sub set
{
    my ($key, $value) = @_;

    croak 'Key and value need to be provided'
        unless $key && defined($value);

    if (! _config()->update_or_create({name => $key, value => $value}))
    {
        croak("Could not add $key=$value to config");
    }

    return 1;
}

=method delete(key)

Delete the config item identified by C<key>. If the key does not exist
then ignore the request.

=cut

sub delete
{
    my ($key) = @_;
    croak 'Key not provided' unless $key;

    my $rs = _config()->find({name => $key});
    return 1 unless $rs;

    return $rs->delete;
}

=method get_keys

Returns a list of keys in the config store.

=cut

sub get_keys
{
    my $rs = _config()->search(undef);

    my @keys;
    while (my $item = $rs->next)
    {
        push @keys, $item->name;
    }

    return @keys;
}

# Convenience function to get the DBIx::Class::ResultSet object for
# this table.

sub _config
{
    return App::Zapzi::get_app()->database->schema->resultset('Config');
}

1;
