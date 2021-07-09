#!/bin/sh
#
# run an ispf command under a vanilla ISPF environment
# See https://tech.mikefulton.ca/BatchISPF for details on running ISPF in batch
#
# Copyright IBM Corp. 2021
#

function ISPFDDDefine {
	ds=$1
	usrds=$2

	if [ "${usrds}" = "" ]; then
		echo "${ds}"
	else
		echo "${usrds}:${ds}"
	fi
	return 0
}
	
function ISPFDDOverride {
	ds=$1
	usrds=$2

	if [ "${usrds}" = "" ]; then
		echo "${ds}"
	else
		echo "${usrds}"
	fi
	return 0
}

function ISPFTempDS {
	tmp=`mvstmp $(hlq)`
	dtouch ${tmp}
	rc=$?
	echo "${tmp}"
	return $rc
}
	
function ISPFRmDS {
	drm $1
}

function Syntax {
	echo "$0 [opts]" >&2
	echo "Run the command(s) specified under ISPF." >&2
	echo "By default, ISPF runs a minimal environment." >&2
	echo "Each DDName can be overridden by exporting the corresponding environment variable to " >&2
	echo "  specify the concatenated datasets needed. ISPF base datasets will be appended to the end of the list." >&2
	echo "Options:" >&2
	echo "  -h : Print this help." >&2
	echo "  -v : Verbose mode - print out the DDNames sent to batch TSO (IKJEFT1B)." >&2
	echo "  - : Read the SYSTSIN DDName data from stdin, not from a dataset." >&2
	echo "Example 1:" >&2
	echo "  Read SYSTSIN from stdin. Run the program HW from library IBMUSER.USER.LOAD under ISPF. Turn off output from SYSTSPRT by setting the DDName to DUMMY." >&2
	echo "  (export SYSTSPRT=DUMMY; export ISPLLIB=IBMUSER.USER.LOAD; echo '  ISPSTART PGM(HW)' | ispfcmd.sh  -)" >&2
	echo "Example 2:" >&2
	echo "  Read SYSTSIN from stdin. Print out the DDNames to stdout. Run the REXX exec HW from IBMUSER.USER.REXX dataset." >&2
	echo "  (export SYSEXEC=IBMUSER.USER.REXX; echo '  ISPSTART CMD(HW)' | ./ispfcmd.sh -v -) "
}

#
# Mainline
#
#set -x

verbose=false
redirect=false
while getopts ":vh" opt; do
        case ${opt} in
	        v )
	                verbose=true
	                ;;
	        h )
			Syntax
			exit 4
			;;
	        \?)
	                if [ ${OPTARG} != "?" ]; then
	                        echo "Unknown Option: ${OPTARG}" >&2
	                fi
	                Syntax
	                exit 4
	                ;;
	esac
done
shift $(expr $OPTIND - 1 )

if [ $# -eq 1 ] && [ "$1" = "-" ]; then
	redirect=true
	shift 1
fi

if [ $# -ne 0 ]; then
	Syntax
	exit 8
fi

if ${redirect}; then
	SYSTSIN=`cat`
else
	if [ "${SYSTSIN}" = "" ]; then
		echo "Need to either provide SYSTSIN data from stdin or export SYSTSIN to the dataset to read" >&2
		Syntax
		exit 8
	fi
fi

if [ "${ISPF_HLQ}" = "" ]; then
	ISPF_HLQ='ISP'
fi

ISPLLIB=`ISPFDDOverride DUMMY ${ISPLLIB}`
ISPMLIB=`ISPFDDDefine "${ISPF_HLQ}.SISPMENU" ${ISPMLIB}`
ISPPLIB=`ISPFDDDefine "${ISPF_HLQ}.SISPMENU" ${ISPPLIB}`
ISPSLIB=`ISPFDDDefine "${ISPF_HLQ}.SISPSENU:${ISPF_HLQ}.SISPSLIB" ${ISPSLIB}`

ISPPROF_TMP=`ISPFTempDS`
if [ $? -gt 0 ]; then 
	exit 4
fi
ISPTLIB_TMP=`ISPFTempDS`
if [ $? -gt 0 ]; then 
	exit 4
fi
ISPTLIB=`ISPFDDDefine "${ISPF_HLQ}.SISPTENU" "${ISPTLIB}"`
SYSEXEC=`ISPFDDDefine "${ISPF_HLQ}.SISPEXEC" "${SYSEXEC}"`
SYSPROC=`ISPFDDDefine "${ISPF_HLQ}.SISPCLIB" "${SYSPROC}"`
ISPTLIB=`ISPFDDDefine "${ISPF_HLQ}.SISPTENU" "${ISPTLIB_TMP}"`
ISPLOG=`ISPFDDOverride DUMMY "${ISPLOG}"`
ISPCTL1=`ISPFDDOverride DUMMY "${ISPCTL1}"`
SYSTSPRT=`ISPFDDOverride stdout "${SYSTSPRT}"`
SYSPRINT=`ISPFDDOverride stdout "${SYSPRINT}"`

if [ "${ISPLLIB}" = "DUMMY" ]; then
	ISPLLIBDD=""
else
	ISPLLIBDD="--ISPLLIB=${ISPLLIB}"
fi

parms="--pgm=IKJEFT1B --ISPPROF=${ISPPROF_TMP} ${ISPLLIBDD} --ISPMLIB=${ISPMLIB} --ISPPLIB=${ISPPLIB}\
 --ISPSLIB=${ISPSLIB} --ISPTLIB=${ISPTLIB} --ISPCTL1=${ISPCTL1} --ISPLOG=${ISPLOG}\
 --SYSEXEC=${SYSEXEC} --SYSPROC=${SYSPROC} --SYSTSPRT=${SYSTSPRT} --SYSPRINT=${SYSPRINT}"

if ${verbose}; then
	echo "mvscmdauth ${parms}"
fi

if ${redirect}; then
	echo "${SYSTSIN}" |  mvscmdauth ${parms} --SYSTSIN=stdin
else
	mvscmdauth ${parms} --SYSTSIN=${SYSTSIN}
fi
rc=$?

ISPFRmDS ${ISPPROF_TMP}
ISPFRmDS ${ISPTLIB_TMP}
exit $rc 
