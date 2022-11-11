# one-liners
This is a list of sample ZOAU one-liners.  These are designed to accomplish a task from the
z/OS UNIX command line that would normally require using a TSO, JCL, or console interface.

- [one-liners](#one-liners)
    - [Print PTFs](#print-ptfs)
    - [Cat data sets](#cat-data-sets)
    - [Dump RACF](#dump-racf)
    - [Report Empty Cylinders](#report-empty-cylinders)
    - [Print online volumes](#print-online-volumes)
    - [Print all files...](#print-all-files)
    - [Display disk labels](#display-disk-labels)
    - [Display GRS contention](#display-grs-contention)
    - [Display z/OS UNIX System Services limits](#display-zos-unix-system-services-limits)
    - [Display JES2 spool available space](#display-jes2-spool-available-space)
    - [Display JES2 details](#display-jes2-details)
    - [Display status of system catalogs](#display-status-of-system-catalogs)
    - [List JES2 automated commands](#list-jes2-automated-commands)
    - [List any system outstanding replies](#list-any-system-outstanding-replies)
    - [Display Address Spaces](#display-address-spaces)
    - [Display CPUs](#display-cpus)
    - [Display memory](#display-memory)
    - [Display IPL information](#display-ipl-information)
    - [Display I/O configuration used](#display-io-configuration-used)
    - [Display SMS info](#display-sms-info)
    - [Display nucleus information](#display-nucleus-information)
    - [Display LPA info](#display-lpa-info)
    - [Display MVS local time](#display-mvs-local-time)
    - [Compress a PDS in place](#compress-a-pds-in-place)
    - [Determine what address spaces are using a data set](#determine-what-address-spaces-are-using-a-data-set)
    - [Run commmand and 'wait'](#run-commmand-and-wait)
    - [Print a job's console log](#print-a-jobs-console-log)
- [Data Set Operations](#data-set-operations)
    - [Delete](#delete)
    - [Delete on volume](#delete-on-volume)
    - [Rename](#rename)

### Print PTFs
Print out what PTFs you have applied to a particular CSI/Target Zone: [chkptf](chkptf.sh)

### Cat data sets
Cat sequential data sets, or PDS members (supports wildcards in data set and member): [dcat](dcat.sh)

### Dump RACF
Dump and Filter RACF database for 2 record types: [dump_and_filter_racf](dump_and_filter_racf.sh)

### Report Empty Cylinders
Print empty cylinders on volume USER01:

```shell
echo "  LISTVTOC FORMAT,VOL=3390=USER01" | mvscmd --pgm=iehlist --sysprint=* --dd2=USER01,vol --sysin=stdin | grep 'EMPTY CYLINDERS'
```

### Print online volumes

```shell
opercmd 'd u,dasd,online,,65536'
```

### Print all files...

Print all files on all online volumes:
* Write out the online volumes to stdout, then strip off the 5 header lines and the one trailer line, using awk to print just the volume serial name and store it into the variable _volumes_.
* For each volume in volumes, print out the volume table of contents if there is no error getting the VTOC for the volume. This will list cataloged and uncataloged data sets. 
* __Note__: You could add a _grep_ or _awk_ filter on the end to restrict the output to files of a particular pattern.
```shell
volumes=`opercmd 'd u,dasd,online,,65536' | tail +5 | sed \\$d | awk '{ print $4; }'` 
for volume in $volumes; do
  out=`vtocls $volume 2>/dev/null` 
  if [ $? -eq 0 ]; then 
    echo "$out" 
  fi
done
```

### Display disk labels
Display status of all z/OS detected disk labels:

```shell
opercmd 'devserv qdasd,type=all'
```

### Display GRS contention
Display any Global Resource Serialization Contention (ENQ and Latch):

```shell
opercmd 'd grs,c'
```

### Display z/OS UNIX System Services limits
Display Unix System Services resource values and high water mark:

```shell
opercmd 'd omvs,limits'
```
### Display JES2 spool available space

```shell
opercmd '$d spl'
```

### Display JES2 details
Display critical JES2 available resources with high water marks:

```shell
opercmd '$jddetails'
```

### Display status of system catalogs

```shell
opercmd 'f catalog,open'
```

### List JES2 automated commands

```shell
opercmd '$t a,all'
```

### List any system outstanding replies

```shell
opercmd 'd r,l'
```

### Display Address Spaces
Display all address spaces including those address spaces started by master scheduler at IPL time:

```shell
opercmd 'd a,all'
```

### Display CPUs
What Z hardware is being used and how many CPUs are available:

```shell
opercmd 'd m=cpu'
```

### Display memory
How much processing memory is available to this z/OS:

```shell
opercmd 'd m=stor'
```

### Display IPL information

```shell
opercmd 'd iplinfo'
```

### Display I/O configuration used

```shell
opercmd 'd ios,config'
```

### Display SMS info
Lists information about your SMS managed volumes:

```shell
opercmd 'D SMS,STORGRP(ALL),LISTVOL'
```

### Display nucleus information
Dump out the load module information for SYS1.NUCLEUS to stdout:

```shell
echo " LISTLOAD OUTPUT=MAP" | mvscmd --pgm=AMBLIST --syslib=SYS1.NUCLEUS --sysin=stdin --sysprint=stdout
```

### Display LPA info
Dump out the fixed, modified, and pageable LPA's:

```shell
echo " LISTLPA" | mvscmd --pgm=AMBLIST --syslib=SYS1.NUCLEUS --sysin=stdin --sysprint=stdout
```

### Display MVS local time
Get the current __MVS__ local time (as opposed to the Unix System Services local time):

```shell
opercmd 'd t' | awk ' { if ($5 == "IEE136I") { print substr($8,8,2) substr($8,11) " " substr($7,6) }}'
```

### Compress a PDS in place

```shell
mvscmd --args=COMPRESS --pgm=IEBCOPY --sysut2=${dsn},old --sysprint=stdout --sysin=dummy
```

### Determine what address spaces are using a data set

```shell
opercmd 'd grs,res=(*,${dsn})'
```

### Run commmand and 'wait'
Run an operator command and loop until you get the expected output:

```shell
function runCmd {
  cmd="$1"
  pattern="$2"
  timestamp=`opercmd "${cmd}" | tail -1 | awk '{ print $2 " " $3; }'`
  while [ true ]; do
    pcon -s ${timestamp} | grep "${pattern}"
    if [ $? -eq 0 ]; then
      break;
    fi
    sleep 3
  done
}
```

### Print a job's console log
Print out the console log for just a particular job. In this example, the job is
STC01455 and it will get the last day of output from the SYSLOG. See
<https://tech.mikefulton.ca/SYSLOGFormat> for details on the system log format

```shell
job="STC01455"
opts='-d'
pcon ${opts} | awk -vjob="${job}" '
 BEGIN { trace=0 }
 /^O|^M|^N|^W|^X/ { if ($6 == job) { trace=1; print; } else { trace=0; }  }
 /^S|^L|^E|^D/  { if (trace) { print; } }
```

# Data Set Operations

### Delete
Delete data set `HLQ.MLQ.LLQ` using mvscmd and idcams  
```shell
  echo " DELETE HLQ.MLQ.LLQ " | mvscmdauth --verbose --pgm=IDCAMS --sysprint=* --sysin=stdin
```

### Delete on volume
Delete data set `HLQ.MLQ.LLQ` on a particular volume using mvscmd and idcams  
``` shell
  echo "  DELETE HLQ.MLQ.LLQ FILE(DD1) NVR" | mvscmdauth --pgm=IDCAMS --sysprint=* --dd1=USERVOL,vol --sysin=stdin
```

### Rename
Rename data set `HLQ.MLQ.LLQ` to `USER.MLQ.LLQ`using mvscmd and idcams  
``` shell
  echo " ALTER HLQ.MLQ.LLQ NEWNAME(USER.MLQ.LLQ)" |mvscmdauth --verbose --pgm=IDCAMS --sysprint=* --sysin=stdin
```
