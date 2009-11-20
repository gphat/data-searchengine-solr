package Data::SearchEngine::Solr;
use Moose;

use WebService::Solr;
use Data::SearchEngine::Item;
use Data::SearchEngine::Results;
use Time::HiRes qw(time);

with 'Data::SearchEngine';

our $VERSION = '0.01';

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

    my $start = time;
    my $resp = $self->_solr->search($query->query, $options);

    my $result = Data::SearchEngine::Results->new(
        query => $query,
        pager => $resp->pager,
        elapsed => time - $start
    );

    use Data::Dumper;
    print STDERR Dumper($resp->content);

    print STDERR Dumper($resp->facet_counts);

    my $facets = $resp->facet_counts;
    if(exists($facets->{facet_fields})) {
        foreach my $facet (keys %{ $facets->{facet_fields} }) {
            print STDERR "#### $facet\n";
            print STDERR Dumper($facets->{facet_fields}->{$facet});
            $result->set_facet($facet, $facets->{facet_fields}->{$facet});
        }
    }
    if(exists($facets->{facet_queries})) {
        foreach my $facet (keys %{ $facets->{facet_queries} }) {
            $result->set_facet($facet, $facets->{facet_queries}->{$facet});
        }
    }

    print STDERR Dumper($result->facets);

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

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Data::SearchEngine::Solr;

    my $foo = Data::SearchEngine::Solr->new();
    ...

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-searchengine-solr at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-SearchEngine-Solr>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::SearchEngine::Solr


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-SearchEngine-Solr>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-SearchEngine-Solr>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-SearchEngine-Solr>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-SearchEngine-Solr/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Cory G Watson.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
