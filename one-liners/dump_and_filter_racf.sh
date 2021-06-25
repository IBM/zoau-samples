#!/bin/sh
#
# Dump and Filter RACF database for 2 record types:
# http://tech.mikefulton.ca/IRRDBU00RecordTypes
#
# Copyright 2021 IBM Corp.
#

mvscmd --pgm=sort --sortin=${tempds} --sysout=${err} --sortout=${output} --sysin=stdin <<zz
 SORT    FIELDS=COPY
 INCLUDE COND=(5,4,CH,EQ,C'0207',OR,
              (5,4,CH,EQ,C'0560',AND,
               257,8,CH,EQ,C'DIGTRING'))
 OPTION  VLSHRT
zz
