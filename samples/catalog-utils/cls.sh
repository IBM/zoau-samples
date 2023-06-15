#!/bin/sh
#*******************************************************************************
# Licensed Materials - Property of IBM
# (c) Copyright IBM Corporation 2019-2023. All Rights Reserved.
#
# Note to U.S. Government Users Restricted Rights:
# Use, duplication or disclosure restricted by GSA ADP Schedule
# Contract with IBM Corp.
#*******************************************************************************
# cls: list catalogs on the system
#
syntax() {
	echo "cls: list the catalogs on the system" >&2
	echo "Syntax: cls [-?h]" >&2
	echo 'Options are:' >&2
	echo ' -? -h : syntax' >&2
}

while getopts ":h" opt; do
	case ${opt} in
	\? | h )
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

master=$(./pmc)
catalogs=$(pcatalog "$master" | awk '/CATALOG/ { print $2; }')
echo "$catalogs"
