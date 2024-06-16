#!/bin/env bash

# dmerge: merge 2 datasets into one using SORT
# requires ZOAU to be installed on your system.
# This is a simple wrapper to generic SORT for just a subset of MERGE capabilities.
#
# This sample only supports all 3 datasets being the same LRECL and RECFM. 
#
# IBM DFSORT documentation can be found here: https://www.ibm.com/docs/en/zos/latest?topic=descriptions-dfsort
# Feel free to enhance this script as appropriate.
#
# Copyright IBM Corp 2024.
#

Syntax()
{
	echo "dmerge.sh is a utility for merging 2 datasets into one."    
	echo "Usage: dmerge.sh [OPTION] [input-dataset 1] [input-dataset 2] [output-dataset]"
	echo "Options:"
	echo "  --help, -?  displays help."
	echo "  -K [start,[length],[keytype],[direction]]  Defines a key field."
	echo "Defaults:"
	echo "  If no -K option specified, defaults are 1,[record-length],CH,A."
	echo "  length defaults to record length - start + 1 (i.e. the rest of the record)."
	echo "  keytype defaults to CH."
	echo "  direction defaults to A."
	echo "Examples:"
	echo "  dmerge.sh -K1,9,CH,A ibmuser.orig ibmuser.new ibmuser.out(merge) "
	echo "    Merge 'orig' and 'new' datasets into 'merge' dataset member using a character key field "
	echo "    starting in the first column with a length of 9, a keytype of character, in ascending order."
}

GenKey()
{
	local start_offset=$1
	local recfm=$2
	local lrecl=$3
	local key=$4
	local start
	local length
	local keytype
	local dir

	local fields=$(echo "${key}" | tr ',' ' ')

	# SORT format is <start>,<length>,<keytype>,<dir>
	
	start=$(echo "${fields}" | awk ' { print $1 }')
	length=$(echo "${fields}" | awk ' { print $2 }')
	keytype=$(echo "${fields}" | awk ' { print $3 }')
	dir=$(echo "${fields}" | awk ' { print $4 }')

	if [ "${start}" = '' ]; then
		start=1
	fi
	start=$((start+start_offset))

	if [ "${length}" = '' ]; then
		length=$((lrecl-start))
	fi
	if [ "${keytype}" = '' ]; then
		keytype='CH'
	fi
	if [ "${dir}" = '' ]; then
		dir='A'
	fi

	echo "${start},${length},${keytype},${dir}"
}

if [ $# -lt 3 ]; then
	Syntax
	if [ "$1" = "-?" ] || [ "$1" = "-help" ] ; then
		exit 0
	fi
	exit 4
fi

keys=''
while [ $# -gt 3 ]; do
	case $1 in
	"-h" | "--help" | "-?")
		Syntax
		exit 0
		;;
	"-K")
		if [ "${keys}" = '' ]; then
			keys="$2"
		else
			keys="${keys} $2"
		fi
		shift
		;;
	*)
		opt_first2letters=$(printf %.2s "$1")
		if [ "${opt_first2letters}" = "-K" ]; then
			key=${1##-K}
			if [ "${keys}" = '' ]; then
				keys="$key"
			else
				keys="${keys} $key"
			fi
		else
			echo "Unknown option ${1} specified" >&2
			exit 4
		fi
		;;
	esac
	shift
done

inds1=$1
inds2=$2
outds=$3

maxrc=0
keytype=''
recfm=''
lrecl=0
init=true
for ds in $inds1 $inds2 $outds; do
	dsinfo=$(dls -l $ds 2>/dev/null)
	if [ $? -gt 0 ]; then
		echo "Dataset $ds does not exist. Allocate the dataset before attempting merge." >&2
		maxrc=4
	fi
	this_keytype=$(echo "$dsinfo" | awk '{ print $2; }')
	this_recfm=$(echo "$dsinfo" | awk '{ print $3; }')
	this_lrecl=$(echo "$dsinfo" | awk '{ print $4; }')
	if $init ; then
		keytype=${this_keytype}
		recfm=${this_recfm}
		lrecl=${this_lrecl}
		init=false
	fi
	if [ "${recfm}" != "${this_recfm}" ] || [[ $lrecl -ne $this_lrecl ]]; then
		echo "Datasets must all have the same record format and logical record length" >&2
		exit 4
	fi
	if [ "${this_keytype}" != 'PO' ] && [ "${this_keytype}" != 'PS' ]; then
		echo "Dataset must be either PS (partitioned sequential) or PO (PDS or PDSE)" >&2
		exit 4
	fi
done

if [ $maxrc -gt 0 ]; then
	exit $maxrc
fi

recfm_firstletter=$(printf %.1s "$recfm")
if [ "${recfm_firstletter}" = 'V' ]; then
	start_offset=4
else
	start_offset=0
fi

merge_cmd=''
for key in $keys; do
	if [ "${merge_cmd}" = '' ]; then
		merge_cmd=' MERGE FIELDS=('
	else
		merge_cmd="${merge_cmd},
  "
  	fi
	sort_key=$(GenKey "$start_offset" "$recfm" "$lrecl" "$key")
	merge_cmd="${merge_cmd}${sort_key}"
done
merge_cmd="${merge_cmd})"

echo "${merge_cmd}" | mvscmd --pgm=sort --args='MSGPRT=CRITICAL,LIST' --sysin=stdin --sysout=stdout --sortin01=$inds1 --sortin02=$inds2 --sortout=$outds
