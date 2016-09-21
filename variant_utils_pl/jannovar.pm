package variant_utils_pl::jannovar;
require Exporter;
our @ISA = ("Exporter");
our @EXPORT_OK = qw(jannovar);

sub jannovar (@) {
    my $filename = $_[0];

    my $cmd =  "java -jar  /home/ivana/third/jannovar/jannovar-cli/target/jannovar-cli-0.17.jar ";
    $cmd .= " annotate -d /home/ivana/third/jannovar/data/hg19_ucsc.ser  --no-3-prime-shifting    -i  $filename";
    print "runnning: $cmd\n";

    system ($cmd) && die "error running $cmd: $!\n";

    my $new_filename = $filename;
    $new_filename=~ s/\.vcf/.jv.vcf/;


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

    return $final_filename;

}
