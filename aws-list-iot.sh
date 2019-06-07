#!/bin/bash
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

if ! which jq > /dev/null 2>&1; then echo "The 'jq' command is not installed, aborting." >&2; exit 1; fi

if [[ "$VERBOSE" == 0 ]]; then
  aws $PROFILE $REGION iot list-topic-rules --query 'rules[].ruleName' --output text | fmt -w 2 | sort
fi

# Verbose:
if [[ "$VERBOSE" == 1 ]]; then
  for n in $(aws $PROFILE $REGION iot list-topic-rules --query 'rules[].ruleName' --output text | fmt -w 2 | sort) ; do
    aws $PROFILE $REGION iot get-topic-rule --rule-name "$n"
  done \
    | (echo IoT_Topic_Rule,Lambda_Function; jq -r ". \
      | .rule.ruleName as \$IoTName \
      | .rule.actions[].lambda.functionArn \
      | (. | gsub(\".*:\"; \"\")) as \$lambdaName
      | [\$IoTName, \$lambdaName] \
      | @csv \
      " | sort ) \
    | sed 's/"//g' \
    | column -t -s,
fi

# Very verbose
if [[ "$VERBOSE" == 2 ]]; then
  for n in $(aws $PROFILE $REGION iot list-topic-rules --query 'rules[].ruleName' --output text | fmt -w 2 | sort) ; do

    aws $PROFILE $REGION iot get-topic-rule --rule-name "$n" \
      | jq -rc \
   --arg PROFILE "$PROFILE" \
   --arg REGION "$REGION" \
    '
    ({
      "ruleName": .rule.ruleName,
      "topicRulePayload": {
	"sql": .rule.sql,
	"description": .rule.description,
	"actions": .rule.actions,
	"ruleDisabled": .rule.ruleDisabled,
	"awsIotSqlVersion": .rule.awsIotSqlVersion
      }
    } | tojson|@sh) as $json
    | ("# IoT Topic Rule \(.rule.ruleName)",
        ([ "aws", $PROFILE, $REGION, "iot", "create-topic-rule", "--cli-input-json", $json ] | join(" ")),
	""
      )
  '
  done
  exit 0
fi

# Very very verbose
if [[ "$VERBOSE" == 3 ]]; then
  for n in $(aws $PROFILE $REGION iot list-topic-rules --query 'rules[].ruleName' --output text | fmt -w 2 | sort) ; do
    aws $PROFILE $REGION iot get-topic-rule --rule-name "$n"
  done | jq -s '{ruleDetails:.}'
fi
