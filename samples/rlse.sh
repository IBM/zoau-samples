#!/bin/sh

# Releases unused space from a dataset.
#
# Author: Anthony Giorgio <agiorgio@us.ibm.com>
#

if [ -z "$1" ]; then
    echo "Usage: $0 DATASET"
    exit
fi

input=" RELEASE INCL($1)"

echo "${input}" | mvscmdauthhelper --pgm=ADRDSSU --sysin=stdin --sysprint=stdout

