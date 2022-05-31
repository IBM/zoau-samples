# README

This directory contains a number of sample scripts that use ZOAU in various ways.

See [one-liners.md](one-liners.md) for a number of short examples that accomplish different tasks.
There are also longer scripts that can be useful:

|Name|Purpose|
|----|-------|
|[chkptf.sh](chkptf.sh) | Print out what PTFs have been applied to a particular CSI/Target Zone.
|[dcat.sh](dcat.sh) | Cat sequential datasets or PDS members (supports wildcards in dataset and member).
|[dump_and_filter_racf.sh](dump_and_filter_racf.sh) | Dump and Filter RACF database for two record types.
|[rcvptf.sh](rcvptf.sh) | Receive a PTF that you have uploaded to the Unix System Services zFS file system from ShopZ.
|[ispfcmd.sh](ispfcmd.sh) | Run an ISPF command from Unix System Services.
|[mps.sh](mps.sh) | Display active MVS processes.
|[zcx_versions.py](zcx_versions.py) | Check running zCX instances to see if any can be upgraded.
|[smpe_list.py](smpe_list.py) | Sample code showing how to convert from JCL to Python using the list feature of SMPE.
|[SMPElistDefaults.yaml](SMPElistDefaults.yaml) | Definitions that `smpe_list.py` needs. Must be put in the same directory as `smpe_list.py`. Changes need to be made to match the user's system.
|[console.sh](console.sh)|Run `opercmd` interactively.
|[runjcl.py](runjcl.py)| Submit a JCL job and print job status.
|[runrexx.py](runrexx.py)| Run a Rexx program in IKJEFT01 and return the data for processing
