#! /usr/bin/env python3
"""
List SMPE Data. This is a Python implementation that provides the ability to
list data stored in SMPE. It relies on yaml to get defaults and argparse to
handle input.
It would replace the following JCL:
//SMPLIST  JOB ,,MSGLEVEL=1,MSGCLASS=H,CLASS=A,REGION=0M,
//             NOTIFY=&SYSUID
//******************************************************************
//SMPLST   EXEC PGM=GIMSMP
//SMPCSI   DD  DSN=AS4SMP.GLOBAL.CSI,DISP=SHR
//SMPLOG   DD  DUMMY
//SMPLOGA  DD  DUMMY
//SMPWRK6  DD DSN=&&TEMP,
//       SPACE=(CYL,(2500,100,500)),VOL=SER=USRAT5,UNIT=3390,
//       DCB=(DSORG=PO,RECFM=FB,LRECL=80,BLKSIZE=3200),
//       DISP=(NEW,DELETE)
//SMPCNTL  DD  *
 SET BDY(GLOBAL).
 LIST.
 """
import sys
import os
import yaml
import argparse
from zoautil_py import mvscmd, datasets
from zoautil_py.types import DDStatement, DatasetDefinition, FileDefinition


def smpe_list(target_zone="GLOBAL", list_options=None, high_level_qualifier="SYS1"):
    """
    This function does the heavy lifting. It performs the function that
        is contained in the JCL. It sets up the DD statements and issues the
        call to the executable.
    """

    # Initialize DD List
    dd_list = []

    # and the temporary dataset
    temp_dataset = None

    # get the defaults from the yaml file
    defaults = get_defaults("./SMPElistDefaults.yaml")

    try:
        # Setup base DDs
        dd_list.append(
            DDStatement("SMPCSI", DatasetDefinition(defaults["SMPECSI"]["Dataset"]))
        )
        dd_list.append(DDStatement("SMPLOG", "DUMMY"))
        dd_list.append(DDStatement("SMPLOGA", "DUMMY"))

        # Create Temporary File
        temp_dataset_name = datasets.tmp_name(high_level_qualifier)
        temp_dataset = datasets.create(
            temp_dataset_name,
            type="PDS",
            primary_space=(defaults["TEMP_DATASET"]["primary_space"]).strip(),
            secondary_space=(defaults["TEMP_DATASET"]["secondary_space"]).strip(),
            block_size=3200,
            record_format="FB",
            record_length=80,
            volumes=(defaults["TEMP_DATASET"]["volume"]).strip(),
            directory_blocks=10,
        )

        # add it to the ddList
        dd_list.append(DDStatement("SMPWRK6", DatasetDefinition(temp_dataset_name)))

        # define the input for the program make - sure the input is EBCIDIC
        sysin_file_name = defaults["SMPECNTL"]["filename"]
        with open(sysin_file_name, mode="w", encoding="cp1047") as file:
            file.write(f"SET     BDY({target_zone}).\n")
            if list_options is None:
                file.write("LIST.\n")
            else:
                file.write(f"LIST {list_options}.\n")
        dd_list.append(DDStatement("SMPCNTL", FileDefinition(sysin_file_name)))

        # define the place for the output to go
        output_dataset_name = datasets.tmp_name(high_level_qualifier)
        _ = datasets.create(
            output_dataset_name,
            type="SEQ",
            primary_space=(defaults["OUTPUT_DATASET"]["primary_space"]).strip(),
            secondary_space=(defaults["OUTPUT_DATASET"]["secondary_space"]).strip(),
            volumes=(defaults["OUTPUT_DATASET"]["volume"]).strip(),
        )
        dd_list.append(DDStatement("SMPLIST", DatasetDefinition(output_dataset_name)))

        # execute the program
        command_return_code = mvscmd.execute_authorized(pgm="GIMSMP", dds=dd_list)

    except Exception as e:
        sys.stderr.write("Error processing command environment...\n")
        sys.stderr.write(f"Exception information: {e}\n")
        sys.exit(1)

    finally:
        # remove temporary dataset and file
        if temp_dataset:
            datasets.delete(temp_dataset_name)
        os.remove(sysin_file_name)

    print(f"Output can be found in: {output_dataset_name}\n")

    return command_return_code


def get_defaults(filename):
    """
    Get the defaults for this program. This is will hold information
    for the workarea dataset and the location of the file we will use
    to hold SMPECNTL.
    """
    # This is all of the information the yaml file should contain
    required_keys = [
        ("SMPECSI", "dataset"),
        ("TEMP_DATASET", "primary_space"),
        ("TEMP_DATASET", "secondary_space"),
        ("TEMP_DATASET", "volume"),
        ("SMPECNTL", "filename"),
        ("OUTPUT_DATASET", "primary_space"),
        ("OUTPUT_DATASET", "secondary_space"),
        ("OUTPUT_DATASET", "volume"),
    ]

    # Open the yaml file and load the data into defaults
    with open(filename) as file:
        defaults = yaml.load(file, Loader=yaml.FullLoader)

    # Make sure the yaml file has all the required info
    for dataset, key in required_keys:
        if dataset in defaults.keys():
            if key not in defaults[dataset]:
                sys.exit(f"Yaml file missing {dataset}:{key}\n")

    return defaults


def parse_args(argv=None):
    """
    This function is responsible for handling arguments. It relies on
    the argparse module.
    """
    program_name = os.path.basename(sys.argv[0])

    if argv is None:
        argv = sys.argv[1:]

    try:
        parser = argparse.ArgumentParser(program_name)
        parser.add_argument("hlq", help="The High Level Qualifier to be used.")
        parser.add_argument(
            "-z", "--zone", default="GLOBAL", help="The target zone to be queried."
        )
        parser.add_argument(
            "-o", "--options", default=None, help="Any list options to be added"
        )
        opts = parser.parse_args(argv)
        return opts

    except Exception as e:
        indent = len(program_name) * " "
        sys.stderr.write(program_name + ": " + repr(e) + "\n")
        sys.stderr.write(indent + "  for help use --help")
        sys.exit(1)


def main():
    """
    Main function. parse input to the program and run the
    SMPE_list function
    """
    args = parse_args()
    result = smpe_list(args.zone, args.options, args.hlq).to_dict()
    if result["rc"] > 0:
        sys.stderr.write(f"Return Code: {result['rc']}\n")
        if result["stderr_response"]:
            sys.stderr.write(f"{result['stderr_response']}\n")
        sys.stderr.write(f"Message from the system:\n{result}\n")


if __name__ == "__main__":
    main()
