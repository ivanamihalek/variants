#!/usr/bin/python

# here, in distinction to 05_realignemnt_pipe, we start from bam (seqmule's own)  files,
# downloaded from Dropbox - that's why it has to be python


from  variant_utils_py.generic_utils import *
from  variant_utils_py.dropbox_utils import *
import commands


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

def main():

	if len(sys.argv) < 2:
		print  "usage: %s <BOid>" % sys.argv[0]
		exit(1)
	boid =	sys.argv[1]

	topdir = "/raw_data"
	year   = "20"+boid[2:4]
	caseno = boid[4:7]

	# check that the expected path in the dropbox exists
	dbx_path = "/".join([topdir, year, caseno, boid,"wes/alignments/by_seqmule_pipeline"])
	if not check_dbx_path(dbx, dbx_path):
		print  dbx_path, "not found in Dropbox"
		print "(I checked in %s)" % dbx_path
		exit(1)
	print dbx_path, "found in dropbox"
	local_dir = os.getcwd()

	# download bamfiles
	files, checksums = scan_through_folder (dbx, dbx_path, local_dir)
	# check md5 sums
	md5sum_check(files, checksums)
	bamfiles = filter (lambda f: ".bam" == f[-4:], files)
	if len(bamfiles)==0:
		print "no bamfile found"
		exit(1)
	if len(bamfiles)>1:
		print "more than one bamfile found"
		exit(1)
	bamfile = bamfiles[0]
	print
	seqmule  = "/home/ivana/third/SeqMule/bin/seqmule";
	bedfile  = "/home/ivana/third/SeqMule/database/ensembl_exon_regions.hg19.bed";
	for f in [seqmule, bedfile]:
		if not os.path.exists(f):
			print f, "not found"
			exit(1)
	# note here we are running only seqmule stats here
	cmd  = "%s stats --aln -t 4 " % seqmule
	cmd += "-prefix %s --bam  %s --capture %s " % (boid, bamfile, bedfile)
	print "running:\n%s\n...\n" % cmd
	os.system(cmd)

	return 0



####################################
if __name__ == '__main__':
	main()

