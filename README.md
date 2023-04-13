# argparse-bash
A simple argument parser for bash with a minimum set of features and dependencies.

## Usage
An example using all features is given in `example.sh`. `argparse.sh` is supposed 
to be sourced in the host script and arguments are to be added using the provided
functions:
```
argparse_add_flag       <name> <char>                 <usage descriptor>
argparse_add_optional   <name> <char> <default value> <usage descriptor>
argparse_add_mandatory  <name> <char>                 <usage descriptor>
argparse_add_positional <name>                        <usage descriptor>
```
A usage message can be printed using `argparse_print_usage`, where the program 
description can be set beforehand using `argparse_set_description`. The parsing
occurs during the call of `argparse_eval` and the output is available in the 
associative array `argparse_output`, which is supposed to be indexed using the 
corresponding argument name.
