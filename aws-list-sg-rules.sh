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

if [[ "$VERBOSE" != "" ]]; then
  aws $PROFILE $REGION ec2 describe-security-groups
else
  aws $PROFILE $REGION ec2 describe-security-groups \
    | jq --arg profile "$PROFILE" -r '.SecurityGroups[] 
       | "aws \($profile) ec2 revoke-security-group-ingress --group-id \( .GroupId )" as $start 
       | .IpPermissions[] 
       | select(.IpProtocol != "-1")
       | (if .IpProtocol == "icmp" then
           "-1"
         else
           if .FromPort == .ToPort then
             "\( .FromPort )"
           else
             "\( .FromPort )-\(.ToPort)"
           end
         end) as $port

         |  "--protocol \( .IpProtocol ) --port \( $port )" as $middle 
       | if 
           .UserIdGroupPairs? | length > 0
         then
           "\($start) \($middle) --source-group \( .UserIdGroupPairs[0].GroupId )"
         else 
           "\($start) \($middle) --cidr \( .IpRanges[].CidrIp )"
         end 
       ' 
fi
