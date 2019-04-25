#!/bin/bash

# Parse arguments:
while getopts ":r:p:v" opt; do
  case $opt in
    r) REGION="--region $OPTARG";;
    p) PROFILE="--profile $OPTARG";;
    v) VERBOSE="$VERBOSE -v";;
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


if [[ "$VERBOSE" == " -v -v" ]]; then
  if [[ "$1" != "" ]]; then 
    buckets=($(echo "$@" | sed 's,s3://,,g'))
  else
    if ! buckets=($(myaws s3api list-buckets | jq -r '.Buckets[].Name')) ; then echo "No buckets found" >&2; exit 0; fi
  fi

  for n in "${buckets[@]}"; do 
    if ! list=$(myaws s3api list-objects-v2 --bucket "$n"); then exit 1; fi
    echo "$list" | jq -r --arg n "$n" '"s3://\($n)/\(.Contents[].Key)"'
  done

  exit
fi

if [[ "$VERBOSE" == " -v" ]]; then myaws s3 ls; exit $?; fi

myaws s3api list-buckets | jq -r '"s3://\(.Buckets[].Name)"'
