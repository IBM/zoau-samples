#!/bin/bash
#
# Create a Unix-style interactive shell for MVS, SDSF
# or subsystem commands. Adjust $ssid to handle prefixes.
#
# Usage:
#
#     ./console.sh       - start an opercmd console
#
#     ./console.sh SSID  - start a console for a subsystem
#
# Example:
#
#     ./console.sh MQ01
#      !MQ01> START QMGR
#
# Copyright IBM Corp. 2021
#

if [ -z "$1" ]
then
    prefix="opercmd"
else
    prefix="$1"
    ssid="!$1"  # Replace prefix with your SSID prefix
fi

while true
do
    read -p "$prefix:> "
    opercmd "${ssid} $REPLY"
done