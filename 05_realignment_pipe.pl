#!/usr/bin/perl -w
use strict;
use lib  '/home/ivana/pypeworks/variants';
use variant_utils_pl::bam2fastq2vcf qw(bam2fastq2vcf);
use variant_utils_pl::migrate_to_bronto  qw(migrate_to_bronto);


@ARGV ==3  || die "Usage: $0 <year> <case number> <individual>\n";

my ($year, $caseno, $individual) = @ARGV;

for my  $cmd  ( 'ls /data01', 'ls /data02') {
    my $ret = `echo $cmd |  ssh ivana\@brontosaurus.tch.harvard.edu 'bash -s '`; chomp $ret;

    foreach (split '\n', $ret) {
	print "$_\n";
    }

}
