import os

####################################
def check_local_path(path):
    if not os.path.exists(path):
        print path, "not found"
        return False
    if not os.path.isdir(path):
        print path, "does not seem to be a directory"
        return False
    return True
