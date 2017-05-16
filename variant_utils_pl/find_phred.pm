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

	my @path_pieces = split "/", $filename;
	pop  @path_pieces;
	my $path = join "/", @path_pieces;
	my @alt_vcf_files = split "\n", `ls $path/*.vcf | grep -v extract`;

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
            my $line = $_;
            my @aux =  map { $_ =~ s/\s//r } split '\t';
            # it looks like AO (allele count - observed) might be preferable,  because
            # "AD is the unfiltered allele depth, i.e. the number of reads that support
            # each of the reported alleles. All reads at the position (including reads
            # that did not pass the variant caller’s filters) are included in this number"
            # but you never know with these morons - the same document where I found this
            # does nto mention AO; leave alone that there might be 'AC' too (and ADF, and ADR ...)
            $aux[8] =~ /\:A[ODC]\:/  && next;
            # find the same position in other vcf files in the same folder
            my $depth_found = 0;
            my ($chrom, $pos) = @aux[0..1];
            for my $altfile (@alt_vcf_files) {
                my $cmd = "grep $pos $altfile | awk '\$1==$chrom'";
                my @field = split '\t', `$cmd`;
                $depth_found =  ($field[3] eq $aux[3]  &&  $field[4] eq $aux[4]);
            }
            $depth_found  || next;
            print "$aux[8]\n";
            print "\n$line\n";
            for my $altfile (@alt_vcf_files) {
                print "\n$altfile\n";
                my $cmd = "grep $pos $altfile | awk '\$1==$chrom'";
                my @field = map { $_ =~ s/\s//r } split '\t', `$cmd`;
                print "   $field[3]   $field[4]    $field[8] \n";
            }

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

