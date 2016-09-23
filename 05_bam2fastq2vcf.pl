#!/usr/bin/perl -w

@ARGV > 1  ||
    die "Usage:  $0  <file name> <prefix> \n";
my $bamfile = $ARGV[0];
my $prefix = $ARGV[1];
my $qsort_root = $bamfile;  $qsort_root =~ s/\.bam$/.qsort/;
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

my $fq1 = $bamfile; $fq1  =~ s/\.bam$/.end1.fastq/;
my $fq2 = $bamfile; $fq2  =~ s/\.bam$/.end2.fastq/;

if (-e $fq1 && ! -z $fq1 && -e $fq2 && ! -z $fq2) {
    print "$fq1  and $fq2 files found\n";
} else {
    $cmd = "$bam2fastq -i $qsort_file -fq $fq1  -fq2 $fq2";
    print "running $cmd ...\n";
    (system $cmd) && die "error: $!\n";
}

# here checking becomse a bot more involved,
#  but then seqmule does its own checking
$cmd  = "seqmule pipeline -N 2 -capture default -threads 4 -e ";
$cmd .= " --prefix $prefix -a $fq1 -b $fq2";
print "running $cmd ...\n";
(system $cmd) && die "error: $!\n";
