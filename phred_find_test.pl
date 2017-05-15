#!/usr/bin/perl -w

use strict;
use lib  '/home/ivana/pypeworks/variants';

use warnings FATAL => 'all';
use variant_utils_pl::find_phred qw(find_phred);

(@ARGV==1) || die "Usage:  $0  <filename file>/all  \n";

my @filenames = ();
if ($ARGV[0] eq "all") {
    foreach my $dir ("/data01", "/data02") {
        my @allfiles = split "\n", `find $dir  -name "*consensus.vcf"`;
        foreach my $file (@allfiles) {
            my $annotated = $file;
            $annotated =~ s/vcf$/annotated.vcf/;
            if ( -e $annotated && ! -z  $annotated ) {
                printf "$annotated found \n";
            } else {
                printf "adding $annotated\n";
                push @filenames, $file;
            }
        }
    }
} else {
    @filenames = split "\n", `cat  $ARGV[0]`;
}

foreach my $filename ( @filenames) {
    print " ***** running $filename  .... \n";
    find_phred($filename);
}
