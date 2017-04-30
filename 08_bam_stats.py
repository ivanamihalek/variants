#!/usr/bin/python

# here, in distinction to 05_realignemnt_pipe, we start from bam (seqmule's own)  files,
# downloaded from Dropbox - that's why it has to be python


from  variant_utils_py.dropbox_utils import *
import commands


####################################
# we will check the existence of these in the main file
seqmule = "/home/ivana/third/SeqMule/bin/seqmule"
samtools = "/usr/local/bin/samtools"
# see in integrator for an idea where did this file came from:
bedfile = {"ccds": "/databases/ccds/15/ccds_exon_regions.hg19.bed",
		   "ensembl": "/databases/ucsc/ensembl_exon_regions.hg19.bed",
		   "agilent": "/databases/agilent/v5_plus_5utr/regions_plain.bed",
		   "agilent_v5": "/databases/agilent/v5/regions_plain.bed",
		   "agilent_v4": "/databases/agilent/v4/regions_plain.bed",
		   "hgmd": "/databases/ensembl/hg19/human_pheno_associated.bed"}

bam_source = "seqmule"


####################################
def exists_on_bronto(path):
	cmd = "ls -d %s" % path
	ssh_cmd = "echo %s |  ssh ivana@brontosaurus.tch.harvard.edu 'bash -s ' " % cmd
	# this returns a tuple (exit code, ret value)
	ret = commands.getstatusoutput(ssh_cmd)
	if ret[0] == 0:
		return True
	return False

#####
def make_on_bronto(path):
	cmd = "mkdir -p %s" % path
	ssh_cmd = "echo %s |  ssh ivana@brontosaurus.tch.harvard.edu 'bash -s ' " % cmd
	# this returns a tuple (exit code, ret value)
	ret = commands.getstatusoutput(ssh_cmd)
	if ret[0] == 0:
		return True
	return False

#####
def construct_bronto_path(boid,bam_source):
	year = "20" + boid[2:4]
	caseno = boid[4:7]
	topdir = None
	for directory in ["/data01", "/data02"]:
		if not exists_on_bronto("/".join([directory,year,caseno])): continue
		if topdir:
			print boid, "found in both /data01 and /data02"
			exit()
		topdir = directory
	if not topdir:
		print boid, "not found in either /data01 nor /data02"
		exit()
	bronto_path = "/".join([topdir, year, caseno, boid, "wes/alignments/%s" % almtdir_name(bam_source)])
	if not exists_on_bronto (bronto_path):
		print bronto_path, "not found"
		exit()
	return bronto_path

####################################
def bronto_store(boid, bam_source, uploadfile):
	bronto_path = construct_bronto_path(boid, bam_source)
	# make sure that we have stats folder - make one if we don't
	statspath = bronto_path+"/stats"
	if not exists_on_bronto(statspath):
		if not make_on_bronto(statspath):
			print "failed to make", statspath, "on bronto"
			exit(1)
	# upload to stats folder
	cmd = "scp %s ivana@brontosaurus.tch.harvard.edu:%s" % (uploadfile, statspath)
	os.system(cmd)
	return

####################################
def sort_bam(samtools, bamfile):
	sortedfile = bamfile[0:-3]+"sorted.bam"
	if os.path.exists(sortedfile):
		print sortedfile, "found"
	else:
		cmd = "%s sort -o %s %s " % (samtools, sortedfile, bamfile)
		print "running:\n%s\n...\n" % cmd
		os.system(cmd)

	indexfile = sortedfile+".bai"
	if os.path.exists(indexfile):
		print indexfile, "found"
	else:
		cmd = "%s index %s " % (samtools, sortedfile)
		print "running:\n%s\n...\n" % cmd
		os.system(cmd)

	return sortedfile

####################################
def stats_file_processed(boid, bam_source, filename):
	bronto_path = construct_bronto_path(boid, bam_source)
	# make sure that we have stats folder - make one if we don't
	path = bronto_path+"/stats/"+filename
	return exists_on_bronto(path)

####################################
def check_and_fetch_bam_if_not_present(boid, bam_source):

	bamfile = "%s.0_bwamem.sort.rmdup.readfiltered.realn.bam"
	if os.path.exists(bamfile): return bamfile
	bamfile = get_bam_from_dropbox(boid, bam_source)
	if bam_source=='seqcenter':
		bamfile = sort_bam(samtools, bamfile)

	return bamfile

####################################
def do_stats (boid):

	# seqmule - uses samtools depth - which gives depth position by position
	# do I want to store that?  probably not - so seqmule process is into
	# cumulative stats (with running sums
	bamfile = None
	outfile = None
	for reference in bedfile.keys():
		cmd  = "%s stats --aln -t 4 " % seqmule
		prefix = reference  + "_" + bam_source + "_"+boid
		# have we done this already? properly I should check the creation date,
		# but now I am leaving it for some better times
		if stats_file_processed(boid, bam_source,"%s_cov_stat_detail.txt" % prefix):
			print "%s_cov_stat_detail.txt" % prefix, "processed already"
			continue
		bamfile = check_and_fetch_bam_if_not_present(boid, bam_source)
		cmd += "-prefix %s --bam  %s --capture %s " % (prefix, bamfile, bedfile[reference])
		print "running:\n%s\n...\n" % cmd
		os.system(cmd)
		# store  to bronto - it should find its way to dropbox in one of the update rounds
		for outfile in ["%s_cov_stat_detail.txt" % prefix, "%s_cov.jpg" % prefix]:# the name that the seqmule generates
			bronto_store(boid, bam_source, outfile)
		os.system("rm *txt *jpg")
	# samtools bedcov or depth? bedcov gives what is in principle average coverage in a region
	# (it gives the sum of depths, which then need to be divided by the length of the region)
	# my regions of interest are exons;
	# do only ensembl here because ccds is a subset
	outfile = "ensembl_%s_%s.bedcov.csv" % (bam_source, boid)
	if stats_file_processed(boid, bam_source,outfile):
		print outfile, "processed already"
	else:
		bamfile = check_and_fetch_bam_if_not_present(boid, bam_source)
		cmd = "%s  bedcov  %s  %s > %s " % (samtools, bedfile["ensembl"], bamfile, outfile)
		print "running:\n%s\n...\n" % cmd
		os.system(cmd)
		bronto_store(boid, bam_source, outfile)

	if outfile and os.path.exists(outfile): os.system("rm -f %s" % outfile)
	if bamfile and os.path.exists(bamfile): os.system("rm -f %s *bai *md5" % bamfile)
	return

####################################
def main():

	if len(sys.argv) < 2:
		print  "usage: %s <BOid>/<BOid list file> " % sys.argv[0]
		exit(1)

	# bam source here is  hardcoded on top
	# aside fromt the fact that seqmule removes duplicates,
	# there does not seem to be much difference
	if not bam_source in ['seqmule', 'seqcenter']:
		print "unrecognized bam source: ", bam_source
		exit()

	for f in bedfile.values() + [seqmule, samtools]:
		if not os.path.exists(f):
			print f, " not found"
			exit(1)

	if os.path.exists(sys.argv[1]) and os.path.isfile(sys.argv[1]):
		boid_list =	sys.argv[1]
		for line in open(boid_list,"r"):
			boid = line.rstrip()
			do_stats (boid)
	else:
		boid = sys.argv[1]
		do_stats (boid)

####################################
if __name__ == '__main__':
	main()

