#!/usr/bin/perl -w
use strict;
use lib  '/home/ivana/pypeworks/variants';
use warnings;
use variant_utils_pl::bam2fastq2vcf qw(bam2fastq2vcf);
use variant_utils_pl::migrate_to_bronto  qw(migrate_to_bronto);

sub find_fastqs;
sub fastqs_from_bam;
sub bam_from_bronto;

@ARGV ==3  || die "Usage: $0 <year> <case number> <individual>\n";

my ($year, $caseno, $individual) = @ARGV;

##########################################
# check we have all the tools needed
my $samtools  = "/home/ivana/third/SeqMule/exe/samtools/samtools";
my $bam2fastq = "/home/ivana/third/bedtools2/bin/bamToFastq";
my $seqmule   = "/home/ivana/third/SeqMule/bin/seqmule";
my $bam_from_dropbox = "/home/ivana/pypeworks/variants/05_bam_from_dropbox.py";
foreach ($samtools, $bam2fastq, $seqmule, $bam_from_dropbox) {
    -e $_ && ! -z $_ || die "$_ not found\n";
}

##########################################
# find the directory on bronto
my $homedir = "";
for my $dir  ( '/data01', '/data02') {
    my $cmd = "ls $dir";
    my $ret = `echo $cmd |  ssh ivana\@brontosaurus.tch.harvard.edu 'bash -s '`; chomp $ret;

    foreach (split '\n', $ret) {
        /$year/ || next;
        $homedir = $dir;
    }
}
$homedir || die "home dir not found on bronto for the year $year\n";

my $casedir = "$homedir/$year/$caseno";
my $cmd     = "ls -d $casedir";
my $ret = `echo $cmd |  ssh ivana\@brontosaurus.tch.harvard.edu 'bash -s '`; chomp $ret;
$ret eq $casedir || die "$casedir not found on bronto\n";

my $boid = "BO". (substr $year, 2,2) . $caseno. $individual;
my $individual_dir = "$casedir/$boid";
$cmd  = "ls -d $individual_dir";
$ret = `echo $cmd |  ssh ivana\@brontosaurus.tch.harvard.edu 'bash -s '`; chomp $ret;
$ret eq $individual_dir || die "$individual_dir  not found on bronto\n";


my $vcf_path = "$individual_dir/wes/variants/called_by_seqmule_pipeline";
my $bam_path = "$individual_dir/wes/alignments/by_seqmule_pipeline";
# do we have something in here, by any chance?
$cmd  = "ls -d $bam_path";
$ret = `echo $cmd |  ssh ivana\@brontosaurus.tch.harvard.edu 'bash -s '`; chomp $ret;

if ($ret eq $bam_path) {
    # bam directory found - does it contain anything?
    $cmd  = "ls -f $bam_path/*bam";
    $ret  = `ssh ivana\@brontosaurus.tch.harvard.edu "bash -s $cmd 2> /dev/null"`; chomp $ret;
    foreach (split '\n', $ret) {
        /.bam$/ || next;
        print $ret, " found on bronto \n";
        exit (0);
    }
}

# also check on Dropbox
my $bamfile = `$bam_from_dropbox seqmule $boid nodwld`;
chomp $bamfile;
if ($bamfile =~ /.bam$/) {
    print $bamfile, " found in Dropbox\n";
    exit (0);
}
exit;


##########################################
# check if the parts of the pipeline have already completed
my $logfile = "$boid.script";

if ( ! -e $logfile || `tail -n1 $logfile` !~ "finished" ) {
    my @fastqs =  find_fastqs;
    @fastqs || (@fastqs =  fastqs_from_bam);
    @fastqs || die "I could not locate neither fastq nor the bam file(s). Bailing out.\n";
    my @fastqs_sorted_alphabetically =  sort { $a cmp $b}  @fastqs; # taking a leap of faith here

    $cmd  = "$seqmule pipeline -N 2 -capture default -threads 4 -e ";
    $cmd .= "-prefix $boid -a $fastqs_sorted_alphabetically[0] -b $fastqs_sorted_alphabetically[1]";
    print "running:\n$cmd\n...\n";
    (system $cmd) && die "error: $!\n";
}

`tail -n1 $logfile` =~ "finished" || die "there was a problem completing\n$cmd\ncheck the logfile $boid.script\n";

##########################################
# create paths on bronto
chdir  "$boid\_result";
my @uploadables = split '\n', `ls *vcf`;
my $bam = `ls *realn.bam`; chomp $bam; push @uploadables, $bam;
my $bai = $bam.".bai"; ; push @uploadables, $bai;

for ($vcf_path, $bam_path ) {
    print "making path $_\n";
    $cmd = "mkdir -p $_";
    $ret = `echo $cmd |  ssh ivana\@brontosaurus.tch.harvard.edu 'bash -s 2> /dev/null'`;
    print "making path $_/md5sums\n";
    $cmd = "mkdir -p $_/md5sums";
    $ret = `echo $cmd |  ssh ivana\@brontosaurus.tch.harvard.edu 'bash -s 2> /dev/null'`;
}

##########################################
# upload to bronto
foreach my $fnm (@uploadables) {
    my $md5sum_local = `md5sum $fnm | cut -d " " -f 1`; chomp $md5sum_local;
    my $path = $bam_path;
    ($fnm =~ /vcf$/)  && ($path = $vcf_path);

    `scp $fnm  ivana\@brontosaurus.tch.harvard.edu:$path`;
    $cmd = "\"md5sum $path/$fnm | cut -d  ' ' -f 1 > $path/md5sums/$fnm.md5\"";
    $ret = `echo $cmd |  ssh ivana\@brontosaurus.tch.harvard.edu 'bash -s 2> /dev/null'`;
    # checksum local
    $cmd = "cat $path/md5sums/$fnm.md5";
    $ret = `echo $cmd |  ssh ivana\@brontosaurus.tch.harvard.edu 'bash -s 2> /dev/null'`;
    $ret ||  die "No md5sum found for $path/$fnm; it should have been calculated right now.\n";
    my $md5sum_bronto = $ret; chomp $md5sum_bronto;

    $md5sum_bronto eq $md5sum_local || die "checksum mismatch for $fnm\n";
    print "uploaded  $fnm, checksum checks\n";

}

#######################################
sub find_or_calculate_remote_md5sum(@) {
    my ($path, $file) = @_;
    # see if we already have one:
    my $cmd = "cat $path/md5sums/$file.md5";
    my $ret = `echo $cmd |  ssh ivana\@brontosaurus.tch.harvard.edu 'bash -s 2> /dev/null'`;
    if (!$ret) {
        print "No md5sum found for $path/$file. Calculating ...\n";
        $cmd = "\"md5sum $path/$file | cut -d  ' ' -f 1 > $path/md5sums/$file.md5\"";
        $ret = `echo $cmd |  ssh ivana\@brontosaurus.tch.harvard.edu 'bash -s 2> /dev/null'`;
        # checksum local
        $cmd = "cat $path/md5sums/$file.md5";
        $ret = `echo $cmd |  ssh ivana\@brontosaurus.tch.harvard.edu 'bash -s 2> /dev/null'`;
        $ret || die "No md5sum found for $path/$file; it should have been calculated right now.\n";
    }
    chomp $ret;
    return  $ret;
}

#######################################
sub find_fastqs  {
    # find fastq - if we have fastq we start from there
    my @fastqs = ();
    my $cmd  = "find $individual_dir -name \"*fastq.bz2\" ";
    my $ret  = `echo $cmd |  ssh ivana\@brontosaurus.tch.harvard.edu 'bash -s '`;
    if (!$ret) {
        $cmd  = "find $individual_dir -name \"*fastq.gz\" ";
        $ret = `echo $cmd |  ssh ivana\@brontosaurus.tch.harvard.edu 'bash -s '`;
    }
    if (!$ret ) {
        printf "No fastqs (bz2 or gz) found. Will try to start from *.bam\n";
        return @fastqs;
    }

    foreach (split '\n', $ret) {
        my @aux = split '\/';
        my $fnm = pop @aux;
        my $path = join "/", @aux;
        my $unzipped = $fnm;
        # the files in archive are empty placeholders - the actual files are on
        # the archive server (Dropbox in our case)
        $path =~ /archive/ && next;
        $unzipped  =~ s/\.bz2$//;
        $unzipped  =~ s/\.gz$//;
        if ( -e $unzipped && ! -z $unzipped) {
            push @fastqs, $unzipped;
        } else {
            # md5sum
            my $md5sum_bronto = find_or_calculate_remote_md5sum($path, $fnm);
            # downnload and check md5sum
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
    if (@fastqs!=2) {
        # the fastqs are not concatenated - not sure how that
        # can look in general, but I've seen cases with names labeled _R1_ and _R2_
        # if it is not the case, suggest modification of thei script
        my %reads = ();
        @{$reads{"left"}}  = sort( grep {/_R1_/} @fastqs );
        @{$reads{"right"}} = sort( grep {/_R2_/} @fastqs );

        if ( scalar(@{$reads{"left"}})  + scalar(@{$reads{"right"}})  != scalar(@fastqs) ) {
            print join ("\n", @fastqs);
            die "Unexpected naming convention for multiple fastq files: consider adapting the script. ";
        }

        # if that is the case, proceed to unzip if needed, and concatenate
        for my $read_side ( "left", "right") {
            `touch $read_side.fastq`;
            for (@{$reads{$read_side}}) {
                if (/(.+)\.gz$/) {
                    `gunzip $_`;
                    `cat $1 >> $read_side.fastq`;
                    `rm $1`;
                } elsif (/(.+)\.bz2$/) {
                    `bzip2 -d $_`;
                    `cat $1 >> $read_side.fastq`;
                    `rm $1`;
                } else {
                    `cat $_ >> $read_side.fastq`;
                    `rm $_`;
                }
            }
        }
        @fastqs = ("left.fastq", "right.fastq");
    }
    return @fastqs;
}


#######################################
sub fastqs_from_bam {

    my @fastqs = ();

    my $bamfile =  bam_from_bronto;
    if (!$bamfile) {
        printf "Bam file(s) not found on bronto either. Checking Dropbox ...\n";
        $bamfile = `$bam_from_dropbox seqcenter $boid`;
        chomp $bamfile;
        $bamfile =~ /.bam$/  ||  return @fastqs;
    }

    my $qsort_root = $bamfile;  $qsort_root =~ s/\.bam$/.qsort/;
    my $qsort_file = $qsort_root.".bam";
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

    # remove bamfiles to make some room on the disk
    `rm -f *.bam`;
    push @fastqs, $fq1;
    push @fastqs, $fq2;

    return @fastqs;
}

#######################################
sub bam_from_bronto {

    my @fastqs = ();
    my $cmd  = "find $individual_dir -name \"*.bam\" ";
    my $ret = `echo $cmd |  ssh ivana\@brontosaurus.tch.harvard.edu 'bash -s '`;
    $ret || return "";

    my @lines = split '\n', $ret;
    if ( @lines>1 ) {
        printf "Multiple bamfiles found: \n". (join "\n", @lines)."\n";
        return  "";
    }

    my @aux = split '\/', $lines[0];
    my $bamfile = pop @aux;
    my $path = join "/", @aux;
    # md5sum
    my $md5sum_bronto = find_or_calculate_remote_md5sum($path, $bamfile);
    (-e $bamfile && ! -z $bamfile) || `scp ivana\@brontosaurus.tch.harvard.edu:$path/$bamfile .`;
    my $md5sum_local = `md5sum $bamfile | cut -d " " -f 1`; chomp $md5sum_local;
    $md5sum_bronto eq $md5sum_local || die "checksum mismatch for $bamfile\n";
    print "downloaded $bamfile from bronto, checksum checks\n";

    return $bamfile;
}

