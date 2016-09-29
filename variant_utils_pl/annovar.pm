package variant_utils_pl::annovar;
require Exporter;
our @ISA = ("Exporter");
our @EXPORT_OK = qw(annovar);

sub jannovar (@) {
    my $filename = $_[0];

    my $new_filename = $filename;
    $new_filename=~ s/\.vcf/.annov/; # annovar will add .vcf
    my $cmd = "/home/ivana/third/annovar/table_annovar.pl $filename  /home/ivana/third/annovar/humandb/ ";
    $cmd .= " -buildver hg19 -out  $new_filename -protocol refGene  -operation g  -nastring . -vcfinput ";
   
    print "runnning: $cmd\n";

    system ($cmd) && die "error running $cmd: $!\n";

    exit;
=pod
    open (IF, "<$new_filename" ) 
	|| die "Cno $new_filename: $!.\n";

    my $final_filename = $new_filename;
    $final_filename=~ s/\.vcf/.cleaned.vcf/;

    open (OF, ">$final_filename" ) 
	|| die "Cno $final_filename: $!.\n";

    while (<IF> ) {

	s/\(\=\)/?/g;
	print OF;

    }
    close OF;
    close IF;
=cut
    return $final_filename;

}
