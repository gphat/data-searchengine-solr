use inc::Module::Install;

name     'Data-SearchEngine-Solr';
all_from 'lib/Data/SearchEngine/Solr.pm';
author   q{Cory G Watson <gphat@cpan.org>};
license  'perl';

build_requires 'Test::More';

requires 'WebService::Solr' => '0.08';
requires 'Time::HiRes';
requires 'Moose' => '0.92';
requires 'Data::SearchEngine' => '0.07';

WriteAll;

