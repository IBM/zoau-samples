#!/bin/sh
#*******************************************************************************
# Licensed Materials - Property of IBM
# (c) Copyright IBM Corporation 2019. All Rights Reserved.
#
# Note to U.S. Government Users Restricted Rights:
# Use, duplication or disclosure restricted by GSA ADP Schedule
# Contract with IBM Corp.
#*******************************************************************************
# dlsall:
# display all cataloged datasets
#
syntax() {
	echo 'dlsall: display all cataloged datasets' >&2
	echo 'Syntax: dlsall [options]' >&2
	echo ' where [options] may be:' >&2
	echo '  -? : syntax' >&2
	echo '  -d : debug' >&2
}

debug=0
while getopts ":d" opt; do
	case ${opt} in
	d )
        debug=1
		;;
	\?)
        syntax
		exit 4
		;;
	esac
done
shift $(( OPTIND - 1 ))
if [ $# -ne 0 ]; then
	syntax
	exit 16
fi

master=$(pmc)
catalogs=$(pcatalog "$master" | awk '/CATALOG/ { print $2; }')
if [ $debug = 1 ]; then
	echo "Master Catalog: $master"
fi
for catalog in ${catalogs}; do
	if [ $debug = 1 ]; then
		echo "Catalog: $catalog"
	fi
	pcatalog "$catalog" | awk '/ALIAS/ { next } /CATALOG/ { next } // { print $1 " " $2; }'
done
