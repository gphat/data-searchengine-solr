package Data::SearchEngine::Solr;
use Moose;

use WebService::Solr;
use Data::SearchEngine::Item;
use Data::SearchEngine::Results;
use Time::HiRes qw(time);

with 'Data::SearchEngine';

our $VERSION = '0.03';

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

    my $result = Data::SearchEngine::Results->new(
        query => $query,
        pager => $resp->pager,
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

Data::SearchEngine::Solr is a Data::SearcEngine backend for the Solr
search server.

=head1 WARNING

This module is under active development is changing quickly.  Patches welcome!

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Cory G Watson.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
