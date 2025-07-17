#!/bin/sh
#
# Create an alias of a dataset.
#
# Copyright IBM Corp 2025
#

set -x

if [ $# -lt 2 ]; then
    echo "Usage: $0 dataset alias"
    exit
fi

dataset=$(print "$1" | tr "[:lower:]" "[:upper:]")
alias=$(print "$2" | tr "[:lower:]" "[:upper:]")

output=$(mvscmdauth --pgm=IDCAMS --sysin=stdin --sysprint=* 2>&1 <<zz
  DEFINE ALIAS -
  (NAME($alias) -
  RELATE($dataset))
zz
)

rc=$?
if [ $rc -ne 0 ]; then
  echo "$output"
fi
