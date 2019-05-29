#!/bin/bash

# Parse arguments:
VERBOSE=0
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


if [[ "$VERBOSE" == 0 ]]; then
  aws $PROFILE $REGION sns list-topics | jq -r '.Topics[].TopicArn'
  exit 0
fi
if [[ "$VERBOSE" == 1 ]]; then
  a=$(aws $PROFILE $REGION sns list-topics | jq -r '.Topics[].TopicArn')
  for n in $a; do aws $PROFILE $REGION sns get-topic-attributes --topic-arn "$n"; done
  exit 0
fi
if [[ "$VERBOSE" == 2 ]]; then
  aws $PROFILE $REGION sns list-topics 
  exit 0
fi
