#!/bin/sh
#*******************************************************************************
# Licensed Materials - Property of IBM
# (c) Copyright IBM Corporation 2019. All Rights Reserved.
#
# Note to U.S. Government Users Restricted Rights:
# Use, duplication or disclosure restricted by GSA ADP Schedule
# Contract with IBM Corp.
#*******************************************************************************
#
#
trap cleanup 0 1 2 3 6 9 14 15
function cleanup {
    drm "${jclseq}" > /dev/null 2>&1
    jcan P "*" "$job" > /dev/null 2>&1
}

function issue_cmd {
    DESC='jsub: Submit a JCL job from a dataset'

    # IMS_COMMAND="DISPLAY ACT"
    JCL_TEMPLATE="/u/ibmuser/jobs/SPOCTMPL.jcl"

    if [[ -z ${TMPHLQ} ]]; then
        hlq=`hlq`
    else
        hlq="${TMPHLQ}"
    fi

    jclseq=`mvstmp ${hlq}`
    jcl=$(cat ${JCL_TEMPLATE} | sed "s@IMS_CMD@$1@")

    # create dataset
    dtouch -tSEQ "${jclseq}"
    decho "${jcl}" "${jclseq}"
    # submit job
    job=$(jsub "${jclseq}")

    # sleep for listing
    sleep 5

    # remove dataset
    drm "${jclseq}"

    # check output
    if jls | grep -q $job; then
        pjdd $job SYSPRINT
    else
        echo "jsub: $job not found.. job listing may be taking too long to refresh"
    fi
}

while true
do
    printf "Enter IMS Command> "
    read -r IMS_COMMAND
    issue_cmd "$IMS_COMMAND"
done