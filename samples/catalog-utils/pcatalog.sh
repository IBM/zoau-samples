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
# pcatalog: print a catalog of all entries
#

syntax() {
	echo "pcatalog: print a catalog of all entries" >&2
	echo "Syntax: " >&2
	echo ' pcatalog [-?h] <catalog dataset>' >&2
	echo 'Options are:' >&2
	echo ' -? : syntax' >&2
	echo '  Example: pcatalog `pmc` <-- print the master catalog' >&2
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
if [ $# -ne 1 ]; then
	echo 'Syntax: pcatalog <catalog>'
	exit 16
fi

catalog=$(echo "$1" | tr '[:lower:]' '[:upper:]')

input=" LISTCAT CATALOG('$catalog') VOLUME"

output=$(echo "$input" | mvscmdauth --pgm=IDCAMS --sysprint=* --sysin=stdin)
echo "$output" | dsfilter
exit 0
