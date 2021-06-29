#!/bin/sh
#
# Print out what PTFs you have applied to a particular CSI/Target Zone:
#
# Copyright IBM Corp. 2021
#

CSI='MVS.GLOBAL.CSI'
ZONE='MVST'
out=/tmp/$$.out
rpt=/tmp/$$.rpt
log=/tmp/$$.log
touch $out $rpt $log
mvscmdauth --pgm=gimsmp --smpcsi=${CSI} --smpout=${out} --smprpt=${rpt} --smplog=${log} --smplist=* --smpcntl=stdin <<zz
  SET BOUNDARY(${ZONE}).
  LIST PTFS.
zz
rc=$?
if [ $rc -gt 0 ]; then
	cat $out $rpt $log >&2
	exit $rc
else
	rm $out $rpt $log
fi
