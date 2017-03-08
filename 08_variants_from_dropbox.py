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
		for entry in response.entries:
			if type(entry)!=dropbox.files.FileMetadata: continue
			print entry.name
			print entry.path_display
			#dbx_path = entry.path_display
			#if not os._exists(local_dir+"/"+entry.name): download(dbx, local_dir, dbx_path)


####################################
def main():

	if len(sys.argv) < 2:
		print  "usage: %s <BOid>" % sys.argv[0]
		exit(1)
	boid =	sys.argv[1]

	topdir = "/raw_data"
	year   = "20"+boid[2:4]
	caseno = boid[4:7]
	dbx_path = "/".join([topdir, year, caseno, boid,"wes/alignments/by_seqmule_pipeline"])
	if not check_dbx_path(dbx, dbx_path):
		print  dbx_path, "not found in Dropbox"
		print "(I checked in %s)" % dbx_path
		exit(1)
	print dbx_path, "found in dropbox"
	local_dir =  os.getcwd()
	scan_through_folder (dbx, dbx_path, local_dir)

	return True



####################################
if __name__ == '__main__':
	main()

