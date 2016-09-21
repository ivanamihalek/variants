package variant_utils_pl::generic;
require Exporter;
our @ISA = ("Exporter");
our @EXPORT_OK = qw(strip_vcf);

use strict;
use warnings;

sub strip_vcf (@) {

    my $filename = $_[0];
    open (IF, "<$filename" ) 
	|| die "Cno $filename: $!.\n";

    my $outf = $filename;
    $outf=~ s/\.vcf/.stripped.vcf/;
    open (OF, ">$outf" ) 
	|| die "Cno $outf: $!.\n";

    my $reading = 0;
    while ( <IF> ) {

	if (! $reading) {
	    print OF;
	    /^#CHROM/ && ($reading = 1);
	} else {
	    my @aux = split '\t';
	    my $newline = join "\t", @aux [0 .. 6];
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
    close OF;
}
