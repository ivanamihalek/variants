#!/usr/bin/perl -w


@ARGV ||
    die "Usage:  $0  <file name> \n";

$filename = $ARGV[0];
# assuming the name that came from the previous step in the pipeline is
# *.stripped.jv.cleaned.vcf
$new_filename = $filename;
$new_filename =~  s/stripped\.jv\.cleaned/annotated/;

$new_filename ne $filename or 
    die "name change failed: expected stripped\.jv\.cleaned in the input name\n";

$cmd =  "/home/ivana/third/vcfanno/vcfanno /home/ivana/third/vcfanno/af_extract.toml $filename > $new_filename ";
print "runnning: $cmd\n";

system ($cmd) && die "error running $cmd: $!\n";

