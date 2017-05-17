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
            ($pos == 120404629) && print " *****************  afdgkfahgla \n";
            my ($ref, $alt) = @aux[3..4];
            my @retvals = check_depth_field_exists_in_other_files ($chrom, $pos, $ref, $alt, \@alt_vcf_files);
            ($pos == 120404629) && print " retvals:   @retvals\n";
             if ( !@retvals ) {
                 print OF $line;
                 next;
            } else {
               my ($new_alts, $new_keystring, $new_valstring) = @retvals;
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
        # thus: if I have the dpehts, I'll go with whichever variants they have - usually it is gatk
        $depth_found = ($field[3] eq $ref   && $field[8]=~/\:AD\:/);
        if ($depth_found) {
            push @retvals, ($field[4], $field[8], $field[9]);
            last;
        }
    }
    return @retvals;
}

sub string_string_hash (@) {
    my ($keystring, $valstring, $separator) = @_;
    my %rethash = ();
    my @subfield_keys = split $separator, $keystring;
    my @subfield_vals  = split $separator, $valstring;
    foreach my $i (0 .. $#subfield_keys ) {
        $rethash{$subfield_keys[$i]} = $subfield_vals[$i];
    }
    return \%rethash;
}

sub parse_depth (@) {
    my ($chrom, $pos, $ref, $alt) = @_[0..3];
    my @alt_vcf_files = @{$_[4]};
    my @original_alts = split(',', $alt);
    my @all_vars = @original_alts;
    unshift @all_vars, $ref;
    my $number_of_vars = scalar(@original_alts) + 1;
    my $retstr = "";
    for my $altfile (@alt_vcf_files) {
        my $cmd = "grep $pos $altfile | awk '\$1==$chrom'";
        my @field = map { $_ =~ s/\s//r } split '\t', `$cmd`;
        ($field[8] && length($field[8] )) || next;
        ($field[9] && length($field[9] )) || next;
        my %subfield_hash = %{string_string_hash( $field[8], $field[9], ":")};
        # I think I still want AD
        if (defined $subfield_hash{"AD"}) {
            # check if the length is correct
            # the value of  $subfield_hash{"AD"} should be something like 45,20,7 or some such
            my @aux = split ",", $subfield_hash{"AD"};
            if ((scalar @aux)==$number_of_vars) {
                $retstr = "";
                # again, careful with the order
                my %depth_hash = %{string_string_hash($ref.",".$alt, $subfield_hash{"AD"}, ',')};
                $retstr = join "," ,( map { $depth_hash{$_}} @all_vars);
                print " $pos  $retstr\n";
                last;
            }
        }
        # I should check what is goin on in other files, but I need to move o
    }
    return $retstr;


}