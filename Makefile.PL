use inc::Module::Install;

name     'Data-SearchEngine-Solr';
all_from 'lib/Data/SearchEngine/Solr.pm';
author   q{Cory G Watson <gphat@cpan.org>};
license  'perl';

build_requires 'Test::More';

requires 'Clone';
requires 'Data::SearchEngine' => '0.17';
requires 'Moose' => '0.92';
requires 'Time::HiRes';
requires 'WebService::Solr' => '0.11';


WriteAll;

