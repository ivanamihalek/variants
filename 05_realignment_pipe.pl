#!/usr/bin/perl -w
use strict;
use lib  '/home/ivana/pypeworks/variants';
use variant_utils_pl::bam2fastq2vcf qw(bam2fastq2vcf);
use variant_utils_pl::migrate_to_bronto  qw(migrate_to_bronto);


@ARGV ==3  || die "Usage: $0 <year> <case number> <individual>\n";

my ($year, $caseno, $individual) = @ARGV;

my $homedir = "";
for my $dir  ( '/data01', 'data02') {
    my $cmd = 'ls $dir';
    my $ret = `echo $cmd |  ssh ivana\@brontosaurus.tch.harvard.edu 'bash -s '`; chomp $ret;

    foreach (split '\n', $ret) {
	/$year/ || next;
	$homedir = $dir;
    }
}

$homedir || die "home dir not found for the year $year\n";
#my $boid = "BO". (substr $year, 2,2) . $caseno. $individual;
my $casedir = "$homedir/$year/$caseno";
my $cmd     = 'ls $casedir'; 
my $ret = `echo $cmd |  ssh ivana\@brontosaurus.tch.harvard.edu 'bash -s '`; chomp $ret;
print "$ret \n";
