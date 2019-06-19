#!/bin/bash
# Parse arguments:
VERBOSE=0
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

if ! which jq > /dev/null 2>&1; then echo "The 'jq' command is not installed, aborting." >&2; exit 1; fi

if [[ "$DEBUG" == 1 ]]; then
  aws $PROFILE $REGION ec2 describe-instances
  exit 0
fi

if [[ "$VERBOSE" == 2 ]]; then
# Very Verbose:
  aws $PROFILE $REGION ec2 describe-instances | jq '.Reservations[].Instances[]'
  exit 0
fi

if [[ "$VERBOSE" == 1 ]]; then

  # Verbose:
  # From https://ilya-sher.org/2016/05/11/most-jq-you-will-ever-need/ 

  #i-001533ad96dad3eb3  Test webpage server  something-integ-test-server  -               172.31.7.204   2017-03-28T20:32:58  t2.micro   running

  JQCODE='.Reservations[].Instances[] 
     | "
      \(.InstanceId)
     %\"\(if .Tags and ([.Tags[] | select ( .Key == "Name" )] != []) then .Tags[] | select ( .Key == "Name" ) | .Value else "-" end)\"
     %\"\(if .Tags and ([.Tags[] | select ( .Key == "aws:cloudformation:stack-name" )] != []) then .Tags[] | select ( .Key == "aws:cloudformation:stack-name" ) | .Value else "-" end)\"
     %\(.KeyName)
     %\(if .PublicIpAddress then .PublicIpAddress else "-" end)
     %\(if .PrivateIpAddress then .PrivateIpAddress else "-" end)
     %\(.LaunchTime)
     %\(.InstanceType)
     %\(.State.Name)
     "'
   JQCODE=$(echo "$JQCODE" | sed 's/^ *//' | tr -d '\n' ) # jq doesn't like newlines in the code, leading spaces killed formatting.
# Other tags:
#     %\"\(if .Tags then [.Tags[] | select( .Key != "Name") |"\(.Key)=\(.Value)"] | join(",") else "-" end)\"

  echo "# aws $PROFILE $REGION ec2 describe-instances"
  (echo "InstanceId%Name%StackName%KeyName%PublicIpAddress%PrivateIpAddress%LaunchTime%InstanceType%State";
      aws $PROFILE $REGION ec2 describe-instances  \
      | jq -r "$JQCODE"  \
      | sed 's/.000Z//g'  \
      | LANG=C sort -t% -k 6 
    ) \
      | column -t -s '%' \

  exit 0
fi

if [[ "$VERBOSE" == 0 ]]; then
  # Brief:
  aws $PROFILE $REGION ec2 describe-instance-status | jq -r '.InstanceStatuses[].InstanceId' | sort
  exit 0
fi

