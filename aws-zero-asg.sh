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
aws $PROFILE $REGION autoscaling describe-auto-scaling-groups --auto-scaling-group-name="$1"
aws $PROFILE $REGION autoscaling update-auto-scaling-group    --auto-scaling-group-name="$1" --min-size         0
aws $PROFILE $REGION autoscaling set-desired-capacity         --auto-scaling-group-name="$1" --desired-capacity 0 --no-honor-cooldown
aws $PROFILE $REGION autoscaling update-auto-scaling-group    --auto-scaling-group-name="$1" --max-size         0
aws $PROFILE $REGION autoscaling describe-auto-scaling-groups --auto-scaling-group-name="$1"

exit 0
