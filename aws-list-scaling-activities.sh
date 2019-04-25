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


if [[ "$VERBOSE" != "" ]]; then
  aws $PROFILE $REGION autoscaling describe-scaling-activities --max-items 60
else
  aws $PROFILE $REGION autoscaling describe-scaling-activities --max-items 60 | jq -r '.Activities[] | [ .StartTime, .AutoScalingGroupName , .Description ] | @tsv' | sort
fi
