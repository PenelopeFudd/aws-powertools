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

if ! which jq > /dev/null 2>&1; then echo "The 'jq' command is not installed, aborting." >&2; exit 1; fi


function setval { printf -v "$1" "%s" "$(cat)"; declare -p "$1"; }
function myaws () {
  local stdval
  local errval
  local retval
  local retrycount=8
  while [[ $retrycount -gt 0 ]] ; do 
    retrycount=$(( retrycount-1 ))
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
function listlcs () { autoscaling describe-launch-configurations | jq -r '.LaunchConfigurations[].LaunchConfigurationName'; }

function cacheAsgs  () { autoscaling describe-auto-scaling-groups ; }
function cacheInstances  () { ec2 describe-instances ; }

function listasgs () { echo "$1" | jq -r '.AutoScalingGroups[].AutoScalingGroupName'; }

function showAsgsForLc () {
    echo "$1" | jq -r --arg lc "$2" '.AutoScalingGroups[] | select(.LaunchConfigurationName == $lc) | .AutoScalingGroupName';
}

function showInstancesForAsg () {
  echo "$1" | jq -r --arg asg "$2" '.AutoScalingGroups[] | select(.AutoScalingGroupName == $asg) | .Instances[].InstanceId';
}

function showInstance () {
  echo "$1" | jq -r --arg id "$2" '.Reservations[].Instances[] | select(.InstanceId == $id) | [ .InstanceId, .ImageId, .InstanceType, .State.Name, .StateReason.Message] | @csv'
}

if ! lcs=$(listlcs); then exit 1; fi

asgOutput=$(cacheAsgs)
ec2Output=$(cacheInstances)

for n in $lcs; do 
  #if [[ ! "$n" =~ cgh ]]; then continue; fi
  echo "Launch Configuration: $n"
  asgs=$(showAsgsForLc "$asgOutput" $n)
  for m in $asgs; do 
    echo "  AutoScaling Group: $m"
    instances=$(showInstancesForAsg "$asgOutput" $m)
      for l in $instances; do 
        showInstance "$ec2Output" $l | sed 's/^/    Instance: /'
      done
  done
done
