#!/bin/sh
#*******************************************************************************
# IMS Command Automation Script using Z Open Automation Utilities (ZOAU)
#*******************************************************************************
#
# DESCRIPTION:
#   This script provides a command-line interface for issuing IMS commands
#   without requiring direct login to z/OS. It demonstrates how ZOAU commands
#   can be used to automate IMS operations from a Unix/Linux shell environment.
#
# PURPOSE:
#   - Prototype for automating IMS command execution via CLI
#   - Eliminates need for manual z/OS login to issue IMS commands
#   - Showcases ZOAU capabilities for mainframe automation
#   - Provides interactive interface for IMS system management
#
# PREREQUISITES:
#   - Z Open Automation Utilities (ZOAU) must be installed and configured
#   - User must have appropriate permissions to execute IMS commands
#   - IMS PLEX must be accessible (default: PLEX1)
#   - Required IMS libraries must be available:
#     * DFS.V15R1M0.SDFSRESL
#     * DFS.V15R1M0.ADFSLOAD
#     * DFS.V15R1M0.SDFSEXEC
#
# ENVIRONMENT VARIABLES:
#   TMPHLQ - (Optional) High-Level Qualifier for temporary datasets
#            If not set, the script will use the default TSO high level qualifier
#
# USAGE:
#   ./ims_command.sh
#
#   The script will prompt for IMS commands interactively:
#   - Enter any valid IMS command at the prompt
#   - Type 'q' or 'Q' to exit the script
#
# EXAMPLES:
#   Enter IMS Command> /DIS ACTIVE
#   Enter IMS Command> /DIS TRAN ALL
#   Enter IMS Command> /STA TRAN TRANNAME
#   Enter IMS Command> q
#
# ZOAU COMMANDS USED:
#   - hlq      : Get default high-level qualifier for datasets
#   - mvstmp   : Generate temporary dataset name
#   - dtouch   : Create a new dataset
#   - decho    : Write content to a dataset
#   - mvscmd   : Execute MVS programs (CSLUSPOC in this case)
#   - drm      : Delete/remove datasets
#
# TECHNICAL DETAILS:
#   The script uses CSLUSPOC (IMS Type-2 Command processor) to execute
#   IMS commands through the Operations Manager (OM) API.
#
# NOTES:
#   - Adjust IMSPLEX parameter (line 28) to match your IMS environment
#   - Modify STEPLIB datasets (line 29) to match your IMS version
#   - WAIT parameter is set to 120 seconds (2 minutes) for command timeout
#   - ROUTE parameter directs commands to IMS Operations (IMSO)
#
# AUTHOR: IBM ZOAU Samples
# VERSION: 1.0
#*******************************************************************************

# Trap signals to ensure cleanup on script exit or interruption
# Signals: EXIT(0), HUP(1), INT(2), QUIT(3), ABRT(6), KILL(9), ALRM(14), TERM(15)
trap cleanup 0 1 2 3 6 9 14 15
#*******************************************************************************
# FUNCTION: cleanup
#
# DESCRIPTION:
#   Cleanup function that removes temporary datasets created during script execution.
#   This function is automatically called when the script exits (via trap).
#
# PARAMETERS:
#   None
#
# GLOBAL VARIABLES:
#   jcltmp - Temporary dataset name to be deleted
#
# ZOAU COMMANDS:
#   drm - Delete/remove MVS dataset
#
# NOTES:
#   - Output is redirected to /dev/null to suppress messages
#   - Errors are ignored (2>&1) to prevent script failure if dataset doesn't exist
#*******************************************************************************
function cleanup {
    drm "${jcltmp}" > /dev/null 2>&1
}

#*******************************************************************************
# FUNCTION: issue_cmd
#
# DESCRIPTION:
#   Issues an IMS command by creating a temporary dataset with the command,
#   then executing the CSLUSPOC program to process it through IMS Operations Manager.
#
# PARAMETERS:
#   $1 - IMS command to execute (e.g., "/DIS ACTIVE", "/STA TRAN TRANNAME")
#
# WORKFLOW:
#   1. Determine High-Level Qualifier (HLQ) for temporary dataset
#   2. Generate unique temporary dataset name
#   3. Create sequential dataset to hold the IMS command
#   4. Write the IMS command to the dataset
#   5. Execute CSLUSPOC program with the command as input
#   6. Clean up temporary dataset
#
# GLOBAL VARIABLES:
#   TMPHLQ  - (Optional) User-specified HLQ for temporary datasets
#   jcltmp  - Generated temporary dataset name
#
# ZOAU COMMANDS:
#   hlq     - Retrieve default high-level qualifier
#   mvstmp  - Generate temporary dataset name with given HLQ
#   dtouch  - Create new MVS dataset (sequential format)
#   decho   - Write content to MVS dataset
#   mvscmd  - Execute MVS program with specified parameters
#   drm     - Delete MVS dataset
#
# CSLUSPOC PARAMETERS:
#   --pgm       : Program name (CSLUSPOC - IMS Type-2 Command processor)
#   --args      : Runtime arguments
#                 * IMSPLEX=PLEX1  : Target IMS PLEX name (customize as needed)
#                 * ROUTE=(IMSO)   : Route to IMS Operations
#                 * WAIT=120      : Command timeout in seconds (2 minutes)
#   --steplib   : Load libraries for CSLUSPOC execution
#                 * DFS.V15R1M0.SDFSRESL : IMS RESLIB
#                 * DFS.V15R1M0.ADFSLOAD : IMS Application Load Library
#                 * DFS.V15R1M0.SDFSEXEC : IMS Executable Library
#   --sysprint  : Output destination (* = display to console)
#   --sysin     : Input dataset containing the IMS command
#
# CUSTOMIZATION:
#   - Update IMSPLEX value to match your IMS environment
#   - Adjust library names (DFS.V15R1M0.*) to match your IMS version
#   - Modify WAIT value if longer/shorter timeout is needed
#   - Change ROUTE parameter if targeting different IMS component
#
# RETURN:
#   Command output is displayed via SYSPRINT
#   Exit code reflects success/failure of CSLUSPOC execution
#
# NOTES:
#   - Temporary dataset is automatically cleaned up after command execution
#   - CSLUSPOC provides XML-formatted output for IMS Type-2 commands
#   - Ensure IMS libraries are accessible and authorized for your user ID
#*******************************************************************************
function issue_cmd {
    # Determine High-Level Qualifier for temporary dataset
    # Use TMPHLQ environment variable if set, otherwise get default from ZOAU
    if [[ -z ${TMPHLQ} ]]; then
        hlq=`hlq`
    else
        hlq="${TMPHLQ}"
    fi

    # Generate unique temporary dataset name using the HLQ
    jcltmp=`mvstmp ${hlq}`

    # Create a sequential dataset to hold the IMS command
    dtouch -tSEQ "${jcltmp}"

    # Write the IMS command (passed as $1) to the temporary dataset
    decho "$1" "${jcltmp}"

    # Execute CSLUSPOC (IMS Type-2 Command processor) to issue the IMS command
    # This invokes the IMS Operations Manager API to process the command
    mvscmd --pgm=CSLUSPOC --args='IMSPLEX=PLEX1,ROUTE=(IMSO),WAIT=120' \
           --steplib=DFS.V15R1M0.SDFSRESL,SHR:DFS.V15R1M0.ADFSLOAD,SHR:DFS.V15R1M0.SDFSEXEC,SHR \
           --sysprint=* --sysin="${jcltmp}"

    # Clean up: Remove the temporary dataset
    drm "${jcltmp}" > /dev/null 2>&1
}

#*******************************************************************************
# MAIN LOOP: Interactive IMS Command Interface
#
# DESCRIPTION:
#   Provides an interactive command-line interface for issuing IMS commands.
#   Continuously prompts the user for IMS commands until they choose to quit.
#
# WORKFLOW:
#   1. Display prompt for IMS command input
#   2. Read user input
#   3. Check if user wants to quit (q/Q)
#   4. If not quitting, pass command to issue_cmd function
#   5. Repeat indefinitely until user quits
#
# USER INPUT:
#   - Any valid IMS command (e.g., /DIS ACTIVE, /STA TRAN, /STO TRAN, etc.)
#   - 'q' or 'Q' to exit the script
#
# COMMON IMS COMMANDS:
#   /DIS ACTIVE          - Display active transactions
#   /DIS TRAN ALL        - Display all transactions
#   /DIS TRAN <name>     - Display specific transaction
#   /DIS PGM ALL         - Display all programs
#   /DIS DB ALL          - Display all databases
#   /STA TRAN <name>     - Start a transaction
#   /STO TRAN <name>     - Stop a transaction
#   /STA DB <name>       - Start a database
#   /STO DB <name>       - Stop a database
#
# NOTES:
#   - Commands are passed directly to CSLUSPOC without validation
#   - Invalid commands will be rejected by IMS with appropriate error messages
#   - Use Ctrl+C to force exit if needed (cleanup will still run via trap)
#*******************************************************************************
while true
do
    # Prompt user for IMS command input
    printf "Enter IMS Command (or 'q' to quit)> "
    read -r IMS_COMMAND

    # Check if user wants to quit (accepts both lowercase and uppercase 'q')
    if [[ "$IMS_COMMAND" == "q" ]] || [[ "$IMS_COMMAND" == "Q" ]]; then
        echo "Exiting..."
        exit 0
    fi

    # Issue the IMS command via CSLUSPOC
    issue_cmd "$IMS_COMMAND"
done
