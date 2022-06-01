#!/usr/bin/env python3
""" Copyright IBM Corp 2021.
    Submits a JCL job and returns status output in a Python dictionary
"""

import argparse
import textwrap
import time

from zoautil_py import datasets, exceptions, jobs


def runjob(jcl_ds: str):
    """This function will submit a JCL job

    Args:
        jcl_ds (str): data set name to submit

    Returns:
        dictionary: Python dictionary of job status - NAME, OWNER, STATUS, RC
    """
    status_record = []
    current_status = {}
    # In case JCL job hangs, it will timeout at 70 seconds.
    # This time can be adjusted.
    timeoutsec = 70
    try:
        if datasets.exists(jcl_ds) is True:
            job_submitted = jobs.submit(jcl_ds, timeout=timeoutsec)
        else:
            print("Dataset not found, check that it exist")
            return -1
    except exceptions.ZOAUException:
        print("Invalid input")
        return -1

    print("Job " + job_submitted.name + " submitted")
    # status will be stored / displayed until ACTIVE status changes
    while (job_submitted.status == "AC"):
        current_status = _set_current_status(job_submitted)
        print(current_status)
        # Keep a record of statuses in a list of dictionaries
        status_record.append(current_status)
        # sleep for three seconds, adjust if more time is needed
        time.sleep(3)
        job_submitted.refresh()

    # return final status and add it to list for record keeping
    current_status = _set_current_status(job_submitted)
    status_record.append(current_status)
    return current_status


def _print_to_log(status_record: list):
    """ Module can be called to write the record of statuses to a file.
        Record will be overwritten every time the script is run to prevent
        the file from getting too large.

        NOTE: Currently this module is not being called from anywhere *

    Args:
        status_record (list): list of Python dictionaries of JCL status results
    """
    output_log = open("log_out.txt", "w")
    output_log.write(str(status_record))


def _set_current_status(job_submitted):
    """Sets Name, owner, status, and rc of submitted JCL job

    Args:
        job_submitted (object):  Job object representing the submitted dataset
    """
    return {'NAME': job_submitted.name,
            'OWNER': job_submitted.owner,
            'STATUS': job_submitted.status,
            'RC': job_submitted.rc
            }


def _parse_arguments():
    """
    Process arguments for script
    """
    parse_input = argparse.ArgumentParser(
            formatter_class=argparse.RawDescriptionHelpFormatter,
            epilog=textwrap.dedent('''
                Example:
                runjob.py "MY.DATASET(JCLJOB)"
                '''))
    parse_input.add_argument('dataset',
                             help="Enter job dataset to submit",
                             type=str)
    argument = parse_input.parse_args()
    return argument


def main():
    argument = _parse_arguments()
    print(runjob(argument.dataset))


if __name__ == "__main__":
    main()
