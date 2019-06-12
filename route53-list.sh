#!/bin/bash
# Parse arguments:
OLDARG="$1"
VERBOSE=0
# Parse arguments:
while getopts ":r:p:vd" opt; do
  case $opt in
    r) REGION="--region $OPTARG";;
    p) PROFILE="--profile $OPTARG";;
    v) VERBOSE=$(( VERBOSE + 1 ));;
    d) DEBUG=$(( DEBUG + 1 ));;
    :) echo "Option -$OPTARG requires an argument." >&2; exit 1;;
    \?) echo "Invalid option: -$OPTARG" >&2;;
  esac
done
shift $((OPTIND-1))

if [[ "$OLDARG" == "" ]]; then
  echo "Usage: ${0##*/} [-p profile] [id]"
  echo "  Given a profile, this will list the ids and names of its hosted zones."
  echo "  Given a profile and id, this will list the records in a hosted zone."
  echo "Example:"
  echo "  ${0##*/} -p 578793564162.ReadOnly"
  echo "    /hostedzone/Z2KA0H9G7DMJ21  servicelookup.internal."
  echo "    /hostedzone/Z2AS4ETD4KYBOL  alpha.things.us-west-2.bluesky.work."
  echo "    /hostedzone/Z6AUJUY7VSN82   z0.alpha.things.us-west-2.bluesky.work."
  echo "    /hostedzone/ZHU8OC79WEOIP   test.z0.alpha.things.us-west-2.bluesky.work."
  echo "  ${0##*/} -p 578793564162.ReadOnly /hostedzone/Z2AS4ETD4KYBOL"
  echo "    alpha.things.us-west-2.bluesky.work.          NS   ns-1896.awsdns-45.co.uk."
  echo "    control.alpha.things.us-west-2.bluesky.work.  A    thingscontrols-elb-1wn15v48f1i3n-511726100.us-west-2.elb.amazonaws.com."
  exit
fi

if ! which jq > /dev/null 2>&1; then echo "The 'jq' command is not installed, aborting." >&2; exit 1; fi

# Given a profile only:
if [[ "$1" == "" ]]; then
  a=$(aws $PROFILE route53 list-hosted-zones 2>&1)
  if [[ ! "$a" =~ ^[{] ]]; then echo "$a" >&2; exit 1; fi
  echo "$a" | jq -r '.HostedZones[] | "\(.Id) \(.Name)"' | column -t | sort -k2
  exit 0
fi

# Given a profile and a hosted zone id:
hid="$1"
if [[ ! $hid =~ ^/ ]]; then hid="/hostedzone/$1"; fi

a=$(aws $PROFILE route53 list-resource-record-sets --hosted-zone-id "$hid" 2>&1)
if [[ ! "$a" =~ ^[{] ]]; then echo "$a" >&2; exit 1; fi

echo "$a" | jq -r '.ResourceRecordSets[] 
         | .Name as $name 
         | .Type as $type 
         | if .ResourceRecords? then 
             ( .ResourceRecords[] | "\($name)\t\($type)\t\(.Value)")
           else
             "\($name)\t\($type)\t\(.AliasTarget.DNSName)"
           end' \
             | sort | column -s$'\t' -t
