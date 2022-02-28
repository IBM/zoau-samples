from zoautil_py import jobs, datasets

jcl_sample = """//UPTIME    JOB MSGLEVEL=(1,1),
//  MSGCLASS=A,CLASS=A
//******************************************************************************
//* Configure the job card as needed, most common keyword parameters often
//* needing editing are:
//* CLASS: Used to achieve a balance between different types of jobs and avoid
//*        contention between jobs that use the same resources.
//* MSGLEVEL: controls hpw the allocation messages and termination messages are
//*           printed in the job's output listing (SYSOUT).
//* MSGCLASS: assign an output class for your output listing (SYSOUT)
//******************************************************************************
//*
//* PRINT USS COMMAND ON JOB OUTPUT
//*
//UPTIME  EXEC PGM=BPXBATCH,REGION=0M
//STDPARM DD *
SH uptime
//STDIN  DD DUMMY
//STDOUT DD SYSOUT=*
//STDERR DD SYSOUT=*
//"""

def run_sample():

    dsn_sample_jcl = datasets.hlq() + ".SAMPLE.JCL"
    dsn_with_mem_sample_jcl = dsn_sample_jcl + "(UPTIME)"

    # NOTE - data set does NOT need to exist prior to running this sample.

    # create and write JCL to data set
    datasets.write(dataset=dsn_with_mem_sample_jcl, content=jcl_sample)

    # submit job
    job_sample = jobs.submit(dsn_with_mem_sample_jcl)

    print("Details - sample job")
    print("id:", job_sample.id)
    print("name:", job_sample.name)
    print("owner:", job_sample.owner)
    print("status:", job_sample.status)
    print("rc:", job_sample.rc)

    print("Waiting for job completion, then refresh and print status, rc...")

    job_sample.wait()
    job_sample.refresh()

    print("status: ", job_sample.status)
    print("rc: ", job_sample.rc)

    dd_stdout = jobs.read_output(job_sample.id, 'UPTIME', 'STDOUT')

    # print the stdout produced by job
    print("The contents of the STDOUT DD:")
    print(dd_stdout)


    # cleanup:
    # cancels and removes job from jes system
    job_sample.purge()

    # delete data set
    datasets.delete(dsn_sample_jcl)

run_sample()