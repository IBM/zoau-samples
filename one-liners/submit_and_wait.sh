#!/bin/sh
#
# Routine to submit short running JCL and wait for output.
#
# Copyright IBM Corp 2021.
#set -x
function runJCL {
	jcl="$1"
	maxwait=$2
	if [ "${jcl#*/}" = "${jcl}" ]; then
		# Dataset - no slashes
		jcl="//'${jcl}'"
	fi
	jobid=`submit $jcl | awk '{ print $2 }'`
	rc=$?
	if [ $rc -gt 0 ]; then
		return $rc
	fi
	currwait=0
	while [ true ]; do
		status=`jls 2>/dev/null ${jobid}`
		state=`echo ${status} | awk ' { print $4; }'`
		case "$state" in
		CC)
			rc=`echo ${status} | awk ' { print $5; }'`
			if [ $rc -gt 0 ]; then
				echo "Job ${jobid} failed with rc: $rc" >&2
			fi
			return ${rc}
		;;
		ABEND*)
			echo "Job ${jobid} ABENDED" >&2
			return 32
		;;
		JCLERR)
			echo "Job ${jobid} has a JCL error" >&2
			return 32
		;;
		*)
			sleep 1
			currwait=$((currwait+1))
		esac
		if [ ${currwait} -gt ${maxwait} ]; then
			echo "Timed out waiting for job ${jobid} to complete" >&2
			return -1
		fi
	done
}

runJCL "$1" 10
exit $?
