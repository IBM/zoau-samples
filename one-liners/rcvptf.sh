#!/bin/sh
#
# Receive a PTF that you have uploaded to the Unix System Services
# zFS file system from ShopZ.
#
# Copyright 2021 IBM Corp.
#

CSI='MVS.GLOBAL.CSI'
ZONE='MVST'
SMPNTS='/tmp/smpnts.CEE240'
ORDER='U02212680'
mvscmdauth --pgm=GIMSMP --smpcsi=${CSI} --smpout=* --smplog=* --smpnts="${SMPNTS}" --sysprint=* --smpcntl=stdin <<zz
  SET BDY(GLOBAL).
  RECEIVE FROMNTS('${ORDER}').
zz
