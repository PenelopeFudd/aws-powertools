#!/bin/bash

VERBOSE=0
# Parse arguments:
while getopts ":lr:p:vd" opt; do
  case $opt in
    l) ALL=1;;
    r) REGION="--region $OPTARG";;
    p) PROFILE="--profile $OPTARG";;
    v) VERBOSE=$(( VERBOSE + 1 ));;
    d) DEBUG=$(( DEBUG + 1 ));;
    :) echo "Option -$OPTARG requires an argument." >&2; exit 1;;
    \?) echo "Invalid option: -$OPTARG" >&2;;
  esac
done
shift $((OPTIND-1))

if [[ "$1" == "" && "$ALL" == "" ]]; then
  echo "Usage: ${0##*/} [-p profile] [-r region] topic-rule-name [topic-rule-names...]"
  echo "       ${0##*/} [-p profile] [-r region] -l"
  echo "  This script enumerates some or all IoT topic rules, finds the Lambda functions, finds the resources the lambda functions need (lambda/iam/dynamodb/s3/rds/sns)"
  exit 1
fi

TODO=( "$@" )
if [[ "$ALL" ]]; then
  TODO=( $(aws $PROFILE $REGION iot list-topic-rules --query 'rules[].ruleName' --output text | fmt -w 2 | sort) )
fi

for n in "${TODO[@]}"; do 
  echo "==================================================="
  echo "IoT Topic Rule: $n"
  lambdaName=$(aws $PROFILE $REGION iot get-topic-rule --rule-name "$n" --query 'rule.actions[].lambda.functionArn' --output text 2>&1 | sed 's/.*://')
  if ! lambdaFunction=$(aws $PROFILE $REGION lambda get-function --function-name "$lambdaName"); then
    echo "Error, lambda function $lambdaName (called by IoT topic rule $n) was not found!"
    continue
  fi

  if ! lambdaPolicy=$(aws $PROFILE $REGION lambda get-policy --function-name "$lambdaName" 2>&1); then
    echo "No Policy found for lambda function $lambdaName"
    echo ""
  else
    echo "Policy for lambda function ${lambdaName}:"
    echo "$lambdaPolicy" | jq '.Policy | fromjson | .Statement[] '
  fi

  echo "Lambda function > $lambdaName"
  echo ""

  location=$(echo "$lambdaFunction" | jq -r '.Code.Location')
  handler=$(echo "$lambdaFunction" | jq -r '.Configuration.Handler')
  echo "handler=$handler"
  runtime=$(echo "$lambdaFunction" | jq -r '.Configuration.Runtime')
  echo "runtime=$runtime"
  role=$(echo "$lambdaFunction" | jq -r '.Configuration.Role')
  echo "role=$role"
  echo ""
  #echo "Environ raw:"
  #echo "$lambdaFunction" | jq -r '.Configuration'
  environ=$(echo "$lambdaFunction" | jq -r '(.Configuration.Environment.Variables // {} ) | to_entries | .[] | @sh "\(.key)=\(.value)"')
  echo ""
  echo "Environ:"
  echo "$environ"
  echo ""

  #TEMPFILE=lambda.zip
  #echo "See lambda.zip for $n"

  TEMPFILE=$(mktemp --tmpdir)
  trap "rm -f '$TEMPFILE'" EXIT

  curl -sS "$location" > "$TEMPFILE"

  h="${handler%%.*}"
  sourceName=$(unzip -l "$TEMPFILE" | gawk -vh="$h" '$1 ~ /^[0-9]+$/ && $2 ~ /^[0-9]+-[0-9]+-[0-9]{4}$/ && match(substr($0,31),"^("h"[.].*)$",a) {print a[1]}')
  if [[ "$sourceName" == "" ]]; then
    echo "Can't determine source from handler name $handler"
    exit 1
  fi
  echo "sourceName=$sourceName"
  echo ""

  arns=$(echo "$environ" | grep -o 'arn:.*')
  if [[ "$arns" != "" ]]; then
    echo "ARNs found:"
    echo "$arns"
    echo ""
  fi

  endpoints=$(echo "$environ" | grep -o '[a-z0-9.-]*[.]rds[.]amazonaws[.]com')
  if [[ "$endpoints" != "" ]]; then
    echo "RDS endpoints found:"
    echo "$endpoints"
    echo ""
  fi


  source=$(unzip -p "$TEMPFILE" "$sourceName" | tr -d '\r')


  botoCalls=$(echo "$source" | grep 'boto3[.]')
  if [[ "$botoCalls" != "" ]]; then
    echo "BOTO calls made:"
    echo "$botoCalls"
    echo ""
  fi

  psycopg2=$(echo "$source" | grep 'psycopg2')
  if [[ "$psycopg2" != "" ]]; then
    echo "psycopg2 calls made:"
    echo "$psycopg2"
    echo ""
  fi

  #echo "$source"

done
