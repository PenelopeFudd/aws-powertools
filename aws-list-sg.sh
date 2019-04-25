#!/bin/bash

# Parse arguments:
while getopts ":r:p:v" opt; do
  case $opt in
    r) REGION="--region $OPTARG";;
    p) PROFILE="--profile $OPTARG";;
    v) VERBOSE=$(( VERBOSE + 1 ));;
    :) echo "Option -$OPTARG requires an argument." >&2; exit 1;;
    \?) echo "Invalid option: -$OPTARG" >&2;;
  esac
done
shift $((OPTIND-1))

if ! which jq > /dev/null 2>&1; then echo "The 'jq' command is not installed, aborting." >&2; exit 1; fi


if [[ "$VERBOSE" == 1 ]]; then
  aws $PROFILE $REGION ec2 describe-security-groups | jq -r '.SecurityGroups[] | [.GroupId,.GroupName] | @csv'  
elif [[ "$VERBOSE" == 2 ]]; then
  aws $PROFILE $REGION ec2 describe-security-groups | jq .
else
  aws $PROFILE $REGION ec2 describe-security-groups | jq -r '.SecurityGroups[].GroupId'  
fi
