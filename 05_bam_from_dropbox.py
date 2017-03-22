#!/usr/bin/python

# bam download has to be python, because Dropbox speaks  python

from  variant_utils_py.dropbox_utils import *
import commands

####################################
def main():

	if len(sys.argv) < 3:
		print  "usage: %s seqmule/seqcenter <boid> [nodwld]" % sys.argv[0]
		exit(1)

	[bam_source, boid] = sys.argv[1:3]
	download_requested = True  # the default is to download but we might be just checking
	if len(sys.argv)>3 and sys.argv[3]=="nodwld": download_requested=False

	if not bam_source in ['seqmule', 'seqcenter']:
		print "unrecognized bam source: ", bam_source
		exit()

	bamfile = get_bam_from_dropbox(boid, bam_source, download_requested)

	if bamfile:
		print bamfile
	else:
		print "none"

	return

####################################
if __name__ == '__main__':
	main()

