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
