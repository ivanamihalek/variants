#!/usr/bin/perl -w


@ARGV ||
    die "Usage:  $0  <file name> \n";

$filename = $ARGV[0];


$cmd =  "java -jar  /home/ivana/third/jannovar/jannovar-cli/target/jannovar-cli-0.17.jar ";
$cmd .= " annotate -d /home/ivana/third/jannovar/data/hg19_ucsc.ser  --no-3-prime-shifting    -i  $filename";
print "runnning: $cmd\n";

system ($cmd) && die "error running $cmd: $!\n";

$new_filename = $filename;
$new_filename=~ s/\.vcf/.jv.vcf/;


open (IF, "<$new_filename" ) 
    || die "Cno $new_filename: $!.\n";

$final_filename = $new_filename;
$new_filename=~ s/\.vcf/.cleaned.vcf/;
open (OF, ">$final_filename" ) 
    || die "Cno $final_filename: $!.\n";

while (<IF> ) {

    s/\(\=\)/?/g;
    print OF;

}
close OF;
close IF;

print "wrote jannovar.cleaned.vcf\n";

print "current pipe:  next run 14_vcfanno.pl $final_filename\n";
