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
policies=$(aws $PROFILE $REGION iam list-attached-role-policies --role-name "$1" --query 'AttachedPolicies[*].PolicyArn' --output text)
for n in $policies; do 
  aws $PROFILE $REGION iam detach-role-policy --role-name "$1" --policy-arn "$n"
done
aws $PROFILE $REGION iam delete-role --role-name "$1"
