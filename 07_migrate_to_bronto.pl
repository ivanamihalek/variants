#!/usr/bin/perl -w
# `` = { } 

chdir 'movables';
`touch md5sums.bison`;

@files  = split "\n", `ls`;
foreach $file (@files)  { 
    print "$file\n";
    `md5sum $file >> md5sums.bison`;
    `scp  $file  ivana@brontosaurus.tch.harvard.edu:tray/`;
} 
