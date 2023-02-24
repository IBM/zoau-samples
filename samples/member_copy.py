#!/usr/bin/env python3
"""Code rights.

Copyright IBM Corp 2022.
member_copy.py - Copy members from one dataset to another. It uses IEBCOPY
because the member copy from ZOAU doesn't preserve the member statistics
"""
import os
import sys
from datetime import datetime

from zoautil_py import mvscmd
from zoautil_py.types import DatasetDefinition, DDStatement, FileDefinition
from create_sysin import create_sysin


def _find_bad_members(memberlist, printfile):
    """Find the bad mambers in the list

    Args:
        memberlist (String): The list of members
        printfile (String): file containing the data returned from IEBCOPY

    Returns:
        badmembers (String): A string of members that weren't in the source
        dataset.
    """
    # If there isn't a comma in the list, there is only 1 member
    if "," not in memberlist:
        badmembers = memberlist
    else:
        # Read the sysprint to find which members were not in the dataset
        badmembers = ""
        with open(printfile, "r", encoding=("cp1047")) as input_file:
            for line in input_file.readlines():
                if "IEB177I" in line:
                    text_list = line.split()
                    badmembers += f"{text_list[1]},"
                    badmembers = badmembers.rstrip(",")
    return badmembers


def get_error_from_file(filename, source, destination):
    """Figure out what the eror text should be based on the error code

    Args:
         filename (String):    The filename
         source (String):      The Source dataset
         destination (String): The destination dataset

    Returns:
        Message Text
    """
    message = ""
    with open(filename, "r", encoding=("cp1047")) as input_file:
        for line in input_file.readlines():
            if "IGW01513T" in line:
                message = "Record Formats incompatible:"
                line_list = line.split()
                message = f"{message} {source} record format is {line_list[7]} "
                message = f"{message} {destination} record format is {line_list[11]}"
            elif "IEB127I" in line:
                message = "Record Formats incompatible:"
                line_list = line.split()
                input_recfm = line_list[5][6:]
                output_recfm = line_list[7][6:]
                message = f"{message} {source} record format is {input_recfm}"
                message = f"{message} {destination} record format is {output_recfm}"
            elif "IEB124I" in line:
                message = "Record length incompatible:"
                line_list = line.split()
                input_lrecl = line_list[5].strip("()")
                output_lrecl = line_list[9].strip("().")
                message = f"{message} {source} record length is {input_lrecl}"
                message = f"{message} {destination} record length is {output_lrecl}"
            elif "913-00000038" in line:
                message = f"You are not authorized to {source}"

    if len(message) < 1:
        message = f"z/OS Unchecked error please check out: {filename}"
    return message


def _find_bad_dataset(error_text, source, destination):
    """Figure out which datast is not there. If it isn't the source
       then it must be the destination

    Args:
        error_text (String): The error text
        source (String): The Source dataset
        destination (String): The destination dataset

    Returns:
        A string of members that were not in the source dataset
    """
    if "SYSUT1" in error_text:
        return f"Dataset: {source} does not exist."
    return f"Dataset: {destination} does not exist."


def _handle_return(mvscmd_dictionary, source, destination, printfile, memberlist):
    """Handle the result of the command

    Args:
        return_dictionary (dictionary): the data returned from the MVSCMD call
        source (string): the dataset that is the source
        destination (string): the dataset that is the destination
        printfile (string): file containing output to sysprt
        memberlist (string): the list of members to be copied

    Returns:
        A dictionary containing a return code and a related message
    """
    # If there is a list of members make sure the message reflects one vs many
    if mvscmd_dictionary["rc"] == 0:
        if "," in memberlist:
            return_message = f"Members: {memberlist} have been copied."
        else:
            return_message = f"Member: {memberlist} has been copied."
    else:
        # Return code 4 is bad input parms so it must be the members that are wrong
        if mvscmd_dictionary["rc"] == 4:
            badmembers = _find_bad_members(memberlist, printfile)
            if "," in badmembers:
                return_message = f"Members: {badmembers} are not in dataset {source}."
            else:
                return_message = f"Member: {badmembers} is not in dataset {source}."

        # Return code 8 means the command is can't run. Probably because one of the
        # datasets are not allocated
        if mvscmd_dictionary["rc"] == 8:
            error_text = mvscmd_dictionary["stderr_response"]
            if "allocating" in error_text:
                return_message = _find_bad_dataset(error_text, source, destination)
            elif len(error_text) > 0:
                return_message = f"z/OS Error: {error_text}"
            else:
                return_message = get_error_from_file(printfile, source, destination)

    return {"rc": mvscmd_dictionary["rc"], "message": return_message}


def member_copy(input_dataset, output_dataset, memberlist, debug_msgs=False):
    """Copy Members from one dataset to another.

    This function will rely on the IEBCOPY utility.
    Args:
         input_dataset (String): the source dataset
         output_dataset (String): the destination dataset
         memberlist (String): A string of members separated by a comma
         debug_msgs (Boolean): Flag to print out debug messages

    Returns:
         Returns dictionary with a return code and a message
    """
    if debug_msgs:
        print("Running the member_copy function")

    dd_list = []  # This will hold the list of dds for the IEBCOPY call

    cwd = os.getcwd()  # need explicit paths for dds
    static_time = str(datetime.now().timestamp())
    # This will hold any input into the program
    sysinfile = f"{cwd}/sysin.{static_time}"
    # This will hold any MVS messages
    sysprtfile = f"{cwd}/sysprt.{static_time}"

    # Create a SYSIN that defines the member or members to copy
    iebcopy_input = []
    iebcopy_input.append(" COPY OUTDD=SYSUT2,INDD=SYSUT1")
    iebcopy_input.append(f" SELECT MEMBER=({memberlist.upper()})")

    # Take the input data and put it into a file.
    create_sysin(iebcopy_input, sysinfile)

    # Now create a DD that points to the created file
    dd_list.append(DDStatement("SYSIN", FileDefinition(sysinfile)))

    # Define the input dataset (SYSUT1) and the output dataset (sysut2)
    dd_list.append(DDStatement("SYSUT1", DatasetDefinition(input_dataset.upper())))
    dd_list.append(DDStatement("SYSUT2", DatasetDefinition(output_dataset.upper())))

    # Create DD statements that point to the system printer
    dd_list.append(DDStatement("SYSPRINT", FileDefinition(sysprtfile)))

    # Execute the IEBCOPY Utility
    return_code_dict = (mvscmd.execute("IEBCOPY", dds=dd_list)).to_dict()

    # Turn the return code object into a Python Dictionary
    # return_code_dict = return_code.to_dict()
    # If the return code is good, then we can get rid of the input file
    return_dictionary = _handle_return(
        return_code_dict, input_dataset, output_dataset, sysprtfile, memberlist
    )

    # As long as we know what the error is then we can erase the input and output files
    if "z/OS" not in return_dictionary["message"] and not debug_msgs:
        os.remove(sysinfile)
        os.remove(sysprtfile)
    else:
        print(
            f"Input file: {sysinfile} and Output file: {sysprtfile} have been retained"
        )

    return return_dictionary


def main():
    """Call the member_copy function

    Args:
         input (String):  The input dataset
         output (String): The output dataset
         members (List):  A list of members that need to be copied
    """
    # If I don't have 3 arguments then I can't do anything
    if len(sys.argv) < 4:
        print("You must provide an input, output, and members")
        sys.exit(1)

    # Identify input and output datasets
    input_dataset = sys.argv[1]
    output_dataset = sys.argv[2]

    # The member list is actually a list -
    # Turn it into a comma delimited string
    memberlist = sys.argv[3:]
    list_of_members = ""
    for member in memberlist:
        list_of_members += member + ","
    list_of_members = list_of_members.rstrip(",")

    # Now run the member_copy function. Make sure all of the parms are in
    # upper case because IEBCOPY expects it.
    return_code_dictionary = member_copy(input_dataset, output_dataset, list_of_members)

    # If the copy didn't work correctly print out the return code
    if return_code_dictionary["rc"] != 0:
        print(f'Return Code:{return_code_dictionary["rc"]}')

    # Return a message about the copy (good or bad)
    print(return_code_dictionary["message"])


if __name__ == "__main__":
    main()
