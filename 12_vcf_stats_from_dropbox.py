#!/usr/bin/python

# here, in distinction to 05_realignemnt_pipe, we start from bam (seqmule's own)  files,
# downloaded from Dropbox - that's why it has to be python

# CHANGE EVERYTHING TO LOOK FOR ANNOTATED VCFs INST of BAMS

from  variant_utils_py.generic_utils import *
from  variant_utils_py.dropbox_utils import *
import commands


####################################
# we will check the existence of these in the main file
# calculate ROHs
bcftools = "/usr/local/bin/bcftools"
# see in integrator for an idea where did this file came from:
bedfile_agilent = "/databases/agilent/v5_plus_5utr/regions_plain.bed"
bedfile_ensembl = "/databases/ucsc/ensembl_exon_regions.hg19.bed"

####################################
DROPBOX_TOKEN = os.environ['DROPBOX_TOKEN']

dbx = dropbox.Dropbox(DROPBOX_TOKEN)
####################################
def scan_through_folder (dbx, dbx_path, local_dir):

	try:
		response = dbx.files_list_folder(dbx_path, recursive = True)
	except dropbox.exceptions.ApiError as err:
		print('Folder listing failed for', dbx_path, '-- assumed empty:', err)
		exit(1)
	else:
		files = []
		checksums = []
		for entry in response.entries:
			if type(entry)!= dropbox.files.FileMetadata: continue
			dbx_file_path = entry.path_display
			local_filename = local_dir+"/"+entry.name
			if not os.path.exists(local_filename): download(dbx, local_filename, dbx_file_path)
			if ".md5" in entry.name:
				checksums.append(entry.name)
			else:
				files.append(entry.name)
	return files, checksums
####################################
def	md5sum_check(files, checksums):
	for file in files:
		print file
		md5file = file+".md5"
		if not md5file in checksums:
			print "md5 file not found for", file
			exit(1)
		md5sum_dropbox = os.popen("cat %s" % md5file).read().strip()
		md5sum_local = os.popen("md5sum %s | cut -d' ' -f 1" % file).read().strip()
		print "dbx: ", md5sum_dropbox
		print "here:", md5sum_local
		if not md5sum_dropbox == md5sum_dropbox:
			print "md5sum mismatch"
			exit(1)
####################################
def almtdir_name(bam_source):
	if bam_source == 'seqmule':
		almtdir = "by_seqmule_pipeline"
	else:
		almtdir = "by_seq_center"
	return almtdir
####################################
def construct_dbx_path(boid,bam_source):
	topdir = "/raw_data"
	year = "20" + boid[2:4]
	caseno = boid[4:7]
	# check that the expected path in the dropbox exists
	dbx_path = "/".join([topdir, year, caseno, boid, "wes/alignments/%s" % almtdir_name(bam_source)])
	if not check_dbx_path(dbx, dbx_path):
		print  dbx_path, "not found in Dropbox"
		print "(I checked in %s)" % dbx_path
		exit(1)
	print dbx_path, "found in dropbox"
	return dbx_path

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
	cmd = "mkdir %s" % path
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
def get_bam_from_dropbox(boid, bam_source):

	dbx_path = construct_dbx_path(boid,bam_source)
	local_dir = os.getcwd()
	# download bamfiles
	files, checksums = scan_through_folder(dbx, dbx_path, local_dir)
	# check md5 sums
	md5sum_check(files, checksums)
	bamfiles = filter(lambda f: ".bam" == f[-4:], files)
	if len(bamfiles) == 0:
		print "no bamfile found"
		exit(1)
	if len(bamfiles) > 1:
		print "more than one bamfile found"
		exit(1)
	return bamfiles[0]

####################################
def bronto_store(boid, bam_source, uploadfile):
	bronto_path = construct_bronto_path(boid, bam_source)
	# make sure that we have stats folder - make one if we don't
	statspath = bronto_path+"/stats"
	if not exists_on_bronto(statspath):
		if not make_on_bronto(statspath):
			print "failed to male", statspath, "onn bronto"
			exit()
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
def do_stats (boid):
	vcffile = get_vcf _from_dropbox(boid, bam_source)
	cmd = "%s  bedcov  %s  %s > %s " % (samtools, bedfile, bamfile, outfile)
	# -a Output all positions (including those with zero depth)
	#cmd = "%s  depth -a  -b %s  %s > %s " % (samtools, bedfile, bamfile, outfile)
	print "running:\n%s\n...\n" % cmd
	os.system(cmd)
	bronto_store(boid, bam_source, outfile)

	return

####################################
def main():

	if len(sys.argv) < 2:
		print  "usage: %s <BOid list> " % sys.argv[0]
		exit(1)
	boid_list =	sys.argv[1]
	# bam source here is  hardcoded on top
	# aside fromt the fact that seqmule removes duplicates,
	# there does not seem to be much difference

	for f in [bedfile_agilent, bedfile_ensembl, bcftools]:
		if not os.path.exists(f):
			print f, "not found"
			exit(1)

	for line in open(boid_list,"r"):
		boid = list.rstrip()
		do_stats (boid)



####################################
if __name__ == '__main__':
	main()
