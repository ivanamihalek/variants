#!/usr/bin/perl -w
use strict;
use lib  '/home/ivana/pypeworks/variants';
use variant_utils_pl::generic qw(strip_vcf);
use variant_utils_pl::jannovar qw(jannovar);

@ARGV ||
    die "Usage:  $0  <file name> \n";
my $filename = $ARGV[0];


my $stripped_filename = strip_vcf($filename);
my $jannovar_filename  = jannovar($filename);
