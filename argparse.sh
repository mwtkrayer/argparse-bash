#!/bin/bash
#
# A simple argument parser for bash.
#
# Requires at least bash 4, eval and printf.
#
# Usage:
#  - `source path/to/this/file` in any bash script.
#  - Call argparse_add_flag(), argparse_add_optional(), 
#    argparse_add_mandatory() and/or argparse_add_positional()
#    to add expected command line arguments.
#  - Call argparse_eval() to evaluated command line arguments.
#  - Call argparse_print_usage() to print usage message.
#  - The output is stored in the associative array argparse_output, 
#    which is indexed by the argument names.
#
declare -r _argp_prog_name=$0
declare    _argp_prog_desc=""
declare -r _argp_all_args=("$@")
declare    _argp_name=()  # name of named arguments, doubles as expanded argument name (e.g. help)
declare    _argp_char=()  # character for named arguments including dash (e.g. -h)
declare    _argp_val=()   # values
declare    _argp_help=()  # strings displayed in help
declare    _argp_type=()  # f,m,o,p for flag,mandatory,optional,positional
declare -A argparse_output=()

argparse_add_flag(){
  _argparse_assert "[[ '$#' == 3 ]]"             "[argparse_add_flag] expecting <name> <char> <help> arguments. (got $# arguments)"
  _argparse_assert "[[ '$1' =~ ^[a-zA-Z][a-zA-Z0-9_-]*\$ ]]" "[argparse_add_flag] expecting <name> as 1st argument: must contain letters only. (got $1)" 
  _argparse_assert "[[ '$2' =~ ^-[a-zA-Z]\$ ]]"  "[argparse_add_flag] expecting <char> as 2nd argument: must begin with - and contain only single letter only. (got $2)"
  _argparse_verify_state
  _argparse_verify_nonduplicate $1 $2
  _argp_name+=("$1")
  _argp_char+=("$2")
  _argp_val+=("0")
  _argp_help+=("$3")
  _argp_type+=("f")
}

argparse_add_optional(){
  _argparse_assert "[[ '$#' == 4 ]]"             "[argparse_add_optional] expecting <name> <char> <value> <help> arguments. (got $# arguments)"
  _argparse_assert "[[ '$1' =~ ^[a-zA-Z][a-zA-Z0-9_-]*\$ ]]" "[argparse_add_optional] expecting <name> as 1st argument: must contain letters only. (got $1)" 
  _argparse_assert "[[ '$2' =~ ^-[a-zA-Z]\$ ]]"  "[argparse_add_optional] expecting <char> as 2nd argument: must begin with - and contain only single letter only. (got $2)"
  _argparse_verify_state
  _argparse_verify_nonduplicate $1 $2
  _argp_name+=("$1")
  _argp_char+=("$2")
  _argp_val+=("$3")
  _argp_help+=("$4")
  _argp_type+=("o")
}

argparse_add_mandatory(){
  _argparse_assert "[[ '$#' == 3 ]]"             "[argparse_add_mandatory] expecting <name> <char> <help> arguments. (got $# arguments)"
  _argparse_assert "[[ '$1' =~ ^[a-zA-Z][a-zA-Z0-9_-]*\$ ]]" "[argparse_add_mandatory] expecting <name> as 1st argument: must contain letters only. (got $1)" 
  _argparse_assert "[[ '$2' =~ ^-[a-zA-Z]\$ ]]"  "[argparse_add_mandatory] expecting <char> as 2nd argument: must begin with - and contain only single letter only. (got $2)"
  _argparse_verify_state
  _argparse_verify_nonduplicate $1 $2
  _argp_name+=("$1")
  _argp_char+=("$2")
  _argp_val+=("NaN")
  _argp_help+=("$3")
  _argp_type+=("m")
}

argparse_add_positional(){
  _argparse_assert "[[ '$#' == 2 ]]"             "[argparse_add_positional] expecting <name> <help> arguments. (got $# arguments)"
  _argparse_assert "[[ '$1' =~ ^[a-zA-Z][a-zA-Z0-9_-]*\$ ]]" "[argparse_add_positional] expecting <name> as 1st argument: must contain letters only. (got $1)" 
  _argparse_verify_state
  _argparse_verify_nonduplicate $1 "-" # dummy char which should never match
  _argp_name+=("$1")
  _argp_char+=(" ")
  _argp_val+=("NaN")
  _argp_help+=("$2")
  _argp_type+=("p")
}

argparse_eval(){
  _argparse_verify_state
  declare -i narg=${#_argp_name[@]}
  declare -ai evald=() # flag whether argument has already been evaluated
  declare -i ii=0
  for (( ii=0; ii<${narg}; ii++ )); do 
    evald+=(0); 
  done
  # Evaluate the arguments
  declare -i readval=0
  declare -i iarg=-1
  declare -i ipos=0
  declare -i iargpos=-1 # iarg of last positional argument evaluated
  declare -i ifound=0
  for _input in ${_argp_all_args[*]}; do
    # If previous iteration expects a value to be read, do it now
    if [[ $readval > 0 ]]; then
      _argp_val[iarg]="${_input}"
      evald[iarg]=1
      readval=0
      continue
    fi
    # Determine the type of current argument
    ifound=0
    iarg=-1
    if [[ "${_input}" =~ ^-[a-zA-Z]$ ]]; then # char mode
      for (( ii=0; ii<${narg}; ii++ )); do
        if [[ "${_argp_char[ii]}" == "${_input}" ]]; then
          ifound=1
          iarg=$ii
          evald[iarg]=0;
          break
        fi
      done
      [[ $ifound == 0 ]] && argparse_print_usage && printf "[argparse_eval] Error! Unknown argument detected: %s\n" ${_input} 1>&2 && exit 254
    elif [[ "${_input}" =~ ^--[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then # name mode
      for (( ii=0; ii<${narg}; ii++ )); do
        if [[ "--${_argp_name[ii]}" == "${_input}" ]]; then
          ifound=1
          iarg=$ii
          evald[iarg]=0;
          break
        fi
      done
      [[ $ifound == 0 ]] && argparse_print_usage && printf "[argparse_eval] Error! Unknown argument detected: %s\n" ${_input} 1>&2 && exit 254
    else # positional mode
      for (( ii=${iargpos}+1; ii<${narg}; ii++ )); do
        if [[ "${_argp_type[ii]}" == "p" ]]; then
          ifound=1
          iarg=$ii
          iargpos=$iarg
          _argp_val[iarg]=${_input}  
          evald[iarg]=1;
          break
        fi
      done
      [[ $ifound == 0 ]] && argparse_print_usage && printf "[argparse_eval] Error! Too many positional arguments provided.\n" 1>&2 && exit 254
    fi
    # Determine if we need to read a value in next iteration
    if [[ ${ifound} > 0 ]] && [[ ${evald[iarg]} == 0 ]]; then 
      if [[ "${_argp_type[iarg]}" == "f" ]]; then
        _argp_val[iarg]=1  
        evald[iarg]=1;
      elif [[ "${_argp_type[iarg]}" == "m" ]] || [[ "${_argp_type[iarg]}" == "o" ]]; then
        readval=1;
      else
        printf "[argparse_eval] Internal error.\n" 1>&2 
        exit 250
      fi
    fi
  done
  # Verify that we are not missing mandatory or positional arguments
  for (( ii=0; ii<${narg}; ii++ )); do
    [[ "${_argp_type[ii]}" == "m" ]] && [[ "${evald[ii]}" == 0 ]] && argparse_print_usage && printf "[argparse_eval] Error! Mandatory argument '%s' missing.\n" "${_argp_name[ii]}" 1>&2 && exit 253
    [[ "${_argp_type[ii]}" == "p" ]] && [[ "${evald[ii]}" == 0 ]] && argparse_print_usage && printf "[argparse_eval] Error! Positional argument '%s' missing.\n" "${_argp_name[ii]}" 1>&2 && exit 253
  done
  # Assign output
  for (( ii=0; ii<${narg}; ii++ )); do
    argparse_output["${_argp_name[ii]}"]=${_argp_val[ii]}
  done
}

argparse_set_description(){
  _argp_prog_desc="$1"
}

argparse_print_usage(){
  # Usage string
  printf "Usage: %s" $_argp_prog_name
  declare -i narg=${#_argp_name[@]}
  declare -i ii=0
  for (( ii=0; ii<$narg; ii++ )); do
    if [[ "${_argp_type[ii]}" == "f" ]]; then
      printf ' [%s]' ${_argp_char[ii]}
    elif [[ "${_argp_type[ii]}" == "m" ]]; then
      printf ' %s <val>' ${_argp_char[ii]}
    elif [[ "${_argp_type[ii]}" == "o" ]]; then
      printf ' [%s <val>]' ${_argp_char[ii]}
    elif [[ "${_argp_type[ii]}" == "p" ]]; then
      printf ' <%s>' ${_argp_name[ii]}
    fi
  done
  printf '\n'
  # Program description
  printf "%s\n" "$_argp_prog_desc"
  # Options
  for (( ii=0; ii<$narg; ii++ )); do
    if [[ "${_argp_type[ii]}" == "f" ]]; then
      printf ' %2s|--%-32s %s\n' "${_argp_char[ii]}" "${_argp_name[ii]}" "${_argp_help[ii]}"
    elif [[ "${_argp_type[ii]}" == "m" ]]; then
      printf ' %2s|--%-32s %s\n' "${_argp_char[ii]}" "${_argp_name[ii]} <val>" "${_argp_help[ii]}"
    elif [[ "${_argp_type[ii]}" == "o" ]]; then
      printf ' %2s|--%-32s %s (Default: "%s")\n' "${_argp_char[ii]}" "${_argp_name[ii]} <val>" "${_argp_help[ii]}" "${_argp_val[ii]}"
    elif [[ "${_argp_type[ii]}" == "p" ]]; then
      printf ' %-37s %s\n' "<${_argp_name[ii]}>" "${_argp_help[ii]}"
    fi
  done
}

_argparse_assert(){
  eval "$1" && return 0 || printf "%s" "$2" 1>&2 && return 255
}

_argparse_verify_state(){
  _argparse_assert "[[ '${#_argp_name[@]}' == '${#_argp_char[@]}' ]]" "[_argparse_verify_state] corrupted state detected!"
  _argparse_assert "[[ '${#_argp_name[@]}' == '${#_argp_val[@]}' ]]"  "[_argparse_verify_state] corrupted state detected!"
  _argparse_assert "[[ '${#_argp_name[@]}' == '${#_argp_help[@]}' ]]" "[_argparse_verify_state] corrupted state detected!"
  _argparse_assert "[[ '${#_argp_name[@]}' == '${#_argp_type[@]}' ]]" "[_argparse_verify_state] corrupted state detected!"
}

_argparse_verify_nonduplicate(){
  _argparse_assert "[[ ! ' ${_argp_name[*]} ' =~ ' $1 ' ]]" "[_argparse_check_duplicate] duplicate name detected! (got $1)"
  _argparse_assert "[[ ! ' ${_argp_char[*]} ' =~ ' $2 ' ]]" "[_argparse_check_duplicate] duplicate char detected! (got $2)"
}
