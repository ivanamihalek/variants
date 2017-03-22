
import os, dropbox
import sys, requests
from time import time

CHUNK_SIZE    = 10 * 1024 * 1024
MAX_RETRIES   = 20


####################################
DROPBOX_TOKEN = os.environ['DROPBOX_TOKEN']

dbx = dropbox.Dropbox(DROPBOX_TOKEN)

####################################
# this is part of bam downloding - it is not general
def scan_through_folder (dbx, dbx_path, local_dir, download_requested):

	# if download is false, we are just checking for the existence
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
			if not entry.name[-4:] in [".md5",".bam",".bai"]: continue
			dbx_file_path = entry.path_display
			local_filename = local_dir+"/"+entry.name
			if download_requested and not os.path.exists(local_filename): download(dbx, local_filename, dbx_file_path)
			if entry.name[-4:] == ".md5":
				checksums.append(entry.name)
			elif entry.name[-4:] in [".bam",".bai"]:
				files.append(entry.name)
	return files, checksums

####################################
def almtdir_name(bam_source):
	if bam_source == 'seqmule':
		almtdir = "by_seqmule_pipeline"
	else:
		almtdir = "by_seq_center"
	return almtdir

####################################
def construct_dbx_path(boid,bam_source, verbose=False):
	topdir = "/raw_data"
	year = "20" + boid[2:4]
	caseno = boid[4:7]
	# check that the expected path in the dropbox exists
	dbx_path = "/".join([topdir, year, caseno, boid, "wes/alignments/%s" % almtdir_name(bam_source)])
	if not check_dbx_path(dbx, dbx_path):
		print  dbx_path, "not found in Dropbox"
		print "(I checked in %s)" % dbx_path
		exit(1)
	if verbose: print dbx_path, "found in dropbox"
	return dbx_path

####################################
def	md5sum_check(files, checksums, verbose=False):
	for file in files:
		md5file = file+".md5"
		if not md5file in checksums:
			print "md5 file not found for", file
			exit(1)
		md5sum_dropbox = os.popen("cat %s" % md5file).read().strip()
		md5sum_local = os.popen("md5sum %s | cut -d' ' -f 1" % file).read().strip()
		if verbose: print "dbx: ", md5sum_dropbox
		if verbose: print "here:", md5sum_local
		if not md5sum_dropbox == md5sum_dropbox:
			print "md5sum mismatch"
			exit(1)


####################################
def get_bam_from_dropbox(boid, bam_source, download_requested=True):

	dbx_path  = construct_dbx_path(boid,bam_source)
	local_dir = os.getcwd()
	# download bamfiles
	files, checksums = scan_through_folder(dbx, dbx_path, local_dir, download_requested)
	# check md5 sums
	if download_requested: md5sum_check(files, checksums)
	bamfiles = filter(lambda f: ".bam" == f[-4:], files)
	if len(bamfiles) == 0:
		print "no bamfile found"
		exit(1)
	if len(bamfiles) > 1:
		print "more than one bamfile found"
		exit(1)
	return bamfiles[0]


####################################
def check_dbx_path(dbx, dbx_path):
    try:
        dbx.files_get_metadata(dbx_path)
        return True
    except:
        return False

####################################
def download(dbx, scratch_path, dbx_path):
    with open(scratch_path, "w") as f:
        try:
            metadata, res = dbx.files_download(path=dbx_path)
        except dropbox.exceptions.ApiError as err:
            print "Download failure:", err
            print "Not sure what that means, so I'll exit."
            exit(1)
        f.write(res.content)
    f.close()

####################################
def upload(dbx, local_file_path, dbx_path):
    f = open(local_file_path)
    file_size = os.path.getsize(local_file_path)

    print
    print "#"*20

    if file_size <= CHUNK_SIZE:
        print "file size %d smaller than CHUNK_SIZE %d " % (file_size, CHUNK_SIZE)
        print dbx.files_upload(f.read(), dbx_path)

    else:
        approx_number_of_chunks =  file_size/CHUNK_SIZE
        print "file size = %d, CHUNK_SIZE = %d  ==> approx %d chunks to upload" % (file_size, CHUNK_SIZE, approx_number_of_chunks)
        t_start = time()
        try:
            upload_session_start_result = dbx.files_upload_session_start(f.read(CHUNK_SIZE))
        except dropbox.exceptions.ApiError as err:
            print "Failed to start the upload session: %s. Exiting." % err
            exit(1)
        try:
            cursor = dropbox.files.UploadSessionCursor(session_id=upload_session_start_result.session_id, offset=f.tell())
        except dropbox.exceptions.ApiError as err:
            print "Failed to obtain cursor: %s. Exiting." % err
            exit(1)
        try:
            commit = dropbox.files.CommitInfo(path=dbx_path)
        except dropbox.exceptions.ApiError as err:
            print "Commit failure: %s. Exiting." % err
            exit(1)


        chunk_counter = 0
        panic_ctr     = 0
        corrupt_file = False
        while f.tell() < file_size and not corrupt_file:
            if ((file_size - f.tell()) <= CHUNK_SIZE):
                try:
                    dbx.files_upload_session_finish(f.read(CHUNK_SIZE), cursor, commit)
                except dropbox.exceptions.ApiError as err:
                    print "Upload finish failure:", err
                    print "Not sure what that means, so I'll move on."
                    corrupt_file = True
            else:
                try :
                    dbx.files_upload_session_append(f.read(CHUNK_SIZE), cursor.session_id, cursor.offset)
                except (dropbox.exceptions.ApiError, dropbox.exceptions.InternalServerError) as err:
                    print "Chunk upload failure:", err
                    panic_ctr += 1
                    if panic_ctr > MAX_RETRIES:
                        print "Reached max number of retries. Bailing out."
                        exit(1)
                    print "Will retry ..."
                    continue
                except requests.exceptions.ConnectionError as err:
                    # if I get  error(104, 'Connection reset by peer'), I should probably go back to repoening the connection
                    print "Connection error", err
                    print "Moving on"
                    break
                except Exception as err:
                    print "Generic Exception", err
                    break
                except BaseException as err:
                    print "BaseException", err
                    break
                panic_ctr = 0
                cursor.offset = f.tell()
                chunk_counter += 1
                if not chunk_counter%10:
                    time_elapsed    = time() - t_start
                    estimated_speed = chunk_counter*1./time_elapsed
                    time_remaining  = (approx_number_of_chunks - chunk_counter)/estimated_speed/60;
                    print "Uploaded %d chunks in %.1fs. Estimated time remaining %.1f min." % (chunk_counter, time_elapsed, time_remaining)
        
        print "Finished uploading in %.1f s." % (time() - t_start)
    f.close()
