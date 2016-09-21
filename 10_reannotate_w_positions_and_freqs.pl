#!/usr/bin/perl -w
use variant_utils_pl::generic qw(strip_vcf);
use strict;

@ARGV ||
    die "Usage:  $0  <file name> \n";
my $filename = $ARGV[0];

strip_vcf($filename);

