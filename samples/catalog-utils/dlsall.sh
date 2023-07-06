#!/bin/sh
# *******************************************************************************
# 
#  Copyright IBM Corp. 2023.
# 
#  Sample Material
# 
#  Licensee may copy and modify Source Components and Sample Materials for
#  internal use only within the limits of the license rights under the Agreement
#  for IBM Z Open Automation Utilities provided, however, that Licensee may not
#  alter or delete any copyright information or notices contained in the Source
#  Components or Sample Materials. IBM provides the Source Components and Sample
#  Materials without obligation of support and "AS IS", WITH NO WARRANTY OF ANY
#  KIND, EITHER EXPRESS OR IMPLIED, INCLUDING THE WARRANTY OF TITLE,
#  NON-INFRINGEMENT OR NON-INTERFERENCE AND THE IMPLIED WARRANTIES AND
#  CONDITIONS OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
# 
# ******************************************************************************/
#
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
