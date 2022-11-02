#!/bin/bash
#!/bin/sh
#
# Use IEHLIST to get the directory information for a data set.
#
# Copyright IBM Corp. 2022
#

set -e

if [ "$#" -ne 1 ]; then
        cat << EOF
usage:
$0 <data set name>
EOF
        exit 1
fi

data_set=$1

volume=$(dls -s ${data_set} | awk -F ' ' '{print $5}')

mvscmd --pgm=IEHLIST \
       --sysprint=stdout \
       --dd1=${data_set},shr,volumes=${volume} \
       --sysin=stdin <<zz
 LISTPDS VOL=3390=${volume},FORMAT,                                       X
               DSNAME=${data_set}
zz
