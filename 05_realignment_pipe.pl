#!/usr/bin/perl -w
use strict;
use lib  '/home/ivana/pypeworks/variants';
use variant_utils_pl::bam2fastq2vcf qw(bam2fastq2vcf);
use variant_utils_pl::migrate_to_bronto  qw(migrate_to_bronto);


@ARGV ==3  || die "Usage: $0 <year> <case number> <individual>\n";

my ($year, $caseno, $individual) = @ARGV;

my $homedir = "";
for my $dir  ( '/data01', '/data02') {
    my $cmd = "ls $dir";
    my $ret = `echo $cmd |  ssh ivana\@brontosaurus.tch.harvard.edu 'bash -s '`; chomp $ret;

    foreach (split '\n', $ret) {
	/$year/ || next;
	$homedir = $dir;
    }
}

$homedir || die "home dir not found for the year $year\n";
my $casedir = "$homedir/$year/$caseno";
my $cmd     = "ls -d $casedir"; 
my $ret = `echo $cmd |  ssh ivana\@brontosaurus.tch.harvard.edu 'bash -s '`; chomp $ret;
$ret eq $casedir || die "$casedir not found\n";

my $boid = "BO". (substr $year, 2,2) . $caseno. $individual;
my $individual_dir = "$casedir/$boid";
$cmd  = "ls -d $individual_dir"; 
$ret = `echo $cmd |  ssh ivana\@brontosaurus.tch.harvard.edu 'bash -s '`; chomp $ret;
$ret eq $individual_dir || die "$individual_dir  not found\n";

# find fastq - if we have fastq we start from there
$cmd  = "find $individual_dir -name \"*fastq*\" "; 
$ret = `echo $cmd |  ssh ivana\@brontosaurus.tch.harvard.edu 'bash -s '`;
$ret || die "No fastqs found. Write the part of the pipeline to start from *.bam\n";

foreach (split '\n', $ret) {
    my @aux = split '\/';
    my $fnm = pop @aux;
    my $path = join "/", @aux;
    print " $path  $fnm \n";
}
