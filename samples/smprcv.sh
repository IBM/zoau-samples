#!/bin/sh
#
# smprcv - receive a PTF from a file
# smprcv <ptf-file> [<CSI-name>]
#
# Copyright IBM Corp. 2023
#

syntax() {
	echo "smprcv: receives the ptf from the specified file into the target CSI" >&2
	echo "Syntax: smprcv [-?vd] [-Q<tmphlq>] <ptf-file> [<CSI-name>]" >&2
	echo 'Options are:' >&2
	echo ' -? : syntax' >&2
	echo ' -d : run in debug mode' >&2
	echo ' -v : run in verbose mode' >&2
	echo ' -Q: use an alternative high-level qualifier for temporary dataset name
     will override TMPHLQ environment variable as well' >&2
  	echo 'ENVIRONMENT VARIABLES
     TMPHLQ: overrides the current high-level qualifier used for temporary dataset name' >&2
	echo "  If no CSI is specified, the environment variable SMP_CSI is used" >&2
	echo "  If the environment variable is not specified, an error is issued" >&2
}

debug=0
while getopts ":d" opt; do
    case $opt in
        d)
            debug=1
            ;;
        \?)
            if [ "$OPTARG" != "?" ]; then
                echo "Invalid option: -$OPTARG" >&2
            fi
            syntax
            exit 4
            ;;
    esac
done

shift $(( OPTIND - 1 ))
if [ $# -gt 2 ]; then
	echo "More than 2 parameters specified" >&2
	syntax
	exit 4
fi
if [ $# -eq 0 ]; then
	echo "Need to specify the ptf file to apply" >&2
	syntax
	exit 4
fi
ptfhfs=$1

if [ $# -eq 2 ]; then
	CSI=$2;
else
	if [ -z "$SMP_CSI" ]; then 
		echo "Need to specify the CSI-name on invocation or define SMP_CSI" >&2
		syntax
		exit 4
	fi
	CSI=$SMP_CSI;
fi

if [ ! -f "$ptfhfs" ]; then 
	echo "PTF file: $ptfhfs does not exist" >&2
	syntax
	exit 8
fi

csids=$(vls "$CSI")
if [ -z "$csids" ]; then 
	echo "CSI dataset $CSI does not exist" >&2
	syntax
	exit 8
fi


if [ -z "$TMPHLQ" ]; then
	hlq=$(hlq)
else
	hlq="$TMPHLQ"
fi
ptfin=$(mvstmp "$hlq.SMPRCV")
drm -f "$ptfin"
dtouch -tseq "$ptfin"
cp -B "$ptfhfs" "//'$ptfin'"
mvscmdauth --pgm=GIMSMP --smpcsi="$CSI" --smphold=DUMMY --smpptfin="$ptfin" --smpcntl=stdin --smpout=* <<zz
 SET BOUNDARY(GLOBAL).
 RECEIVE LIST.
zz
rc=$?

if [ ! "$debug" ]; then
	drm -f "$ptfin"
fi

exit $rc
