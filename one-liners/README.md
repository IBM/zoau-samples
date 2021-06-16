# one-liners

This is a list of sample ZOAU one-liners.  These are designed to accomplish a task from the
z/OS UNIX command line that would normally require using a TSO, JCL, or console interface.

Print empty cylinders on volume USER01:

```shell
echo "  LISTVTOC FORMAT,VOL=3390=USER01" | mvscmd --pgm=iehlist --sysprint=* --dd2=USER01,vol --sysin=stdin | grep 'EMPTY CYLINDERS'
```

Print online volumes:

```shell
opercmd 'd u,dasd,online,,65536'
```

Display status of all z/OS detected disk labels:

```shell
opercmd 'devserv qdasd,type=all'
```

Display any Global Resource Serialization Contention (ENQ and Latch):

```shell
opercmd 'd grs,c'
```

Display Unix System Services resource values and high water mark:

```shell
opercmd 'd omvs,limits'
```

Display JES2 spool available space:

```shell
opercmd '$d spl'
```

Display critical JES2 available resources with high water marks:

```shell
opercmd '$jddetails'
```

Check status of system catalogs:

```shell
opercmd 'f catalog,open'
```

List JES2 automated commands:

```shell
opercmd '$t a,all'
```

List any system outstanding replies:

```shell
opercmd 'd r,l'
```

Display all address spaces including those address spaces started by master scheduler at IPL time:

```shell
opercmd 'd a,all'
```

What Z hardware is being used and how many CPUs are available:

```shell
opercmd 'd m=cpu'
```

How much processing memory is available to this z/OS:

```shell
opercmd 'd m=stor'
```

IPL information:

```shell
opercmd 'd iplinfo'
```

I/O configuration used:

```shell
opercmd 'd ios,config'
```

Dump out the load module information for SYS1.NUCLEUS to stdout:

```shell
echo " LISTLOAD OUTPUT=MAP" | mvscmd --pgm=AMBLIST --syslib=SYS1.NUCLEUS --sysin=stdin --sysprint=stdout
```

Dump out the fixed, modified, and pageable LPA’s:

```shell
echo " LISTLPA" | mvscmd --pgm=AMBLIST --syslib=SYS1.NUCLEUS --sysin=stdin --sysprint=stdout
```

Get the current ‘MVS’ local time (as opposed to the Unix System Services local time):

```shell
opercmd 'd t' | awk ' { if ($5 == "IEE136I") { print substr($8,8,2) substr($8,11) " " substr($7,6) }}'
```

Compress a PDS in place:

```shell
mvscmd --args=COMPRESS --pgm=IEBCOPY --sysut2=${dsn},old --sysprint=stdout --sysin=dummy
```

Determine what address spaces are using a dataset:

```shell
opercmd 'd grs,res=(*,${dsn})'
```
