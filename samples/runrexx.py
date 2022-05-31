#!/usr/bin/env python3
"""
    Copyright IBM Corp 2022.
    runrexx.py - python routine to execute REXX code in IKJEFT01
"""
import os
import sys
from datetime import datetime

from zoautil_py import mvscmd
from zoautil_py.types import DatasetDefinition, DDStatement, FileDefinition


def runrexx(library, executable, parms, inputdata, outputinfo):
    """runrexx function will run REXX code in a TSO (IKJEFT01) address space

    Args:
        library (str): library that the REXX code is in
        executable (str):  program to be executed
        parms (str): input parameters to the executable
        inputdata (list): a list of strings containing input lines without newlines
        outputinfo (dict): A dictionary containing:
                "DDName" the output DD the program is writing to
                "Filename" the zfs file the output would go to

    Returns:
         Returns a structure that contains data with the following keys:
            returninfo: A structure containing the return information from the
                   command call. It will have the return code, any messages
                   and data that can be found in stdout and stderr.
            systsprtfile: The filename that the SYSTSPRT DD pointed to in case any
                   data is there.
            sysprtfile: The filename that the SYSPRINT DD pointed to in case any
                   data is there
    """

    dd_list = []  # This will hold the list of dds for the IKJEFT01 call
    try:
        cwd = os.getcwd()  # need explicit paths for dds
        # This will hold any input into the program
        systsinfile = f"{cwd}/systsin.{str(datetime.now().timestamp())}"
        # This will hold any MVS messages
        sysprtfile = f"{cwd}/sysout.{str(datetime.now().timestamp())}"
        # This will hold TSO output
        systsprtfile = f"{cwd}/systsprt.{str(datetime.now().timestamp())}"

        # The first dd statement will tell the system the dataset containing
        # the REXX code
        dd_list.append(DDStatement("SYSEXEC", DatasetDefinition(library)))

        # Take the input data and put it into a file.
        # (make sure it's EBCDIC and less than 72 bytes)
        if len(inputdata) > 0:
            with open(systsinfile, "w", encoding="cp1047") as systsin:
                for listitem in inputdata:
                    if len(listitem) > 72:
                        raise Exception(
                            f"Input lines must be 72 chars or fewer\n"
                            f"{listitem} length: {len(listitem)}"
                        )
                    else:
                        systsin.write(f"{listitem}\n")
        # Now create a DD that points to the created file
        dd_list.append(DDStatement("SYSTSIN", FileDefinition(systsinfile)))

        # If there is a DD that the REXX code is writing to, make sure that
        # there is a DD that points to it.
        #  The output can go to a dataset or a file
        if len(outputinfo) != 0:
            ddname = outputinfo["DDName"]
            if "Filename" in outputinfo:
                outputfilename = outputinfo["Filename"]
                dd_list.append(DDStatement(ddname, FileDefinition(f"{outputfilename}")))

            if "Dataset" in outputinfo:
                outputfilename = outputinfo["Dataset"]
                dd_list.append(DDStatement(ddname, DatasetDefinition(outputfilename)))

        # Create DD statements that point to the files we defined
        dd_list.append(DDStatement("SYSPRINT", FileDefinition(sysprtfile)))
        dd_list.append(DDStatement("SYSTSPRT", FileDefinition(systsprtfile)))

        # This will be the REXX program that is to be run and any parms it needs
        cmd = f"{executable} {parms}"
        # Execute the REXX code in IKJEFT01
        return_code = mvscmd.execute_authorized("IKJEFT01", pgm_args=cmd, dds=dd_list)

        # Turn the return code object into a Python Dictionary
        return_code_dict = return_code.to_dict()
        # If the return code is good, then we can get rid of the input file
        if return_code_dict["rc"] == 0:
            os.remove(systsinfile)

        # Return all data to the caller in a dictionary
        return_data = {
            "returninfo": return_code_dict,
            "systsprtfile": systsprtfile,
            "sysprintfile": sysprtfile,
        }

    except Exception as e:
        print("Error processing command environment")
        print(f"Failed with exception: {e}")
        sys.exit(1)

    return return_data
