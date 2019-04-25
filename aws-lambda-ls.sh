#!/bin/bash

# Parse arguments:
TEMP=$(getopt -o p:vj -l profile:,verbose,json -- "$@")
if [ $? != 0 ]; then 
  echo "Usage: $0 [-p profile] [-v] [-j]"
  echo "  This script lists the lambda functions in the account."
  echo "  Options:"
  echo "    -v: Be verbose"
  echo "    -j: Dump json output"
  echo "    -p profile: Use a non-default aws profile from ~/.aws/config"
  exit 1
fi
eval set -- "$TEMP"
while [[ "$1" != "" ]] ; do
  case "$1" in
    -p|--profile) PROFILE="--profile $2"; shift ;;
    -v|--verbose) VERBOSE=1;;
    -j|--json) JSON=1;;
    --) shift; break;;
    *) echo "Error: '$1' is not a valid option." 1>&2; exit 1;;
  esac
  shift
done

a=$(aws $PROFILE lambda list-functions 2>&1)
if [[ "$a" =~ The\ config\ profile\ .*\ could\ not\ be\ found ]]; then echo "Error: $a" >&2 ; exit 1; fi
if [[ "$a" =~ An\ error\ occurred ]]; then echo "Error: $a" >&2; exit 1; fi

if [[ "$JSON" == 1 ]]; then echo "$a" | jq -S '.Functions | sort_by(.FunctionName | ascii_downcase)' ; exit 0; fi
#if [[ "$VERBOSE" == 1 ]]; then echo "$a" | jq .; exit 0; fi
echo "$a" | jq -r ".Functions[].FunctionName" | sort
