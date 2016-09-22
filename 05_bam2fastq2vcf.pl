#!/usr/bin/perl -w

@ARGV ||
    die "Usage:  $0  <file name> \n";
my $bamfile = $ARGV[0];
my $qsort = $bamfile;
$qsort =~ s/\.bam$/.qsort$/;
die "$bamfile  $qsort\n";

############
$samtools  = "/home/ivana/third/SeqMule/exe/samtools/samtools";
$bam2fastq = "/home/ivana/third/bedtools2/bin/bamToFastq";
$seqmule   = "/home/ivana/third/SeqMule/bin/seqmule";

foreach ($samtools, $bam2fastq, $seqmule) {
    -e $_ || die "$_ not found\n";
}

$cmd = "$samtools sort -n ";
