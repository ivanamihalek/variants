#!/usr/bin/perl -w
use strict;
use warnings FATAL => 'all';

#infile is just alist of boids
@ARGV==3 || die "Usage: $0  <infile> <workdir> <year>.\n";
my ($infile, $workdir, $year) = @ARGV;
my $realn = "/home/ivana/pypeworks/variants/06_realignment_pipe.pl";

for ($infile, $workdir, $realn) {
    (-e $_) || die "$_ not found.\n";
}
$workdir =~ "current" || die "workir has no current in its path - sure you want to use it?\n";
chdir $workdir;

my $yr = substr $year, 2, 2;
my @boids = split "\n", `grep BO$yr $infile`;
for my $boid (@boids) {
    print $boid, "\n";
    # parse boid into year/case/individual (year I have already)
    # run 05_relignment pipe year c
    my $case       = substr $boid, 4, 3;
    my $individual = substr $boid, 7, 2;
    print `$realn $year $case $individual`;
    `rm -rf BO* seqmule*`;
}
1;