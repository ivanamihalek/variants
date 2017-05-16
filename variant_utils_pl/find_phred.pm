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

sub parse_phred (@);

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
    my $count = 0;
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
            # filed [3] is the ref, and fields[4] are alts
            my $aux_four_sorted = join ",", (  sort (split ",", $aux[4]) );
            for my $altfile (@alt_vcf_files) {
                my $cmd = "grep $pos $altfile | awk '\$1==$chrom'";
                my $ret =  `$cmd`;
                ($ret && length($ret)>0) || next;
                my @field = split '\t', $ret;
                my $field_four_sorted = join ",", (  sort (split ",", $field[4]) );
                $depth_found = ($field[3] eq $aux[3]  &&  $field_four_sorted eq $aux_four_sorted  && $field[8]=~/\:A[ODC]\:/);
                last if $depth_found;
            }
            $depth_found  || next;
            print "\n-----------------------------------------------------------------------\n";
            print "$aux[8]\n";
            print "\n$line\n";
            my $depthstr = parse_phred ($chrom, $pos, $aux[3], $aux[4], \@alt_vcf_files);
            $count ++;
            $count==50 && exit;
            #next;
            #my $newline = join "\t", @aux [0 .. 7];
            #$newline .= join "\t", @aux [8 .. 9];
            #print OF $newline;
        }

    }

    close IF;
    close OF;

    return $outf;
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

sub parse_phred (@) {
    my ($chrom, $pos, $ref, $alt) = @_[0..3];
    my @alt_vcf_files = @{$_[4]};
    print "  $chrom, $pos, $ref, $alt \n";
    print "@alt_vcf_files\n";
    my @original_alts = split(',', $alt);
    my @all_vars = @original_alts;
    unshift @all_vars, $ref;
    my $number_of_vars = scalar(@original_alts) + 1;
    my $retstr = "";
    for my $altfile (@alt_vcf_files) {
        print "\n$altfile\n";
        my $cmd = "grep $pos $altfile | awk '\$1==$chrom'";
        my @field = map { $_ =~ s/\s//r } split '\t', `$cmd`;
        ($field[8] && length($field[8] )) || next;
        ($field[9] && length($field[9] )) || next;
        print "   $field[3]   $field[4]    $field[8]   $field[9] \n";
        my %subfield_hash = %{string_string_hash( $field[8], $field[9], ":")};
        # I think I still want AD
        if (defined $subfield_hash{"AD"}) {
            # check if the length is correct
            # the value of  $subfield_hash{"AD"} should be something like 45,20,7 or some such
            my @aux = split ",", $subfield_hash{"AD"};
            if ((scalar @aux)==$number_of_vars) {
                print "\t  >>   @aux \n";
                $retstr = "";
                # again, careful with the order
                my %depth_hash = %{string_string_hash($ref.",".$alt, $subfield_hash{"AD"}, ',')};
                $retstr = join "," ,( map { $depth_hash{$_}} @all_vars);
                print "\t  >>   $retstr \n";
                last;
            }
        }
        # I should check what is goin on in other files, but I need to move o
    }
    return $retstr;


}