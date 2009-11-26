package Data::SearchEngine::Solr::Results;
use Moose;

extends 'Data::SearchEngine::Results';

with 'Data::SearchEngine::Results::Faceted';

1;