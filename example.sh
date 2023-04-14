#!/bin/bash
set -e

# Set command line arguments for demo
set -- -f -o some_string --mandatory 123 file.txt

# Load argparse
source argparse.sh

# Set a program description which will be displayed in the 'usage' printout
argparse_set_description "$(cat << EOM
This is some description.
With multiple lines.
EOM
)"

# Define various types of arguments: flag, optional, mandatory, positional
argparse_add_flag       "flag"      "-f"                  "This is a flag. 0 if not set, 1 otherwise"
argparse_add_optional   "option"    "-o" "another_string" "This is an optional argument, which expects a value."
argparse_add_mandatory  "mandatory" "-m"                  "This is a mandatory argument, which expects a value"
argparse_add_positional "positional"                      "This is a positional argument."
argparse_add_flag       "help"      "-h"                  "Print this message and exit."


# Evaluate arguments and print results
argparse_eval
printf "flag       = %s\n" ${argparse_output["flag"]}
printf "option     = %s\n" ${argparse_output["option"]}
printf "mandatory  = %s\n" ${argparse_output["mandatory"]}
printf "positional = %s\n" ${argparse_output["positional"]}

# Print 'usage' message to screen, if -h flag is set
[[ ${argparse_output["help"]} > 0 ]] && argparse_print_usage && exit 0
