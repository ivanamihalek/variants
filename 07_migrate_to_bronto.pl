#!/usr/bin/perl -w
# `` = { } 

@gzipped_fastq_files = split "\n", `ls *end*fastq.gz`;
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
	push @gzipped_fastq_file, $file.".gz";
    }
}
mkdir 'movables';

# collect fastq files
foreach my $file (@gzipped_fastq_files)  { 
   `mv $file movables`;
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

print "From here: data management pipeline, md5sum check\n";
