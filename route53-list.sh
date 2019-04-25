#!/bin/bash
if [[ "$1" == "" ]]; then
  echo "Usage: ${0##*/} profile [id]"
  echo "  Given a profile, this will list the ids and names of its hosted zones."
  echo "  Given a profile and id, this will list the records in a hosted zone."
  echo "Example:"
  echo "  ${0##*/} 578793564162.ReadOnly"
  echo "    /hostedzone/Z2KA0H9G7DMJ21  servicelookup.internal."
  echo "    /hostedzone/Z2AS4ETD4KYBOL  alpha.things.us-west-2.bluesky.work."
  echo "    /hostedzone/Z6AUJUY7VSN82   z0.alpha.things.us-west-2.bluesky.work."
  echo "    /hostedzone/ZHU8OC79WEOIP   test.z0.alpha.things.us-west-2.bluesky.work."
  echo "  ${0##*/} 578793564162.ReadOnly /hostedzone/Z2AS4ETD4KYBOL"
  echo "    alpha.things.us-west-2.bluesky.work.          NS   ns-1896.awsdns-45.co.uk."
  echo "    control.alpha.things.us-west-2.bluesky.work.  A    thingscontrols-elb-1wn15v48f1i3n-511726100.us-west-2.elb.amazonaws.com."
  exit
fi

if ! which jq > /dev/null 2>&1; then echo "The 'jq' command is not installed, aborting." >&2; exit 1; fi


# Given a profile only:
if [[ "$2" == "" ]]; then
  a=$(aws --profile "$1" route53 list-hosted-zones 2>&1)
  if [[ ! "$a" =~ ^[{] ]]; then echo "$a" >&2; exit 1; fi
  echo "$a" | jq -r '.HostedZones[] | "\(.Id) \(.Name)"' | column -t | sort -k2
  exit 0
fi

# Given a profile and a hosted zone id:
hid="$2"
if [[ ! $hid =~ ^/ ]]; then hid="/hostedzone/$2"; fi

a=$(aws --profile "$1" route53 list-resource-record-sets --hosted-zone-id "$hid" 2>&1)
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
