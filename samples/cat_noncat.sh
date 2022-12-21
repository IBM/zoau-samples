#!/bin/sh

mvscmd --pgm=IEBGENER --sysprint=* --sysin=dummy --sysut2="TSSXP.TESTIN.SEQ" --sysut1="SYS1.NONCAT.PARMLIB(TESTING),SHR,volumes=RNDCM1"
cat "//'TSSXP.TESTIN.SEQ'"