#!/usr/bin/perl -w

@ARGV ||
    die "Usage:  $0  <file name> \n";
my @filename = $ARGV[0];

############
$samtools  = "/home/ivana/third/SeqMule/exe/samtools/samtools";
$bam2fastq = "/home/ivana/third/bedtools2/bin/bamToFastq";
$seqmule   = "/home/ivana/third/SeqMule/bin/seqmule";

foreach ($samtools, $bam2fastq, $seqmule) {
    -e $_ || die "$_ not found\n";
}
