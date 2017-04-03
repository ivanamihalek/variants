use strict;
use warnings;
package variant_utils_pl::vcfanno;
require Exporter;
our @ISA = ("Exporter");
our @EXPORT_OK = qw(vcfanno);

sub vcfanno (@) {
    my $filename = $_[0];
    # assuming the name that came from the previous step in the pipeline is
    # *.stripped.jv.cleaned.vcf --> this was for jannovar, which was giving me some wrong mapping to protein sequence
    #$filename =~ /stripped\.jv\.cleaned/ || die "in vcfannp: unexpected filename: $filename\n";
    $filename =~ /stripped\.annov/ || die "in vcfanno: unexpected filename: $filename\n";
    my $new_filename = $filename;
    $new_filename =~  s/stripped\.annov/annotated/;

    $new_filename ne $filename or 
	die "name change failed: expected stripped\.jv\.cleaned in the input name\n";

    my $cmd =  "/home/ivana/third/vcfanno/vcfanno /home/ivana/third/vcfanno/af_extract.toml $filename > $new_filename ";
    print "runnning: $cmd\n";

    system ($cmd) && die "error running $cmd: $!\n";

    return $new_filename;

}
