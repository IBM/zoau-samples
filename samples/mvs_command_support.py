#!/usr/bin/env python3
"""Provide support for mvscmd dds
"""
import os
import subprocess
from datetime import datetime
from zoautil_py import datasets, mvscmd
from zoautil_py.types import DDStatement, FileDefinition, DatasetDefinition

_mcs_data_set_list=[]

def get_zos_userid() -> str:
    """Get the z/OS userid from the system.
    Parameters: None
    Return:
        user_id - <str>: The z/OS user id of the caller
    """
    uid = str(subprocess.run(["id"], shell=True, capture_output=True, check=False).stdout)
    user_id = uid[(uid.find("(")+1):uid.find(")")]
    return user_id


def create_temp_dataset(options: dict=None) -> dict:
    """Create a temporary dataset.
       Create a dataset and return all the necessary info about it as a dictionary

    Paramters:
        options - <dict> (optional): All of the options that one could set to create
                                     a dataset in ZOAU. Defaults to None.
    Return:
        dataset_dictionary - <dict>: A complete dictionary contains info of the
                                     created temporary dataset
    """
    zos_userid = get_zos_userid()
    dataset_name = f"{zos_userid}.TEMPRARY"
    dataset_name = datasets.tmp_name(dataset_name)
    _mcs_data_set_list.append(dataset_name)
    if options is None:
        dataset_object = datasets.create(dataset_name,"SEQ",)
    else:
        dataset_object = datasets.create(dataset_name, **options)
    return dataset_object.to_dict()

def create_non_temp_dataset(options: dict=None) -> dict:
    """Create a temporary dataset.
       Create a dataset and return all the necessary info about it as a dictionary

    Paramters:
        options - <dict> (optional): All of the options that one could set to create
                                     a dataset in ZOAU. Defaults to None.
    Return:
        dataset_dictionary - <dict>: A complete dictionary contains info of the
                                     created temporary dataset
    """
    if options is None or "name" not in options:
        zos_userid = get_zos_userid()
        dataset_name = datasets.tmp_name(zos_userid)
    else:
        dataset_name = datasets.tmp_name(options["name"])
    if options is None:
        dataset_object = datasets.create(dataset_name,"SEQ")
    else:
        dataset_object = datasets.create(dataset_name, **options)

    # Keep track of datasets you create in a global variable
    _mcs_data_set_list.append(dataset_name)

    return dataset_object.to_dict()

def get_temp_file_name(name : str=None, working_directory : str="/tmp") -> str:
    """Define a temporary filename to be used the filesystem

    Parameters:
        name - <str> (optional): A string containing the name of the file. 
                                 Defaults to None
        working_directory - <str>(optional): A directory where the file can live. 
                                             Defaults to tmp
    Return:
        filename - <str>: The name of the created file
    """
    # First lets make sure the name has the word TEMPORARY in it
    if name is None:
        name = "TEMPRARY"
    else:
        name = f"{name}.TEMPRARY"

    # We get a data and timestamp to ensure that the file name is unique
    static_time = str(datetime.now().timestamp())
    temp_file_name = f"{working_directory}/{name}.{static_time}"

    # Keep track of all the files in our global _mcs_data_set_list too
    _mcs_data_set_list.append(temp_file_name
                              )
    # Now we can return the generated name
    return temp_file_name



def create_input_file(input_list : list, input_file_name : str, codepage : str="cp1047"):
    """Create the input file that will be used for an input DD. It is meant to
       fit the 72 character limit that is in JCL card decks

    Parameters:
        input_list - <list>: List of strings containing the input
        input_file_name - <str>: The name of the file
        codepage - <str> (optional): The codepage to use when writing the data.
                                     Defaults to "cp1047".
    """
    # (make sure it's EBCDIC and less than 72 bytes)
    with open(input_file_name, "w", encoding=codepage) as sysin:
        for listitem in input_list:
            if len(listitem) > 72:
                print("Input lines must be less than 72 chars\n")
                print(f"{listitem} is length: {len(listitem)} and is ignored")

            else:
                sysin.write(f"{listitem}\n")


def create_input_dd(input_list : list, ddname : str="SYSIN")->DDStatement:
    """Create an input DD basedd on a list

    Parameters:
        input_list - <list>: A list of strings which is input to the DD
        ddname - <str> (optional): The DDName used for input. Defaults to "SYSIN".
    Return:
        <DDStatement>: The created DD statement 
    """
    # First we need to create the name of the temporary file
    # Use the ddname in the file
    temporary_file_name = get_temp_file_name(ddname)

    # Now create the file that will hold the input
    create_input_file(input_list, temporary_file_name)

    # Now create the DD that will hold the input

    return DDStatement(ddname, FileDefinition(temporary_file_name))


def cleanup_temporaries(debugging :bool=False):
    """Remove any temporary files or datasets

    Args:
        debugging - <bool> (optional): Debug flag. If set keep files around
        _mcs_data_set_list - <list> (implicit): Global variable that is updated
                                                whenever a dataaet or file is created
    Return:
        None
    """
    for dataset in _mcs_data_set_list:
        print(dataset)
        if "TEMPRARY" in dataset:
            if "/" in dataset:
                if debugging:
                 print(f"Temporary file: {dataset} has not been erased")
                else:
                    os.remove(dataset)
            else:
                if debugging:
                    print(f"Temporary Dataset: {dataset} has not been erased")
                else:
                    # All uppercase names are DATASETS
                    return_code = datasets.delete(dataset)
                    if return_code != 0:
                        print(f"Error erasing {dataset}")

def main():
    """Test this with a SMPE list
    """
    # First define a list of DD statements
    dd_list=[]

    # Create an input dd to list the Global Zone
    dd_list.append(create_input_dd([" SET BDY(GLOBAL)."," LIST. "],ddname="SMPCNTL"))

    # Define the Workspace dataset
    workspace_dataset={"type":"PDS","primary_space":"1G","secondary_space":"1G",
                       "block_size":3200,"record_format":"FB","record_length":80,
                       "volumes":"USRAT8"}
    workspace_dataset=create_temp_dataset(workspace_dataset)

    # Add it to the DD list
    dd_list.append(DDStatement("SMPWRK6",DatasetDefinition(workspace_dataset["name"])))

    # Define the Dummy DDs
    dd_list.append(DDStatement("SMPLOG","DUMMY"))
    dd_list.append(DDStatement("SMPLOGA","DUMMY"))

    # Define the Global CSI
    dd_list.append(DDStatement("SMPCSI",DatasetDefinition("AT4SMP.GLOBAL.CSI")))

    # Define the output dataset
    output_dataset={"type":"SEQ","primary_space":"5M","secondary_space":"5M","volumes":"USRAT8"}

    # Create the output dataset
    output_dataset=create_non_temp_dataset(output_dataset)

    # Add it to the DD list
    dd_list.append(DDStatement("SMPLIST",DatasetDefinition(output_dataset['name'])))

    # Now run the Command
    command_return_dictionary = mvscmd.execute_authorized(pgm="GIMSMP", dds=dd_list).to_dict()

    if command_return_dictionary['rc']>0:
        print(f"Command failed with a return code of: {command_return_dictionary['rc']}")
    else:
        print(f"Command succeeded. Output can be found in: {output_dataset['name']}")

    # Remove the temporary file and Dataset
    cleanup_temporaries(False)

if __name__ == "__main__":
    main()
    