#!/usr/bin/env python3
"""Code rights.

Copyright IBM Corp 2023.
create_sysin.py - standard routine for creating a sysin file that can be used
as input to an MVS program
"""
import sys


def create_sysin(inputdata, filename, codepage="cp1047"):
    """Write sysin (or other JCL inputs like systsin) to a file

    Take the input and create a file that will be used for input. If
    it is empty create an empty file. It is assumed that we will be using
    this as input to some MVS program so it will treat the input like
    JCL cards.
    Args:
         inputdata: the data (as a list of strings) that will be in the file
         filename:  the file that will hold the info
    """
    # Take the input data and put it into a file.
    # (make sure it's EBCDIC and less than 72 bytes)
    if len(inputdata) > 0:
        with open(filename, "w", encoding=codepage) as sysin:
            for listitem in inputdata:
                if len(listitem) > 72:
                    raise Exception(
                        f"Input lines must be 72 chars or fewer\n"
                        f"{listitem} length: {len(listitem)}"
                    )
                sysin.write(f"{listitem}\n")
    else:
        with open(filename, "w", encoding=codepage) as sysin:
            sysin.write(" ")


def main():
    """Create a file based on input list.
    call create_sysin to take input provided to write to a file
    Assume codepage is cp1047"""
    if len(sys.argv) < 3:
        print("Incomplete number of args.:")
        print("create_sysin.py filename list of strings")
    input_list = []
    filename = sys.argv[1]
    for arg_item in sys.argv[2:]:
        input_list.append(arg_item)
    create_sysin(input_list, filename)
    print(f"Input written to: {filename}")


if __name__ == "__main__":
    main()
