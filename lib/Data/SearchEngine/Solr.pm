package Data::SearchEngine::Solr;
use Moose;

use Data::SearchEngine::Paginator;
use Data::SearchEngine::Item;
use Data::SearchEngine::Solr::Results;
use Time::HiRes qw(time);
use WebService::Solr;

with 'Data::SearchEngine';

our $VERSION = '0.05';

has options => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { {
        wt => 'json',
        fl => '*,score',
    } }
);

has 'url' => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

has '_solr' => (
    is => 'ro',
    isa => 'WebService::Solr',
    lazy_build => 1
);

sub _build__solr {
    my ($self) = @_;

    return WebService::Solr->new($self->url);
}

sub search {
    my ($self, $query) = @_;

    my $options = $self->options;

    $options->{rows} = $query->count;
    # page?

    if($query->has_filters) {
        $options->{fq} = [];
        foreach my $filter (keys %{ $query->filters }) {
            push(@{ $options->{fq} }, $query->get_filter($filter));
        }
    }

    if($query->has_order) {
        $options->{sort} = $query->order;
    }

    if($query->page > 1) {
        $options->{start} = ($query->page - 1) * $query->count;
    }

    my $start = time;
    my $resp = $self->_solr->search($query->query, $options);

    my $dpager = $resp->pager;
    my $pager = Data::SearchEngine::Paginator->new(
        current_page => $dpager->current_page,
        entries_per_page => $dpager->entries_per_page,
        total_entries => $dpager->total_entries
    );

    my $result = Data::SearchEngine::Solr::Results->new(
        query => $query,
        pager => $pager,
        elapsed => time - $start
    );

    my $facets = $resp->facet_counts;
    if(exists($facets->{facet_fields})) {
        foreach my $facet (keys %{ $facets->{facet_fields} }) {
            $result->set_facet($facet, $facets->{facet_fields}->{$facet});
        }
    }
    if(exists($facets->{facet_queries})) {
        foreach my $facet (keys %{ $facets->{facet_queries} }) {
            $result->set_facet($facet, $facets->{facet_queries}->{$facet});
        }
    }

    foreach my $doc ($resp->docs) {

        my %values;
        foreach my $f ($doc->fields) {
            $values{$f->name} = $f->value;
        }

        $result->add(Data::SearchEngine::Item->new(
            id      => $doc->value_for('id'),
            values  => \%values,
        ));
    }

    return $result;
}

1;

__END__

=head1 NAME

Data::SearchEngine::Solr - Data::SearchEngine backend for Solr

=head1 SYNOPSIS

  my $solr = Data::SearchEngine::Solr->new(
    url => 'http://localhost:8983/solr',
    options => {
        fq => 'category:Foo',
        facets => 'true'
    }
  );

  my $query = Data::SearchEngine::Query->new(
    count => 10,
    page => 1,
    query => 'ice cream',
  );

  my $results = $solr->search($query);

  foreach my $item ($results->items) {
    print $item->get_value('name')."\n";
  }

=head1 DESCRIPTION

Data::SearchEngine::Solr is a L<Data::SearcEngine> backend for the Solr
search server.

=head1 SOLR FEATURES

=head2 FILTERS

This module uses the values from Data::SearchEngine::Query's C<filters> to
populate the C<fq> parameter.  Before talking to Solr we iterate over the
filters and add the filter's value to C<fq>.

  $query->filters->{'last name watson'} = 'last_name:watson';

Will results in fq=name:watson.  Multiple filters will be appended.

=head2 FACETS

Facets may be enabled thusly:

  $solr->options->{facets} = 'true';
  $solr->options->{facet.field} = 'somefield';

You may also use other C<facet.*> parameters, as defined by Solr.

To access facet data, consult the documentation for
L<Data::SearchEngine::Results> and it's C<facets> method.

=head1 ATTRIBUTES

=head2 options

HashRef that is passed to L<WebService::Solr>.  Please see the above
documentation on filters and facets before using this directly.

=head2 url

The URL at which to contact the Solr instance.

=head1 METHODS

=head2 search ($query)

Accepts a L<Data::SearchEngine::Query> and returns a
L<Data::SearchEngine::Results> object containing the data from Solr.

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Cory G Watson.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
