#!/usr/bin/perl -w
# `` = { } 


@fastq_files = split "\n", `ls *end*fastq`;
if (@fastq != 2) { 
    my $currentdir = `pwd`; chomp $currentdir;
    print "I expected exactyl 2 paired end fastq files.\n";
    print "Am I in the right directory? ($currentdir)\n";
    exit;
}

mkdir 'movables';

# collect fastq files
foreach my $file (@fastq_files)  { 
   `gzip $file`;
   `mv $filw movables`;
}

# collect alignment and variant files
`mv *result/*.vcf* movables`
`mv *result/*.realn.bam* movables`

# caclulate md5sum and migrate
chdir 'movables';
`touch md5sums.bison`;

@files  = split "\n", `ls`;
foreach my $file (@files)  { 
    print "$file\n";
    `md5sum $file >> md5sums.bison`;
    `scp  $file  ivana\@brontosaurus.tch.harvard.edu:tray/`;
} 

`scp  md5sums.bison  ivana\@brontosaurus.tch.harvard.edu:tray/`;

print "From here: data management pipeline, md5sum check\n";
