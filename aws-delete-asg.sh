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

aws $PROFILE $REGION autoscaling delete-auto-scaling-group --auto-scaling-group-name "$1" --force

starttime=$(date +%s)
# Wait for deletion:
sleeptime=2
count=20
while ! aws $PROFILE $REGION autoscaling describe-auto-scaling-groups --auto-scaling-group-name="$1" | grep -q '"AutoScalingGroups": \[\]'; do
  sleep $sleeptime
#  sleeptime=$(( $sleeptime + 1 ))
#  if [[ "$sleeptime" > 60 ]]; then sleeptime=60; fi
  count=$(( count - 1 ))
  if [[ "$count" -lt 1 ]]; then echo "Timeout deleting $1" >&2; exit 1; fi
done
endtime=$(date +%s)
timediff=$(( endtime - starttime ))
echo "OK - Deleted $1 after $timediff seconds" >&2
exit 0
