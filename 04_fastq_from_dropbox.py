#!/usr/bin/python

# has to be python, because Dropbox speaks  python

from  variant_utils_py.dropbox_utils import *
import commands

####################################
def main():

	if len(sys.argv) < 2:
		print  "usage: %s  <boid> [nodwld]" % sys.argv[0]
		exit(1)

	boid = sys.argv[1]
	download_requested = True  # the default is to download but we might be just checking
	if len(sys.argv)>3 and sys.argv[2]=="nodwld": download_requested=False

	fastqfiles = get_fastq_from_dropbox(boid, download_requested)

	if fastqfiles:
		print "\n".join(fastqfiles)
	else:
		print "none"

	return

####################################
if __name__ == '__main__':
	main()

