#!/bin/sh
#
# cat sequential datasets, or PDS members (supports wildcards in dataset and member)
#
# Copyright 2021 IBM Corp.
#

#set -x
file=$1
datasetPattern=${file%(*}
memberPattern=`echo "${file}" | tr '()' '\t\t' | awk '{ print $2; }'`
datasets=`dls ${datasetPattern}`
for dataset in ${datasets}; do
	if [ "${memberPattern}" = '' ]; then
		cat "//'${dataset}'"
	else
            	members=`mls "${dataset}(${memberPattern})"`
		for member in ${members}; do
                        cat "//'${dataset}(${member})'"
		done
	fi
done
