#!/usr/bin/perl -w
use strict;
use lib  '/home/ivana/pypeworks/variants';
use variant_utils_pl::generic qw(strip_vcf);
use variant_utils_pl::annovar qw(annovar);
use variant_utils_pl::vcfanno  qw(vcfanno);

@ARGV ||
    die "Usage:  $0  <file name> [<file name 2> ...] \n";
my @filenames = @ARGV;

foreach my $filename ( @filenames) {
    my $stripped_filename  = strip_vcf($filename);
    my $annovar_filename   = annovar ($stripped_filename);
    my $annotated_filename = vcfanno  ($annovar_filename);

    printf "\nfinal annotated file: $annotated_filename\n\n";
}
