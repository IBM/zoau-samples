#!/bin/sh
#*******************************************************************************
#
# Copyright IBM Corp. 2023.
#
# Sample Material
#
# Licensee may copy and modify Source Components and Sample Materials for
# internal use only within the limits of the license rights under the Agreement
# for IBM Z Open Automation Utilities provided, however, that Licensee may not
# alter or delete any copyright information or notices contained in the Source
# Components or Sample Materials. IBM provides the Source Components and Sample
# Materials without obligation of support and "AS IS", WITH NO WARRANTY OF ANY
# KIND, EITHER EXPRESS OR IMPLIED, INCLUDING THE WARRANTY OF TITLE,
# NON-INFRINGEMENT OR NON-INTERFERENCE AND THE IMPLIED WARRANTIES AND
# CONDITIONS OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#******************************************************************************/
#
# psmpgzone - print SMP global zones for a CSI
# psmpgzone [<CSI-name>]
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
