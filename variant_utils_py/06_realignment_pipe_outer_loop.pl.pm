#!/usr/bin/perl -w
use strict;
use warnings FATAL => 'all';

#infile is just alist of boids
@ARGV==3 || die "Usage: $0  <infile> <workdir> <year>.\n";
my ($infile, $orkdir, $year) = @ARGV;
for ($infile, $orkdir, $year) {
    (-e $_) || die "$_ not found\.n";
}
my $yr = substr $year, 2, 2;
@boids = split "\n", `grep BO$yr $infile`;
for my $boid (@boids) {
    print $boid, "\n";
}
1;