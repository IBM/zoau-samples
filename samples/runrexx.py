#!/usr/bin/env python3
"""Code rights.

Copyright IBM Corp 2022.
runrexx.py - python routine to execute REXX code in IKJEFT01
"""
import os
import sys
from datetime import datetime

from zoautil_py import mvscmd
from zoautil_py.types import DatasetDefinition, DDStatement, FileDefinition


def write_out_the_input(inputdata, filename):
    """Write out the input into a file

    Take the input and create a file that will be used for input. If
    it is empty create an empty file
    Args:
         inputdata: the data that will be in the file
         filename:  the file that will hold the info
    """
    # Take the input data and put it into a file.
    # (make sure it's EBCDIC and less than 72 bytes)
    if len(inputdata) > 0:
        with open(filename, "w", encoding="cp1047") as systsin:
            for listitem in inputdata:
                if len(listitem) > 72:
                    raise Exception(
                        f"Input lines must be 72 chars or fewer\n"
                        f"{listitem} length: {len(listitem)}"
                    )
                systsin.write(f"{listitem}\n")
    else:
        with open(filename, "w", encoding="cp1047") as systsin:
            systsin.write(" ")


def runrexx(authorized, library, program_info, inputdata, outputinfo):
    """Run a Rexx program and collect ite data from it.

    function will run REXX code in a TSO (IKJEFT01) address space
    Args:
        authorized (boolean): A flag to determine if the code run authorized
        library (str): library that the REXX code is in
        program_info: A string containing the program and its arguments
        inputdata (list): a list of strings containing input lines without newlines
        outputinfo (dict): A dictionary containing:
                "DDName" the output DD the program is writing to
                "Filename" the zfs file the output would go to
                "Dataset" the dataset the output would go to
                a DD would point to either a Dataset or a File but not both

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

    cwd = os.getcwd()  # need explicit paths for dds
    static_time = str(datetime.now().timestamp())
    # This will hold any input into the program
    systsinfile = f"{cwd}/systsin.{static_time}"
    # This will hold any MVS messages
    sysprtfile = f"{cwd}/sysprt.{static_time}"
    # This will hold TSO output
    systsprtfile = f"{cwd}/systsprt.{static_time}"

    # The first dd statement will tell the system the dataset containing
    # the REXX code
    dd_list.append(DDStatement("SYSEXEC", DatasetDefinition(library)))

    # Take the input data and put it into a file.
    write_out_the_input(inputdata, systsinfile)

    # Now create a DD that points to the created file
    dd_list.append(DDStatement("SYSTSIN", FileDefinition(systsinfile)))

    # If there is a DD that the REXX code is writing to, make sure that
    # there is a DD that points to it.
    #  The output can go to a dataset or a file
    if len(outputinfo) != 0:
        if "Filename" in outputinfo:
            outputfilename = outputinfo["Filename"]
            dd_list.append(
                DDStatement(outputinfo["DDName"], FileDefinition(f"{outputfilename}"))
            )

    if "Dataset" in outputinfo:
        outputfilename = outputinfo["Dataset"]
        dd_list.append(
            DDStatement(outputinfo["DDName"], DatasetDefinition(outputfilename))
        )

    # Create DD statements that point to the files we defined
    dd_list.append(DDStatement("SYSPRINT", FileDefinition(sysprtfile)))
    dd_list.append(DDStatement("SYSTSPRT", FileDefinition(systsprtfile)))

    # now we determine how to run the REXX code in IKJEFT01
    if authorized is True:
        # Execute the REXX code authorized
        return_code_dict = (
            mvscmd.execute_authorized("IKJEFT01", pgm_args=program_info, dds=dd_list)
        ).to_dict()
    else:
        # Execute the code unauthorized
        return_code_dict = (
            mvscmd.execute("IKJEFT01", pg_args=program_info, dds=dd_list)
        ).to_dict()

    # Turn the return code object into a Python Dictionary
    # return_code_dict = return_code.to_dict()
    # If the return code is good, then we can get rid of the input file
    if return_code_dict["rc"] == 0:
        os.remove(systsinfile)

    # Return all data to the caller in a dictionary
    return_data = {
        "returninfo": return_code_dict,
        "systsprtfile": systsprtfile,
        "sysprintfile": sysprtfile,
    }

    return return_data


def main():
    """Call the runrexx function.

    To run this main copy the code below into a dataset of your choosing.
    Make sure the member name HELOWRLD.
    /* REXX Sample code to run a hello world from Python */
    parse Arg Input
    If length(Input>0) then say "Argument passed in is: " input
    else say " No input passed in"
    Say "Simple hello World app running for " userid()
    Say "Now printing data passed in via STDIN:"
    Do Forever
      parse pull data
      if length(data)=0 then leave
      say data
    end
    OutToDD.1="First Line of data written a DD"
    OutToDD.2="Second Line of data written to a DD"
    Address TSO "EXECIO * DISKW DDDATA (STEM OUTTODD. FINIS )"
    exit
    /* End of REXX Code */
    Call the main with a dataset name
    runrexx.py Data.set.name
    """
    if len(sys.argv) == 1:
        print("You must provide a dataset name that holds the REXX Code.")
        sys.exit(1)
    dataset = sys.argv[1]
    authorized = False
    program_and_parms = "HELOWRLD These are the parameters"
    returndata = runrexx(
        authorized,
        dataset,
        program_and_parms,
        ["Line 1 of input", "Line 2 of input"],
        {"DDName": "DDDATA", "Filename": "/tmp/dddata.txt"},
    )
    return_code_dictionary = returndata["returninfo"]
    if return_code_dictionary["rc"] == 0:
        print(f'Code ran with a return code: {return_code_dictionary["rc"]}')
    else:
        print(f'Return Code:{return_code_dictionary["rc"]}')
        print(return_code_dictionary["stderr_response"])


if __name__ == "__main__":
    main()
