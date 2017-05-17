# SeqMule evaluates consensus from several callers,
# but then sometimes drops the alternative depths and their phred scores
# I need the alt depths for further  processing, so I will asuume that
# the other vcf files are still present in the directory,
# and if so force allele dpeths from one of the files, that has the consensus alt strinf
package variant_utils_pl::find_depth;
require Exporter;
our @ISA = ("Exporter");
our @EXPORT_OK = qw(find_depth);

use strict;
use warnings;

sub parse_depth (@);
sub find_depth_field_in_other_files (@);

sub find_depth (@) {

    my $filename = $_[0];
    open (IF, "<$filename" ) 
	|| die "Cno $filename: $!.\n";

	my @path_pieces = split "/", $filename;
	pop  @path_pieces;
	my $path = join "/", @path_pieces;
	my @alt_vcf_files = split "\n", `ls $path/*.vcf | grep -v extract`;

    my $outf = $filename;
    $outf=~ s/\.vcf/.fixed_depth.vcf/;
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
            if ($aux[8] =~ /\:A[ODC]\:/) {
                 print OF $line;
                 next;
            }
            # find the same position in other vcf files in the same folder
            my ($chrom, $pos) = @aux[0..1];
            my ($ref, $alt) = @aux[3..4];
            my @retvals = check_depth_field_exists_in_other_files ($chrom, $pos, $ref, $alt, \@alt_vcf_files);
             if ( !@retvals ) {
                 print OF $line;
                 next;
            } else {
               my ($new_ref, $new_alts, $new_keystring, $new_valstring) = @retvals;
               $aux[2] = $new_ref;
               $aux[3] = $new_alts;
               $aux[8] = $new_keystring;
               $aux[9] = $new_valstring;
               my $newline = join "\t", @aux;
               print OF $newline;
            }
         }
    }

    close IF;
    close OF;

    return $outf;
}

###############################################################
sub  check_depth_field_exists_in_other_files (@) {

    my ($chrom, $pos, $ref, $alt) = @_[0..3];
    my @alt_vcf_files = @{$_[4]};
    my $depth_found = 0;
    my @retvals = ();
    # filed [3] is the ref, and fields[4] are alts
    my $alt_sorted = join ",", (  sort (split ",", $alt) );
    for my $altfile (@alt_vcf_files) {
        my $cmd = "grep $pos $altfile | awk '\$1==$chrom'";
        my $ret =  `$cmd`;
        ($ret && length($ret)>0) || next;
        my @field = split '\t', $ret;
        ($field[8] && length($field[8] )) || next;
        ($field[9] && length($field[9] )) || next;
        my $field_four_sorted = join ",", (  sort(split ",", $field[4]) );
        # there is just too much shit to resolve - the consensus has varinats that exist in only one file ...
        # just go with the variant that has depth
        # thus: if I have the depths, I'll go with whichever variants they have - usually it is gatk
        $depth_found = ($field[8]=~/\:AD\:/);
        if ($depth_found) {
            push @retvals, ($field[3], $field[4], $field[8], $field[9]);
            last;
        }
    }
    return @retvals;
}

