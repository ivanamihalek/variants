#!/usr/bin/perl -w
use strict;
use lib  '/home/ivana/pypeworks/variants';
use variant_utils_pl::generic qw(strip_vcf);
use variant_utils_pl::jannovar qw(jannovar);
use variant_utils_pl::vcfanno  qw(vcfanno);

@ARGV ||
    die "Usage:  $0  <file name> \n";
my $filename = $ARGV[0];


my $stripped_filename  = strip_vcf($filename);
my $jannovar_filename  = jannovar ($stripped_filename);
my $annotated_filename = vcfanno  ($jannovar_filename);

printf "final annptated file: $annotated_filename\n";
