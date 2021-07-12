#!/usr/bin/env python3
#
# Iterate through a zCX registry directory and obtain version information
# about any running zCX instances.  Print a message if a given instance
# is backlevel and can be upgraded. Requires Python and ZOAU.
#
# Usage: python3 zcx_versions.py -p <ZCX_REGISTRY_PATH>
#
# Anthony Giorgio <agiorgio@us.ibm.com>
#
# Copyright IBM Corp. 2021
#

import argparse
import os
import subprocess
import sys

opercmd = "/usr/lpp/IBM/zoautil/bin/opercmd"

def parse_args(argv=None):
    program_name = os.path.basename(sys.argv[0])

    if argv is None:
        argv = sys.argv[1:]
    # end if

    try:
        parser = argparse.ArgumentParser(program_name)
        parser.add_argument("-p", "--zcx-registry-path",
                            help="Path of the zCX registry directory.")
        parser.add_argument("-u", "--upgradeable-only", action='store_true',
                            help="Show only zCX instances that can be upgraded.")
        parser.add_argument("-z", "--zoau-path", help="Path to zoau install directory.")

        opts = parser.parse_args(argv)

        return opts

    except Exception as e:
        indent = len(program_name) * " "
        sys.stderr.write(program_name + ": " + repr(e) + "\n")
        sys.stderr.write(indent + "  for help use --help")
        sys.exit(1)


# Main code starts here

cli_opts = parse_args()
registry_path = cli_opts.zcx_registry_path

if registry_path is None:
    print("No registry path specified.")
    sys.exit(1)

if cli_opts.zoau_path is not None:
    opercmd = "{0}/bin/opercmd".format(cli_opts.zoau_path)
    print("Using opercmd at {0}".format(opercmd))

if not os.path.isfile(opercmd):
    print("Not found: {0}".format(opercmd))
    exit(1)

print("Looking for running zCX instances in directory {0}".format(registry_path))

with os.scandir(path=registry_path) as it:
    for entry in it:
        if entry.is_dir():
            if len(entry.name) > 8:
                # It can't be an instance directory as the name is too long.
                continue

            try:
                # See if the directory name corresponds to a running zCX instance.
                result = subprocess.check_output("{0} 'f {1},display,version'".format(opercmd, entry.name),
                                                  shell=True, stderr=subprocess.PIPE, timeout=5)

                if ("NOT ACTIVE" in result.decode()):
                    continue

                # If it's running, parse out the version information.
                lines = result.decode().splitlines()

                msg_start_idx = None
                for i in range(0,len(lines)):
                    if "GLZB022I" in lines[i]:
                        msg_start_idx = i

                if msg_start_idx is None:
                    print("Unable to parse version message.")
                    continue

                apar_offset = 3
                version_offset = 1

                if "Current Appliance" in lines[msg_start_idx + 3]:
                    current_apar = lines[msg_start_idx + 3].split()[apar_offset]
                    current_version = lines[msg_start_idx + 4].split()[version_offset]
                    available_apar = lines[msg_start_idx + 6].split()[apar_offset]
                    available_version = lines[msg_start_idx + 7].split()[version_offset]

                    if (current_version != available_version):
                        print("Instance {0} is version {1} ({2}) and can be upgraded to {3} ({4})"
                              .format(entry.name.ljust(8), current_version, current_apar,
                                      available_version, available_apar))
                    else:
                        if not cli_opts.upgradeable_only:
                            print("Instance {0} is version {1} ({2})".format(entry.name.ljust(8),
                                                                             current_version, current_apar))

                else:
                    print("Unable to find current instance version.")
                    continue

            except subprocess.CalledProcessError as e:
                print(e.stdout.decode())
            except subprocess.TimeoutExpired as e:
                print("Timeout expired")
