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
$cmd  = "find $individual_dir -name \"*fastq.bz2\" "; 
$ret = `echo $cmd |  ssh ivana\@brontosaurus.tch.harvard.edu 'bash -s '`;
if (!$ret) {    
    $cmd  = "find $individual_dir -name \"*fastq.gz\" "; 
    $ret = `echo $cmd |  ssh ivana\@brontosaurus.tch.harvard.edu 'bash -s '`;
}
$ret || die "No fastqs found. Write the part of the pipeline to start from *.bam\n";

my @fastqs = ();

foreach (split '\n', $ret) {
    my @aux = split '\/';
    my $fnm = pop @aux;
    my $path = join "/", @aux;
    print "$path  $fnm \n";
    # md5sum
    $cmd = "cat $path/md5sums/$fnm.md5";
    $ret = `echo $cmd |  ssh ivana\@brontosaurus.tch.harvard.edu 'bash -s 2> /dev/null'`;
    $ret ||  die "No md5sum found for $path/$fnm\n";
    my $md5sum_bronto = $ret; chomp $md5sum_bronto;
    # downnload and check md5sum
    my $unzipped = $fnm;
    $unzipped  =~ s/\.bz2$//;
    $unzipped  =~ s/\.gz$//;
    if ( -e $unzipped && ! -z $unzipped) { 
	push @fastqs, $unzipped;
    } else {
	(-e $fnm && ! -z $fnm) || `scp ivana\@brontosaurus.tch.harvard.edu:$path/$fnm .`;
	my $md5sum_local = `md5sum $fnm | cut -d " " -f 1`; chomp $md5sum_local;
	$md5sum_bronto eq $md5sum_local || die "checksum mismatch for $fnm\n";
	print "downloaded $fnm, checksum checks\n";
	# decmpress bz2; seqmule knows how to read gz itself
	if ($fnm =~ /bz2$/) {
	    printf "unzipping $fnm\n";
	    `bzip2 -d $fnm`;
	    push @fastqs, $unzipped;
	} else {
	    push @fastqs, $fnm;
	}
    }
}
@fastqs==2 || die "Unexpected number of fastqs:\n".(join "\n",@fastqs)."\n"; 

my $logfile = "$boid.script";

if ( ! -e $logfile || `tail -n1 $logfile` !~ "finished" ) {

    my @fastqs_sorted_alphabetically =  sort { $a cmp $b}  @fastqs; # taking a leap of faith here

    my $seqmule   = "/home/ivana/third/SeqMule/bin/seqmule";
    (-e $seqmule && ! -z $seqmule) || die "$seqmule  not found";
    $cmd  = "$seqmule pipeline -N 2 -capture default -threads 4 -e ";
    $cmd .= "-prefix $boid -a $fastqs_sorted_alphabetically[0] -b $fastqs_sorted_alphabetically[1]";
    print "running:\n$cmd\n...\n";
    (system $cmd) && die "error: $!\n";
}

`tail -n1 $logfile` =~ "finished" || die "there was a problem completing\n$cmd\ncheck the logfile $boid.script\n";

chdir  "$boid\_result";
my @uploadables = split '\n', `ls *vcf`;
my $bam = `ls *realn.bam`; chomp $bam; push @uploadables, $bam;
my $bai = $bam.".bai"; ; push @uploadables, $bai;
my $vcf_path = "$individual_dir/wes/variants/called_by_seqmule_pipeline";
my $bam_path = "$individual_dir/wes/alignments/by_seqmule_pipeline";

for ($vcf_path, $bam_path ) {
    print "making path $_\n";
    $cmd = "mkdir -p $_";
    $ret = `echo $cmd |  ssh ivana\@brontosaurus.tch.harvard.edu 'bash -s 2> /dev/null'`;
    print "making path $_/md5sums\n";
    $cmd = "mkdir -p $_/md5sums";
    $ret = `echo $cmd |  ssh ivana\@brontosaurus.tch.harvard.edu 'bash -s 2> /dev/null'`;
}

foreach my $fnm (@uploadables) {
    my $md5sum_local = `md5sum $fnm | cut -d " " -f 1`; chomp $md5sum_local;
    my $path = $bam_path;
    ($fnm =~ /vcf$/)  && ($path = $vcf_path);
 
    `scp $fnm  ivana\@brontosaurus.tch.harvard.edu:$path`;
    $cmd = "\"md5sum $path/$fnm | cut -d  ' ' -f 1 > $path/md5sums/$fnm.md5\"";
    #print "echo $cmd |  ssh ivana\@brontosaurus.tch.harvard.edu 'bash -s 2> /dev/null'";
    #exit;
    $ret = `echo $cmd |  ssh ivana\@brontosaurus.tch.harvard.edu 'bash -s 2> /dev/null'`;
    # checksum local
    $cmd = "cat $path/md5sums/$fnm.md5";
    $ret = `echo $cmd |  ssh ivana\@brontosaurus.tch.harvard.edu 'bash -s 2> /dev/null'`;
    $ret ||  die "No md5sum found for $path/$fnm; it should have been calculated right now.\n";
    my $md5sum_bronto = $ret; chomp $md5sum_bronto;

    $md5sum_bronto eq $md5sum_local || die "checksum mismatch for $fnm\n";
    print "uploaded  $fnm, checksum checks\n";
    
}
