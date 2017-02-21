#!/usr/bin/perl -w
use strict;
use lib  '/home/ivana/pypeworks/variants';
use warnings FATAL => 'all';
use variant_utils_pl::generic qw(strip_vcf);
use variant_utils_pl::annovar qw(annovar);
use variant_utils_pl::vcfanno  qw(vcfanno);

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
    my $stripped_filename  = strip_vcf($filename);
    my $annovar_filename   = annovar ($stripped_filename);
    my $annotated_filename = vcfanno  ($annovar_filename);
    `rm  $stripped_filename $annovar_filename `;
    printf "\nfinal annotated file: $annotated_filename\n\n";
}
