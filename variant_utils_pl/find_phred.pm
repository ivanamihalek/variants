# SeqMule evaluates consensus from several callers,
# but then sometimes drops the alternative depths and their phred scores
# I need the alt depths for further  processing, so I will asuume that
# the other vcf files are still present in the directory,
# and if so force allele dpeths from one of the files, that has the consensus alt strinf
package variant_utils_pl::find_phred;
require Exporter;
our @ISA = ("Exporter");
our @EXPORT_OK = qw(find_phred);

use strict;
use warnings;

sub find_phred (@) {

    my $filename = $_[0];
    open (IF, "<$filename" ) 
	|| die "Cno $filename: $!.\n";

    my $outf = $filename;
    $outf=~ s/\.vcf/.phredded.vcf/;
    open (OF, ">$outf" ) 
	|| die "Cno $outf: $!.\n";

    my $reading = 0;
    while ( <IF> ) {

        if (! $reading) {
            print OF;
            /^#CHROM/ && ($reading = 1);
        } else {
            my @aux = split '\t';
            $aux[8] =~ ":AD:" && next;
            print "$aux[8]\n";
            print "\n$_\n";
            
            exit;
            my $newline = join "\t", @aux [0 .. 7];
            $newline .= join "\t", @aux [8 .. 9];
            print OF $newline;
        }

    }

    close IF;
    close OF;

    return $outf;
}
