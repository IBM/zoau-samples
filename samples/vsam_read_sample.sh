#!/bin/bash

# Purpose: Use ZOAU's mvscmdauth to run IDCAMS and print the contents of a VSAM data set
#          in character format. The data set is specified as OME.QUAL.D250430.T171115.

# Run IDCAMS to print the VSAM data set
mvscmdauth --pgm=IDCAMS --sysprint=* --sysin=stdin --INVSAM=OME.QUAL.D250430.T171115 <<EOF
  PRINT INFILE(INVSAM) CHARACTER 
EOF
