#!/bin/bash

# Defaults:
IMAGEID="--image-id ami-32f14356"
TYPE="--instance-type t2.micro"
PLACEMENT="--placement AvailabilityZone=ca-central-1a"

if [[ "$1" == "" ]]; then
  echo "Usage: ${0##*/} [-p profile] [-r region] [-i ami-12341234] [-t t2.micro] [-l availabilityzone]"
  echo "  This script creates an EC2 instance."
  echo ""
  echo "Options:"
  echo "  -p profile: which aws profile to use from ~/.aws/config."
  echo "  -r region: create the instance in which region?  Default defined in the ~/.aws/config file."
  echo "  -i image-id: copy this image as the starting filesystem.  Default: ${IMAGEID##* }"
  echo "  -t type: use this type of instnace.  Default: ${TYPE##* }"
  echo "  -l placement: use this availability zone.  Default: ${PLACEMENT##*=}"
  exit 1
fi

# Parse arguments:
while getopts ":r:p:i:t:l:v" opt; do
  case $opt in
    r) REGION="--region $OPTARG";;
    p) PROFILE="--profile $OPTARG";;
    i) IMAGEID="--image-id $OPTARG";;
    t) TYPE="--instance-type $OPTARG";;
    l) PLACEMENT="--placement AvailabilityZone=$OPTARG";;
    v) VERBOSE=$(( VERBOSE + 1 ));;
    :) echo "Option -$OPTARG requires an argument." >&2; exit 1;;
    \?) echo "Invalid option: -$OPTARG" >&2;;
  esac
done
shift $((OPTIND-1))
a=$(aws $PROFILE $REGION ec2 run-instances $IMAGEID $TYPE $PLACEMENT)
echo "$a"
