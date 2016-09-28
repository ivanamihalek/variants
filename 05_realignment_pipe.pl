#!/usr/bin/perl -w
use strict;
use lib  '/home/ivana/pypeworks/variants';
use variant_utils_pl::bam2fastq2vcf qw(bam2fastq2vcf);
use variant_utils_pl::migrate_to_bronto  qw(migrate_to_bronto);


@ARGV > 2 || die "Usage: $0 <year> <case number>\n";

my ($year, $caseno) = @ARGV;

for my  $cmd  ( 'ls /data01', 'ls /data02') {
    my $ret = `echo $cmd |  ssh ivana\@brontosaurus.tch.harvard.edu 'bash -s '`;

    foreach (split "\n", $ret) {
	print "$ret\n";
    }

}
