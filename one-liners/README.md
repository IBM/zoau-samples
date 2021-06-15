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
