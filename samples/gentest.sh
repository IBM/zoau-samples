#!/bin/sh
#
# Use IEBDG to generate a sequential dataset with test data.
#
# Copyright IBM Corp. 2022
#

if [ "$#" -ne 2 ]; then
    echo "usage:
        $0 <data set name> <records>"
    exit 1
fi

data_set=$1
records=$2
if ! dls -q "$data_set"; then
    dtouch -tseq -rFB -l80 "$data_set"
fi

mvscmd --pgm=IEBDG \
       --sysprint=stdout \
       --OUT="$data_set" \
       --sysin=stdin <<zz
  DSD OUTPUT=(OUT)
  FD NAME=FIELD1,LENGTH=70,FORMAT=AL,ACTION=RP
  FD NAME=FIELD2,LENGTH=10,PICTURE=10,' TEST DATA'
  CREATE QUANTITY=$records,NAME=(FIELD1,FIELD2)
zz
