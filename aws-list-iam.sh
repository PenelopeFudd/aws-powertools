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
  aws $PROFILE $REGION iam list-roles | jq -r '.Roles[].RoleName'
  exit 0
fi
if [[ "$VERBOSE" == 1 ]]; then
  all=$(aws $PROFILE $REGION iam list-roles)
  roles=$(echo "$all" | jq -r '.Roles[].RoleName')

  for n in $roles; do 
    echo "# Role: $n"

    thisrole=$(echo "$all" | jq -r --arg n "$n" '.Roles[] | select(.RoleName == $n)')

    assumepolicy=$(echo "$thisrole" | jq -c '.AssumeRolePolicyDocument')
    echo "aws $PROFILE $REGION iam create-role --role-name $n --assume-role-policy-document '$assumepolicy'"

    aws $PROFILE $REGION iam list-attached-role-policies --role-name $n \
      | jq -r --arg n "$n" --arg PROFILE "$PROFILE" --arg REGION "$REGION" \
        '"  aws \($PROFILE) \($REGION) iam attach-role-policy --role-name \($n) --policy-arn \(.AttachedPolicies[].PolicyArn)"'

    echo ""
  done
  exit 0
fi
if [[ "$VERBOSE" == 2 ]]; then
  aws $PROFILE $REGION iam list-roles 
  exit 0
fi
