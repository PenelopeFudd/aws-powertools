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

function setval { printf -v "$1" "%s" "$(cat)"; declare -p "$1"; }
function myaws () {
  local stdval
  local errval
  local retval
  local retrycount=4
  while [[ $retrycount -gt 0 ]] ; do 
    retrycount=$(( retrycount -1 ))
    eval "$( aws $PROFILE $REGION "$@" 2> >(setval errval) > >(setval stdval); <<<"$?" setval retval; )"
    #echo "std out is : |$stdval| std err is : |$errval| return val is : |$retval|"
    # Success:
    if [[ "$retval" == 0 ]]; then echo "$stdval"; return 0; fi
    # Throttled:
    if [[ "$errval" =~ RequestLimitExceeded ]]; then echo "$errval" 1>&2; continue; fi
    # Other error:
    echo "$stdval"
    echo "$errval" >&2
    return "$retval"
  done
  echo "Too many retries, giving up." >&2
  exit
}

function ec2 () { myaws ec2 "$@"; }
function autoscaling () { myaws autoscaling "$@"; }
function listasgs () { autoscaling describe-auto-scaling-groups | jq -r '.AutoScalingGroups[].AutoScalingGroupName'; }
function deleteasg () { autoscaling delete-auto-scaling-group --auto-scaling-group-name "$1" --force-delete; }

if ! asgs=$(listasgs); then exit 1; fi
echo "found these asgs, trying to delete them: $asgs"
for n in $asgs; do 
  echo Deleting $n
  deleteasg $n
done
