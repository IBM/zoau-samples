#!/bin/sh
#
# pcatalog: print a catalog of all entries
#
# Copyright IBM Corp. 2023
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
