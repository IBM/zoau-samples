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
# smpapply - apply a PTF
# smpapply <ptf> <zone> [<CSI-name>]
#

syntax() {
	echo "Syntax: smpapply [-?d] <ptf> <zone> [<CSI-name>]" >&2
	echo 'Options:' >&2
	echo ' -? : syntax' >&2
	echo ' -d : run in debug mode' >&2
	echo "  applies the previously received ptf into the target zone and CSI" >&2
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

if [ $# -gt 3 ]; then
	echo "More than 3 parameters specified" >&2
	syntax
	exit 4
fi
if [ $# -lt 2 ]; then
	echo "Need to specify the ptf to apply, and what zone to apply it to" >&2
	syntax
	exit 4
fi
ptf=$(echo "$1" | tr '[:lower:]' '[:upper:]')
zone=$(echo "$2" | tr '[:lower:]' '[:upper:]')

if [ $# -eq 3 ]; then
	CSI=$3;
else
	if [ -z "$SMP_CSI" ]; then 
		echo "Need to specify the CSI-name on invocation or define SMP_CSI" >&2
		syntax
		exit 4
	fi
	CSI="$SMP_CSI"
fi

csids=$(vls "$CSI")
if [ -z "$csids" ]; then 
	echo "CSI dataset ${CSI} does not exist" >&2
	syntax
	exit 8
fi


mvscmdauth --pgm=GIMSMP --smpcsi="$CSI" --smphold=DUMMY --smpcntl=stdin --smpout=* <<zz
 SET BOUNDARY(${zone}) .                                            
  APPLY CHECK                                                  
        BYPASS(HOLDSYS)      
        S(${ptf})                                             
  .                                                            
  APPLY                                                        
        S(${ptf})                                             
        BYPASS(HOLDSYS)     
        RC(APPLY=04)                                           
  .                                                            
zz

exit $?
