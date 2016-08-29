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
	# I can't do this: this DP is not the read depth, though some headers say so - it is some
	# property of the position itself, rather than the experiment
	#if ($aux[7] =~ /(DP=\d+)/) {
	#     $newline .= "\t$1\t"; 
	#} else {
	    $newline .= "\tinfo\t";   # jannovar insists that this should not be of zero length
	#}
	$newline .= join "\t", @aux [8 .. 9];
	print OF $newline;
    }

}

close IF;


print "current pipe:  next run 12_jannovar.pl $outf\n";
