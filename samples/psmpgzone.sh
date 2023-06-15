#!/bin/sh
#
# psmpgzone - print SMP global zones for a CSI
# psmpgzone [<CSI-name>]
#
# Copyright IBM Corp. 2023
#

syntax() {
	echo "psmpgzone: print SMP global zones for the specified CSI" >&2
	echo "Syntax: psmpgzone [<CSI-name>]" >&2
	echo "  If no CSI is specified, the environment variable SMP_CSI is used" >&2
	echo "  If the environment variable is not specified, an error is issued" >&2
}

set -o noglob
while getopts ":h" opt; do
  case ${opt} in
    \? | h )
      syntax
      exit 4
      ;;
  esac
done

if [ $# -gt 1 ]; then
	echo "More than 1 parameter specified"
	syntax
	exit 4
fi

if [ $# -eq 1 ]; then
	CSI=$1;
else
    	if [ -z "$SMP_CSI" ]; then
		echo "Need to specify the CSI-name on invocation or define SMP_CSI"
		syntax
		exit 4
	fi
	CSI=$SMP_CSI;
fi

mvscmdauth --pgm=GIMSMP --smplist=* --smpcsi="$CSI" --smpcntl=stdin <<zz
 SET BDY(GLOBAL).
 LIST GZONE.
zz
