#!/usr/bin/perl -w


@ARGV ||
    die "Usage:  $0  <file name> \n";

$filename = $ARGV[0];
@aux = split '\.', $filename;

$new_filename = $aux[0].".annotated.vcf";

$cmd =  "/home/ivana/third/vcfanno/vcfanno /home/ivana/third/vcfanno/af_extract.toml $filename > $new_filename ";
print "runnning: $cmd\n";

system ($cmd) && die "error running $cmd: $!\n";

