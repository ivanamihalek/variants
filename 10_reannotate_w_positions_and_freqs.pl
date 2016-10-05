#!/usr/bin/perl -w
use strict;
use lib  '/home/ivana/pypeworks/variants';
use variant_utils_pl::generic qw(strip_vcf);
use variant_utils_pl::annovar qw(annovar);
use variant_utils_pl::vcfanno  qw(vcfanno);

@ARGV==1 || die "Usage:  $0  <filename file>  \n";
my @filenames = split "\n", `cat  $ARGV[0]`;

foreach my $filename ( @filenames) {
    my $stripped_filename  = strip_vcf($filename);
    my $annovar_filename   = annovar ($stripped_filename);
    my $annotated_filename = vcfanno  ($annovar_filename);
    `rm  $stripped_filename $annovar_filename `;
    printf "\nfinal annotated file: $annotated_filename\n\n";
}
