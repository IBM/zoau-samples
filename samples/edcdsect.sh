#!/bin/env bash

# 
# EDCDSECT USS invocation. 'edcdsect -?' for help (see below)
#
syntax()
{
  printf '%s\n' "edcdsect is a utility for generating C structure mappings for Assembler DSECTs
Usage: edcdsect [OPTION] [PARAMETERS]...

Options:
  -h, --help        display this help and exit.
  -v, --verbose     run in verbose mode.

Parameters:
  <file>            The assembler file to process

Examples:
  Process a single macro DCBD into a structure:
    echo '      DCBD' | edcdsect

  Process an assembler file dcbd.s into a structure:
    edcdsect dcbd.s
"
}

verbose=false
if [ $# -gt 0 ]; then
  if [ "$1" = "-h" ] || [ "$1" = '--help' ]; then
    syntax
    exit 0
  fi
  if [ "$1" = "-v" ] || [ "$1" = '--verbose' ]; then
    verbose=true
    shift
  fi
fi

if [ $# -gt 0 ]; then
  if [ -e "$1" ]; then
    input="$1"
  else
    printf 'Unable to open %s for read.\n' "$1" >&2
    syntax
    exit 4
  fi
else
  if [ -t 0 ]; then
    printf 'Need to specify assembler code to process.\n' >&2
    syntax
    exit 4
  fi
fi

struct_name=''
if [ "${input}" != "" ]; then
  source=$(cat "${input}")
else
  source=""
  OLDIFS="$IFS"
  IFS='' 
  while read line; do
    source="${source}
${line}"
  done </dev/stdin
  IFS="$OLDIFS"
fi

compiler="CBC.SCCNCMP"

asm='ASMA90'
asm_opts='SUPRWARN(425,434),GOFF,ADATA,NOTERM,NODECK,NOOBJECT,LIST'
sysadata=$(mvstmp $(hlq))
if ! dtouch -rvb -l8144 -tseq "${sysadata}" ; then
  printf 'Unable to allocate SYSADATA temporary dataset %s' "${sysadata}"
  exit 4
fi

listing=$(printf '%s\n' "${source}" | mvscmd --pgm="${asm}" --args="${asm_opts}" --syslib=SYS1.MACLIB --sysadata="${sysadata}" --sysin=stdin --sysprint=* --syspunch=DUMMY --syslin=DUMMY)
rc=$?

if [ $rc -gt 4 ] ; then
  printf '%s\n' "${listing}"
  exit $rc
fi

if ${verbose} ; then
  printf 'Assembler Listing:\n%s\n' "${listing}" >&2
fi

tmp_output=$(mvstmp $(hlq))
if ! dtouch -rvb -l137 -tseq "${tmp_output}" ; then
  printf 'Unable to allocate DSECT temporary output dataset %s' "${tmp_output}"
  exit 4
fi
err=$(mvscmd --pgm=CCNEDSCT --args="SECT(${struct_name}),EQU,NODEF,UNNAMED" --steplib="${compiler}" --sysadata="${sysadata}" --edcdsect="${tmp_output}" --sysprint=stdout --sysout=stdout)
rc=$?

cat "//'${tmp_output}'"
if [ $rc -gt 0 ]; then
  printf '%s\n' "${err}" >&2
  exit $rc
fi

if ${verbose} ; then
  printf 'CCNEDSCT Listing:\n%s\n' "${err}" >&2
fi

drm -f "${sysadata}"
drm -f "${tmp_output}"
