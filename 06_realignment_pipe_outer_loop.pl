#!/usr/bin/perl -w
use strict;
use warnings FATAL => 'all';

#infile is just alist of boids
@ARGV==3 || die "Usage: $0  <infile> <workdir> <year>.\n";
my ($infile, $orkdir, $year) = @ARGV;
for ($infile, $orkdir) {
    (-e $_) || die "$_ not found.\n";
}
$orkdir =~ "current" || die "workir has no current in its path - sure you want to use it?\n";
my $yr = substr $year, 2, 2;
my @boids = split "\n", `grep BO$yr $infile`;
for my $boid (@boids) {
    print $boid, "\n";
    # parse boid into year/case/individual (year I have already)
    # run 05_relignment pipe year case individual
}
1;