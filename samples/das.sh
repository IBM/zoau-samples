#!/bin/sh

# das: disassemble specified load module.
# requires ZOAU to be installed on your system.
# This is a very simple wrapper to ASMDASM: https://www.ibm.com/docs/en/hla-and-tf/latest?topic=zos-jcl-example
# Feel free to enhance this script as appropriate.
#
# Copyright IBM Corp 2024.
#

Syntax()
{
	echo "das.sh is a utility for disassembling programs that reside in datasets."
	echo "Usage: das.sh DATASET MODULE"
	echo "Options:"
	echo "  --help, -h  displays help"
	echo "Examples:"
	echo "  das.sh CEE.SCEERUN CEEBINIT    Disassemble the CEEBINIT module."
	echo "Notes:"
	echo "  Output written to MODULE.das and MODULE.lst in current directory."
}

if [ $# -ne 2 ]; then
	Syntax
	if [ "$1" = "-h" ] || [ "$1" = "--help" ] ; then
		exit 0
	fi
	exit 4
fi
# Unfortunate: specify what dataset the ASMDASM program is in on your system
ASMDASM_DS='SYS1.ASMT.SASMMOD2'

ds=$1
mod=$2
das="$PWD/${mod}.das"
lst="$PWD/${mod}.lst"

rm -f "${das}" "${lst}"
touch "${das}" "${lst}"
if [ $? -gt 0 ]; then
	echo "Unable to set up disassembly and listing files ${das} and ${lst}" >&2
	exit 4
fi

echo "${mod}" | mvscmd --pgm=asmdasm --steplib=${ASMDASM_DS} --syslib="${ds}(${mod})" --sysin=stdin --sysprint="${lst}" --syspunch="${das}"
