# one-liners

This is a list of sample ZOAU one-liners.  These are designed to accomplish a task from the
z/OS UNIX command line that would normally require using a TSO, JCL, or console interface.

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
mvscmd --args=COMPRESS --pgm=IEBCOPY --sysut2=${dsn},old --sysprint=* --sysin=dummy
```

Determine what address spaces are using a dataset:

```shell
opercmd 'd grs,res=(*,${dsn})'
```
