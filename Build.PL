use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::SFTP',
    license             => 'perl',
    dist_author         => 'Sawyer X <xsawyerx@cpan.org>',
    dist_version_from   => 'lib/Test/SFTP.pm',
    dist_abstract       => 'An object to help test Net::SFTP',

    requires => {
        'Test::More'  => 0.78,
        'Moose'       => 0.63,
        'Net::SFTP'   => 0.10,
    },

    build_requires => {
        'Test::More'  => 0.78,
        'IO::Prompt'  => '0.99.4',
        'English'     => 1.02,
    },

    recommends => {
        'Test::Timer' => 0.05,
        'File::Util'  => 3.27,
    },

    add_to_cleanup     => [ 'Test-SFTP-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
