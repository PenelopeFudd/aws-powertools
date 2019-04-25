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
shift "$((OPTIND-1))"

if [[ "$4" == "" ]]; then 
  echo "Usage: $0 [-p profile] [-r region] asg-name min max desired"
  echo "  This script will set the minimum, maximum and desired size limits of the specified ASG."
  exit 1
fi

if ! which jq > /dev/null 2>&1; then echo "The 'jq' command is not installed, aborting." >&2; exit 1; fi

aws $PROFILE $REGION autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$1" \
    |  jq -r '.AutoScalingGroups[] | [ .AutoScalingGroupName , .MinSize, .DesiredCapacity, .MaxSize ] | @csv'
aws $PROFILE $REGION autoscaling update-auto-scaling-group --auto-scaling-group-name "$1" --min-size "$2" --max-size "$3" --desired-capacity "$4"
aws $PROFILE $REGION autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$1" \
    |  jq -r '.AutoScalingGroups[] | [ .AutoScalingGroupName , .MinSize, .DesiredCapacity, .MaxSize ] | @csv'
