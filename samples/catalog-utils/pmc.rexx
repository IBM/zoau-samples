/* REXX */
/*******************************************************************************
*
* Copyright IBM Corp. 2023.
*
* Sample Material
*
* Licensee may copy and modify Source Components and Sample Materials for
* internal use only within the limits of the license rights under the Agreement
* for IBM Z Open Automation Utilities provided, however, that Licensee may not
* alter or delete any copyright information or notices contained in the Source
* Components or Sample Materials. IBM provides the Source Components and Sample
* Materials without obligation of support and "AS IS", WITH NO WARRANTY OF ANY
* KIND, EITHER EXPRESS OR IMPLIED, INCLUDING THE WARRANTY OF TITLE,
* NON-INFRINGEMENT OR NON-INTERFERENCE AND THE IMPLIED WARRANTIES AND
* CONDITIONS OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
*
*******************************************************************************/
/* Print out the name of the master catalog.
 * Syntax: pmc [-v]
 * If -v option specified, also print out the master catalog VOLSER
 * Mark Zelden's IPLINFO.TXT was used to create this routine. 
 * All errors mine
 */
Parse arg opts .

If (opts='-v') Then Do
  vol=1
End
Else Do
  vol=0
End

If (opts='-?') Then Do
  return Syntax()
End

CVT      = C2d(Storage(10,4))                /* point to CVT         */         
AMCBS    = C2d(Storage(D2x(CVT + 256),4))    /* point to AMCBS       */         
If Bitand(CVTOSLV2,'80'x) <> '80'x then do   /*Use CAXWA B4 OS/390 R4*/         
  ACB      = C2d(Storage(D2x(AMCBS + 8),4))  /* point to ACB         */         
  CAXWA    = C2d(Storage(D2x(ACB + 64),4))   /* point to CAXWA       */         
  MCATDSN  = Storage(D2x(CAXWA + 52),44)     /* master catalog dsn   */         
  MCATDSN  = Strip(MCATDSN,'T')              /* remove trailing blnks*/         
  MCATUCB  = C2d(Storage(D2x(CAXWA + 28),4)) /* point to mcat UCB    */         
  MCATVOL  = Storage(D2x(MCATUCB + 28),6)    /* master catalog VOLSER*/         
End                                                                             
Else do                                      /* OS/390 R4 and above  */         
  MCATDSN  = Strip(Substr(IPASCAT,11,44))    /* master catalog dsn   */         
  MCATVOL  = Substr(IPASCAT,1,6)             /* master catalog VOLSER*/                                   
End

If (vol) Then Do
  Say MCATDSN MCATVOL
End
Else Do
  Say MCATDSN
End
Return 0

Syntax: Procedure
  Call SayErr 'pmc: print out the master catalog'
  Call SayErr 'Syntax: pmc [-?v]'
  Call SayErr 'Options:'
  Call SayErr '  -? : show syntax'
  Call SayErr '  -v : print the volume the master catalog resides on'
Return 4

SayErr: Procedure
Parse Arg text

call syscalls 'ON'
buf=text || esc_n
address syscall "write" 2 "buf"
Return 0
