#!/usr/bin/python

# here, in distinction to 05_realignemnt_pipe, we start from bam (seqmule's own)  files,
# downloaded from Dropbox - that's why it has to be python


from  variant_utils_py.generic_utils import *
from  variant_utils_py.dropbox_utils import *
import commands

####################################
def check_dbx_path(dbx, dbx_path):
    try:
        dbx.files_get_metadata(dbx_path)
        return True
    except:
        return False

####################################
DROPBOX_TOKEN = os.environ['DROPBOX_TOKEN']

dbx = dropbox.Dropbox(DROPBOX_TOKEN)

####################################
def main():

	if len(sys.argv) < 2:
		print  "usage: %s <BOid>" % sys.argv[0]
		exit(1)
	boid =	sys.argv[1]

	topdir = "/raw_data"
	year = "20"+boid[2:4]
	caseno = boid[4:7]
	dbx_path = "/".join([topdir, year, caseno, boid,"wes/alignments/by_seqmule_pipeline"])
	if not check_dbx_path(dbx, dbx_path):
		print  dbx_path, "not found in Dropbox"
		print "(I checked in %s)" % dbx_path
		exit(1)
	print dbx_path, "found in dropbox"


	return True



####################################
if __name__ == '__main__':
	main()

