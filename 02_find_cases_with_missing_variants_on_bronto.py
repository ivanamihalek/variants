#!/usr/bin/python

import sys
import  os
import  subprocess

from  variant_utils_py.generic_utils import *
from  variant_utils_py.mysqldb import *

verbose = False

####################################
def find_boids_without_variants():
    boids = []
    db     = connect_to_mysql()
    cursor = db.cursor()
    switch_to_db (cursor, 'blimps_production')
    # find all individual ids that have no variants
    qry  = 'select i.boid from individuals i left join variants v '
    qry += 'on i.id=v.individual_id where v.individual_id is null'
    rows  = search_db (cursor, qry)
    boids = [row[0] for row in rows]
    cursor.close()
    db.close()
    return boids

####################################
def find_dir(boid):
    # find directory
    paths = []
    for toplevel_dir in ["/data01", "/data02"]:
        paths += [path for path, dir, file in os.walk(toplevel_dir) if boid in dir]
    if len(paths) == 0:
        if verbose: print "No data found for %s" % boid
        return None
    if len(paths) > 1:
        if verbose: print "Data  for %s found in several places. This might require some attention" % boid
        if verbose: print "\n".join(paths)
        return None

    return paths[0]

####################################
def main():
    boids = find_boids_without_variants()
    if len(boids) == 0:
        print "All boids seem to have variants today."
        return

    for boid in boids:
        # can we locate where the related data is stored
        boid_dir = find_dir(boid)
        if not boid_dir: continue
        # do we have the variants?
        vcfs = [file for path, dir, file in os.walk(boid_dir+"/"+boid) if "vcf" in file]
        print boid, boid_dir, vcfs
        # if not, output the name
    return


####################################
if __name__ == '__main__':
    main()
