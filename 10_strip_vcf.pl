#!/usr/bin/perl -w


@ARGV ||
    die "Usage:  $0  <file name> \n";

$filename = $ARGV[0];
open (IF, "<$filename" ) 
    || die "Cno $filename: $!.\n";


$outf = $filename;
$outf=~ s/\.vcf/.stripped.vcf/;
open (OF, ">$outf" ) 
    || die "Cno $outf: $!.\n";


$reading = 0;
while ( <IF> ) {

    if (! $reading) {
	print OF;
        /^#CHROM/ && ($reading = 1);
    } else {
	@aux = split '\t';
	$newline = join "\t", @aux [0 .. 6];
	$newline .= "\t\t"; 
	$newline .= join "\t", @aux [8 .. 9];
	print OF $newline;
    }

}

close IF;


print "next run\n";
print "java -jar  /home/ivana/third/jannovar/jannovar-cli/target/jannovar-cli-0.17.jar  annotate -d /home/ivana/third/jannovar/data/hg19_ucsc.ser  --no-3-prime-shifting    -i  $outf\n";
print "\n";
print " ... follofed by  vcf anno ...\n";
