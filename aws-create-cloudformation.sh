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

if [[ "$2" == "" ]]; then
  echo "Usage: $0 [-p profile] [-r region] [-v] stack-name template-filename"
  echo "  This script will create the given stack specified by the template."
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

FILE="$2"
if [[ ! "$2" =~ ^/ ]]; then FILE="./$FILE"; fi
echo "Creating cloudformation stack $1 from $FILE..."

result=$(aws $PROFILE $REGION cloudformation create-stack --stack-name "$1" --template-body file://"$FILE" 2>&1)
if [[ ! "$result" =~ StackId.*arn:aws:cloudformation: ]]; then
  echo "$result" >&2
  exit 1
fi

StackId=$(echo "$result" | jq -r '.StackId')

# Get the Isengard link for watching this stack:
URL=$(jq -n --arg account "$account" --arg role "$role" --arg StackId "$StackId" '
  ( "cloudformation/home?region=us-west-2#/stack/detail?stackId=\($StackId)" | @uri ) as $destination |
    "https://isengard.amazon.com/federate?account=\($account)&role=\($role)&destination=\($destination)"
  ')

echo ""
echo "Updates here: $URL"
echo ""

function getstatus() {
  aws $PROFILE $REGION cloudformation describe-stacks --stack-name "$1" | jq -r '.Stacks[] | .StackStatus'
}

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
