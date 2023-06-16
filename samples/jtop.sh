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
# jtop: list the jobs in a simplistic 'top' like format (sorted by CT column 
#       but can be sorted by any column by piping through sort)
#
syntax() {
	echo "Syntax: " >&2
	echo " jtop [-?vd] " >&2
	echo " Print out MVS jobs running " >&2
	echo " For each job, the following fields are printed out " >&2
	echo " Jobname, APPC/MVS transaction program name, initiator address space name" >&2
	echo " Stepname " >&2
	echo " Procedure stepname or requesting userid " >&2
	echo " Type of job " >&2
	echo " Address space identifier " >&2
	echo " A=<...> Address space status" >&2
	echo " PER=<...> Program event recording (PER) activity" >&2
	echo " SMC=<...> Number of outstanding step-must-complete requests" >&2
	echo " AFF=<...> Processor affinity" >&2
	echo " ET=<...> Elapsed time since initiation" >&2
	echo " Accumulated processor time" >&2
	echo " WUID=<...> Work unit identifier" >&2
	echo " USERID=<...> Transaction requestor's userid" >&2
	echo " Central (real) address range (V=R only)" >&2
	echo "Example output line:" >&2
	echo "IZUSVR1  IZUSVR1  ZOSMF    IN   SO  A=0046   PER=NO   SMC=000 PGN=N/A  DMN=N/A  AFF=NONE CT>03.53.09  ET>73.27.38 WUID=STC02621 USERID=IZUSVR   WKL=STARTED  SCL=STCLOM   P=1 RGP=N/A      SRVR=NO  QSC=NO" >&2
	echo "IZUSVR1 is currently running Step IZUSVR1 as user ZOSMF. Running in address space 0046 with PER inactive. No outstanding 'step-must-complete'. No processor affinity" >&2
	echo "  Cumulative processor time is 3 hours 53 minutes 9 seconds. Elapsed time is 73 hours, 27 minutes, 38 seconds. Work Unit Identifier STC02621. Requested by user IZUSVR." >&2
	echo "  Unknown fields (please help): IN ?? SO?? PGN??DMN??  WKL?? SCL?? P? RGP? SRV?? QSC??" >&2
}

while getopts ":h" opt; do
	case ${opt} in
	\? | h )
		if [ "$OPTARG" != "?" ]; then
			echo "Invalid option: -$OPTARG" >&2
		fi
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

orig=$(opercmd '$d condef' |
	awk ' {
		ind = index($0, "DISPMAX=");
		if (ind > 0) {
			result=substr($0,ind+8);
			ind = index(result, ",");
			if (ind > 0) {
				result=substr(result,ind-1);
			}
			print result;
		}
	}')

opercmd '$t condef,dispmax=1000000' >/dev/null 2>&1
out=$(opercmd 'd jobs,all')
# set the condef back again...
opercmd "\$t condef,dispmax=${orig}" >/dev/null 2>&1
#
#Sample raw output:
#
#S0W1      2018005  11:09:37.20             IEE115I 11.09.37 2018.005 ACTIVITY 846
#                                            JOBS     M/S    TS USERS    SYSAS    INITS   ACTIVE/MAX VTAM     OAS
#                                           00018    00030    00000      00033    00030    00000/00040       00038
#                                            *MASTER* *MASTER*          NSW  *   A=0001   PER=NO   SMC=000
#                                                                                PGN=N/A  DMN=N/A  AFF=NONE
#                                                                                CT=00.18.12  ET=00402.40
#                                                                                WUID=STC03388 USERID=+MASTER+
#                                                                                WKL=SYSTEM   SCL=SYSTEM   P=1
#                                                                                RGP=N/A      SRVR=NO  QSC=NO
#                                            PCAUTH   PCAUTH            NSW  *   A=0002   PER=NO   SMC=000
#                                                                                PGN=N/A  DMN=N/A  AFF=NONE
#                                                                                CT=000.010S  ET=00402.40
#                                                                                WKL=SYSTEM   SCL=SYSTEM   P=1
#                                                                                RGP=N/A      SRVR=NO  QSC=NO
#
#Fields: (see syntax above)

echo "$out" | awk '
function ltrim(s) { sub(/^[ \t\r\n]+/, "", s); return s }
function rtrim(s) { sub(/[ \t\r\n]+$/, "", s); return s }
function trim(s)  { return rtrim(ltrim(s)); }
BEGIN { inHeader=0; firstLine=0; inLine=0; count=0; blank=" "; dot="."; altct="CT>"; altet="ET>"; }
       /^[ ]+JOBS[ ]+M.S[ ]+TS USERS[ ]+SYSAS[ ]+INITS[ ]+ACTIVE.MAX VTAM[ ]+OAS/ { inHeader=1; next; }
       /^[ ]+PGN=/ { second=trim($0); next; }
       /^[ ]+CT=/  	{
				third=trim($0);
				if (substr(third,11,1) != "S") {
					third=altct substr(third,4);
				}
				if (substr(third,19,1) == "." || substr(third,17,8) == "NOTAVAIL") {
					third=substr(third,1,13) altet substr(third,17);
				}
				next;
			}
       /^[ ]+WUID=/  	{
				fourth=trim($0);
				fourth=sprintf("%-29s", fourth)
				if (substr(fourth,15,1) == " ") {
					fourth=substr(fourth,1,14) dot substr(fourth,16)
				}
				next;
			}
       /^[ ]+WKL=/  { fifth=trim($0); next; }
       /^[ ]+RGP=/  { sixth=trim($0); firstLine=1; print first blank second blank third blank fourth blank fifth blank sixth; next; }
       /^[ ]+/ 	{
			if (inHeader) {
				jobInfo=$0; inHeader=0; firstLine=1; next;
			} else if (firstLine) {
				first=trim($0);
				if (substr(first,20,1) == " ") {
					first=substr(first,1,18) dot substr(first,20);
				}
				inLine=1; firstLine=0; next;
			}
		}
     ' | sort -b -r -k 12.1
