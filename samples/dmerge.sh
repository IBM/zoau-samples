#!/bin/sh

# dmerge: merge 2 datasets into one using SORT
# requires ZOAU to be installed on your system.
# This is a very simple wrapper to generic SORT
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
	echo "  -K [start,[length],[type],[direction]]  Defines a key field."
	echo "Defaults:"
	echo "  If no -K option specified, defaults are 1,[record-length],CH,A."
	echo "  If start is specified, length must be specified."
	echo "  type defaults to CH."
	echo "  direction defaults to A."
	echo "Examples:"
	echo "  dmerge.sh -K1,9,CH,A ibmuser.orig ibmuser.new ibmuser.merge "
	echo "    Merge 'orig' and 'new' datasets into 'merge' dataset using a character key field "
	echo "    starting in the first column with a length of 9, a type of character, in ascending order."
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
		echo "Unknown option ${1} specified" >&2
		exit 4
		;;
	esac
	shift
done

inds1=$1
inds2=$2
outds=$3

maxrc=0
type=''
recfm=''
lrecl=0
init=true
for ds in $inds1 $inds2 $outds; do
	dsinfo=$(dls -l $ds 2>/dev/null)
	if [ $? -gt 0 ]; then
		echo "Dataset $ds does not exist. Allocate the dataset before attempting merge." >&2
		maxrc=4
	fi
	this_type=$(echo "$dsinfo" | awk '{ print $2; }')
	this_recfm=$(echo "$dsinfo" | awk '{ print $3; }')
	this_lrecl=$(echo "$dsinfo" | awk '{ print $4; }')
	if $init ; then
		type=${this_type}
		recfm=${this_recfm}
		lrecl=${this_lrecl}
		init=false
	fi
	if [ "${recfm}" != "${this_recfm}" ] || [[ $lrecl -ne $this_lrecl ]]; then
		echo "Datasets must all have the same record format and logical record length" >&2
		exit 4
	fi
	if [ "${this_type}" != 'PO' ] && [ "${this_type}" != 'PS' ]; then
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

echo $keys $type $recfm $lrecl $start_offset
#echo "${mod}" | mvscmd --pgm=asmdasm --steplib=${ASMDASM_DS} --syslib="${ds}(${mod})" --sysin=stdin --sysprint="${lst}" --syspunch="${das}"
