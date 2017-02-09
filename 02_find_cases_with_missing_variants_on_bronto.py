#!/usr/bin/python

import sys
from os import listdir
import  subprocess

from  variant_utils_py.generic_utils import *
from  variant_utils_py.mysqldb import *

####################################
def main():

    db     = connect_to_mysql()
    cursor = db.cursor()
    switch_to_db (cursor, 'blimps_production')
    # find all individual ids that have no variants
    qry  = 'select i.boid from individuals i left join variants v '
    qry += 'on i.id=v.individual_id where v.individual_id is null'
    rows  = search_db (cursor, qry)
    for row in rows:
        print row[0]

    cursor.close()
    db.close()
    return


####################################
if __name__ == '__main__':
    main()
