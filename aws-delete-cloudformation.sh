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
if [[ "$1" == "" ]]; then
  echo "Usage: ${0##*/} [-p profile] [-r region] stack-name"
  echo "  This will delete the given cloudformation stack"
  exit 1
fi

Identity=$(aws $PROFILE sts get-caller-identity 2>&1)
if [[ "$Identity" =~ Unable.to.locate.credentials ]]; then
  echo "Error, the given profile was not found." >&2
  exit 1
fi
if [[ "$Identity" =~ An.error.occurred..ExpiredToken ]]; then
  echo "Error, the given profile has expired." >&2
  exit 1
fi
account=$(echo "$Identity" | jq -r '.Account')
role=$(echo "$Identity" | jq -r '.Arn | sub("arn:aws:sts::[0-9]*:assumed-role/";"") | sub("/.*"; "")')



result=$(aws $PROFILE $REGION cloudformation describe-stacks --stack-name "$1" 2>&1)
if [[ "$result" =~ An.error.occurred ]]; then
  echo "$result" | grep -o '^An error.*' >&2
  exit 1
fi
StackId=$(echo "$result" | jq -r '.Stacks[] | .StackId')

echo "Deleting $1..."
result=$(aws $PROFILE $REGION cloudformation delete-stack --stack-name "$1" 2>&1)
if [[ "$result" =~ An.error.occurred ]]; then
  echo "$result" | grep -o '^An error.*' >&2
  exit 1
fi
echo ""

function getstatus() {
  aws $PROFILE $REGION cloudformation describe-stacks --stack-name "$1" | jq -r '.Stacks[] | .StackStatus'
}

echo "Waiting for stack deletion:"
START=$(date +%s)
while sleep 10; do
  status=$(getstatus "$StackId")
  if [[ "$status" != "$oldstatus" ]] ; then echo $(date +"%F %T") "$status"; oldstatus="$status"; fi
  if [[ ! "$status" =~ IN_PROGRESS ]]; then break; fi
  sleep 10
done
echo "Total time: $(( $(date +%s) - START ))"
echo "Final status: $status"
if [[ "$status" =~ FAILED || "$status" =~ ROLLBACK_COMPLETE$ ]]; then exit 1; fi
