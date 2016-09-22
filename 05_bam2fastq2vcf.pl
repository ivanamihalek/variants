#!/usr/bin/perl -w

@ARGV ||
    die "Usage:  $0  <file name> \n";
my $bamfile = $ARGV[0];
my $qsort_root = $bamfile;
$qsort_root =~ s/\.bam$/.qsort/;
my $qsort_file = $qsort_root.".bam";

############
$samtools  = "/home/ivana/third/SeqMule/exe/samtools/samtools";
$bam2fastq = "/home/ivana/third/bedtools2/bin/bamToFastq";
$seqmule   = "/home/ivana/third/SeqMule/bin/seqmule";

foreach ($samtools, $bam2fastq, $seqmule) {
    -e $_ || die "$_ not found\n";
}

if (-e $qsort_file and ! -z $qsort_file ) {
    print "$qsort_file found.\n"
} else {
    $cmd = "$samtools sort -n $bamfile $qsort_root";
    print "running $cmd ...\n";
    (system $cmd) && die "error: $!\n";
}
