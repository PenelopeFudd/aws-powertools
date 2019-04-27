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

data=$(aws $PROFILE $REGION ec2 describe-internet-gateways --internet-gateway-ids "$1")
if [[ "$data" == "" ]]; then exit 1; fi

vpcid=$(echo "$data" | jq -r '.InternetGateways[0].Attachments[].VpcId')
if [[ "$vpcid" != "null" ]]; then
  for vpc in $vpcid; do
    aws $PROFILE $REGION ec2 detach-internet-gateway --internet-gateway-id "$1" --vpc-id "$vpc"
  done
fi
aws $PROFILE $REGION ec2 delete-internet-gateway --internet-gateway-id "$1"
