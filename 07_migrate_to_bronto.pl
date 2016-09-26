#!/usr/bin/perl -w
# `` = { } [ ]
$move_fastqs = 0;
@ARGV && $ARGV[0] eq "fastq" && ($move_fastqs = 1);

mkdir 'movables';

if ($move_fastqs) { 
    my @gzipped_fastq_files = ();
    my $ret  =  `ls *end*fastq.gz 2>/dev/null`;
    $ret && (@gzipped_fastq_files = split "\n", `ls *end*fastq.gz`);
    if (@gzipped_fastq_files != 2) { 
	
	@fastq_files = split "\n", `ls *end*fastq`;
	if (@fastq_files != 2) { 
	    my $currentdir = `pwd`; chomp $currentdir;
	    print "I expected exactyl 2 paired end fastq files.\n";
	    print "Am I in the right directory? ($currentdir)\n";
	    exit;
	}
	@gzipped_fastq_file  =  ();
	foreach my $file (@fastq_files)  { 
	    `gzip $file`;
	    push @gzipped_fastq_files, $file.".gz";
	}
    }
    # collect fastq files
    foreach my $file (@gzipped_fastq_files)  { 
	`mv $file movables`;
    }
}

# collect alignment and variant files
`mv *result/*.vcf* movables`;
`mv *result/*.realn.bam* movables`;

# caclulate md5sum and migrate
chdir 'movables';
@files  = split "\n", `ls`;

`touch md5sums.bison`;

foreach my $file (@files)  { 
    print "$file\n";
    `md5sum $file >> md5sums.bison`;
    `scp  $file  ivana\@brontosaurus.tch.harvard.edu:tray/`;
} 

`scp  md5sums.bison  ivana\@brontosaurus.tch.harvard.edu:tray/`;

print "Next (on bronto): data management pipeline, md5sum check\n";
