#!/usr/bin/python

# here, in distinction to 05_realignemnt_pipe, we start from vcf (seqmule's own)  files,
# downloaded from Dropbox - that's why it has to be python

# CHANGE EVERYTHING TO LOOK FOR ANNOTATED VCFs INST of vcfS

from  variant_utils_py.generic_utils import *
from  variant_utils_py.dropbox_utils import *
import commands


####################################
# we will check the existence of these in the main file
# calculate ROHs
bcftools = "/usr/local/bin/bcftools"
variant_caller = "seqmule"

####################################
DROPBOX_TOKEN = os.environ['DROPBOX_TOKEN']

dbx = dropbox.Dropbox(DROPBOX_TOKEN)
####################################
def scan_through_folder (dbx, dbx_path, local_dir):


	if (variant_caller != "seqmule"):
		print "from scan_through_folder:"
		print "this implementation knows only how to handle seqmule case"
		exit()

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
			if not "consensus.annotated.vcf" in entry.name: continue
			if not os.path.exists(local_filename): download(dbx, local_filename, dbx_file_path)
			if entry.name[-4:]==".md5":
				checksums.append(entry.name)
			elif entry.name[-4:]==".vcf":
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
def variant_dir_name(vcf_source):
	if vcf_source == 'seqmule':
		almtdir = "called_by_seqmule_pipeline"
	else:
		almtdir = "called_by_seq_center"
	return almtdir

####################################
def construct_dbx_path(boid, variant_caller):
	topdir = "/raw_data"
	year   = "20" + boid[2:4]
	caseno = boid[4:7]
	# check that the expected path in the dropbox exists
	dbx_path = "/".join([topdir, year, caseno, boid, "wes/variants/%s" % variant_dir_name(variant_caller)])
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
def construct_bronto_path(boid,vcf_source):
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
	bronto_path = "/".join([topdir, year, caseno, boid, "wes/variants/%s" % variant_dir_name(vcf_source)])
	if not exists_on_bronto (bronto_path):
		print bronto_path, "not found"
		exit()
	return bronto_path

####################################
def get_vcf_from_dropbox(boid, variant_caller):


	dbx_path = construct_dbx_path(boid, variant_caller)
	local_dir = os.getcwd()
	# download vcf files
	files, checksums = scan_through_folder(dbx, dbx_path, local_dir)
	# check md5 sums
	md5sum_check(files, checksums)
	vcffiles = filter(lambda f: ".vcf" == f[-4:], files)
	if len(vcffiles) == 0:
		print "no vcffile found"
		exit(1)
	if len(vcffiles) > 1:
		print "more than one vcffile found"
		exit(1)
	return vcffiles[0]

####################################
def bronto_store(boid, vcf_source, uploadfile):
	bronto_path = construct_bronto_path(boid, vcf_source)
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
def sort_vcf(samtools, vcffile):
	sortedfile = vcffile[0:-3]+"sorted.vcf"
	if os.path.exists(sortedfile):
		print sortedfile, "found"
	else:
		cmd = "%s sort -o %s %s " % (samtools, sortedfile, vcffile)
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
def do_stats (boid, variant_caller):
	vcffile = get_vcf_from_dropbox(boid, variant_caller)
	outfile = boid+".seqmule_vcf.bcftools_roh.cvs"
	cmd = "%s  roh   -G30 --AF-dflt 0.4    %s  > %s " % (bcftools, vcffile, outfile)
	print "running:\n%s\n...\n" % cmd
	os.system(cmd)
	bronto_store(boid, variant_caller, outfile)

	return

####################################
def main():


	if (variant_caller != "seqmule"):
		print "this implementation knows only how to handle seqmulr case"
		exit()

	if len(sys.argv) < 2:
		print  "usage: %s <BOid list> " % sys.argv[0]
		exit(1)
	boid_list =	sys.argv[1]
	# vcf source here is  hardcoded on top
	# aside fromt the fact that seqmule removes duplicates,
	# there does not seem to be much difference

	for f in [bcftools]:
		if not os.path.exists(f):
			print f, "not found"
			exit(1)

	for line in open(boid_list,"r"):
		boid = line.rstrip()
		do_stats (boid, variant_caller)



####################################
if __name__ == '__main__':
	main()

