#!/bin/bash

# Parse arguments:
VERBOSE=0
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


if [[ "$VERBOSE" == 0 ]]; then aws $PROFILE $REGION cloudwatch describe-alarms | jq -r '.MetricAlarms[].AlarmName'; exit 0; fi

if [[ "$VERBOSE" == 1 ]]; then aws $PROFILE $REGION cloudwatch describe-alarms | jq .; exit 0; fi
# {
#   "MetricAlarms": [
#     {
#       "EvaluationPeriods": 1,
#       "TreatMissingData": "missing",
#       "AlarmArn": "arn:aws:cloudwatch:us-west-2:978708203214:alarm:QueryServerIsNotRunning",
#       "StateUpdatedTimestamp": "2017-12-06T02:07:50.482Z",
#       "AlarmConfigurationUpdatedTimestamp": "2017-05-15T23:55:54.428Z",
#       "ComparisonOperator": "LessThanThreshold",
#       "AlarmActions": [],
#       "Namespace": "QueryServerStatus",
#       "AlarmDescription": "Check if the query server is on",
#       "StateReasonData": "{\"version\":\"1.0\",\"queryDate\":\"2017-12-06T02:07:50.473+0000\",\"statistic\":\"Average\",\"period\":60,\"recentDatapoints\":[],\"threshold\":1.0}",
#       "Period": 60,
#       "StateValue": "INSUFFICIENT_DATA",
#       "Threshold": 1,
#       "AlarmName": "QueryServerIsNotRunning",
#       "Dimensions": [],
#       "Statistic": "Average",
#       "StateReason": "Insufficient Data: 1 datapoint was unknown.",
#       "InsufficientDataActions": [],
#       "OKActions": [],
#       "ActionsEnabled": true,
#       "MetricName": "IsQueryServerUp"
#     },
#     {
#       "EvaluationPeriods": 1,
#       "TreatMissingData": "breaching",
#       "AlarmArn": "arn:aws:cloudwatch:us-west-2:978708203214:alarm:QueryServerScript>1",
#       "StateUpdatedTimestamp": "2017-12-06T02:07:44.353Z",
#       "AlarmConfigurationUpdatedTimestamp": "2017-05-24T18:05:35.059Z",
#       "ComparisonOperator": "GreaterThanThreshold",
#       "AlarmActions": [],
#       "Namespace": "QueryServerStatus",
#       "AlarmDescription": "QueryServerScript>1",
#       "StateReasonData": "{\"version\":\"1.0\",\"queryDate\":\"2017-12-06T02:07:44.354+0000\",\"statistic\":\"Average\",\"period\":60,\"recentDatapoints\":[],\"threshold\":1.0}",
#       "Period": 60,
#       "StateValue": "ALARM",
#       "Threshold": 1,
#       "AlarmName": "QueryServerScript>1",
#       "Dimensions": [],
#       "Statistic": "Average",
#       "StateReason": "Threshold Crossed: no datapoints were received for 1 period and 1 missing datapoint was treated as [Breaching].",
#       "InsufficientDataActions": [],
#       "OKActions": [],
#       "ActionsEnabled": true,
#       "MetricName": "IsQueryServerScriptUp"
#     },
#     {
#       "EvaluationPeriods": 1,
#       "TreatMissingData": "missing",
#       "AlarmArn": "arn:aws:cloudwatch:us-west-2:978708203214:alarm:QueryServerScriptNotRunning",
#       "StateUpdatedTimestamp": "2017-12-06T02:07:47.426Z",
#       "AlarmConfigurationUpdatedTimestamp": "2017-05-15T23:43:16.539Z",
#       "ComparisonOperator": "LessThanThreshold",
#       "AlarmActions": [],
#       "Namespace": "QueryServerStatus",
#       "AlarmDescription": "check if query server script is working",
#       "StateReasonData": "{\"version\":\"1.0\",\"queryDate\":\"2017-12-06T02:07:47.419+0000\",\"statistic\":\"Average\",\"period\":60,\"recentDatapoints\":[],\"threshold\":1.0}",
#       "Period": 60,
#       "StateValue": "INSUFFICIENT_DATA",
#       "Threshold": 1,
#       "AlarmName": "QueryServerScriptNotRunning",
#       "Dimensions": [],
#       "Statistic": "Average",
#       "StateReason": "Insufficient Data: 1 datapoint was unknown.",
#       "InsufficientDataActions": [],
#       "OKActions": [],
#       "ActionsEnabled": true,
#       "MetricName": "IsQueryServerScriptUp"
#     },
#     {
#       "EvaluationPeriods": 5,
#       "AlarmArn": "arn:aws:cloudwatch:us-west-2:978708203214:alarm:Something-ReadCapacityUnitsLimit-BasicAlarm",
#       "StateUpdatedTimestamp": "2017-12-15T00:24:42.684Z",
#       "AlarmConfigurationUpdatedTimestamp": "2017-05-05T19:35:13.123Z",
#       "ComparisonOperator": "GreaterThanOrEqualToThreshold",
#       "AlarmActions": [
#         "arn:aws:sns:us-west-2:978708203214:dynamodb"
#       ],
#       "Namespace": "AWS/DynamoDB",
#       "StateReasonData": "{\"version\":\"1.0\",\"queryDate\":\"2017-12-15T00:24:42.679+0000\",\"statistic\":\"Sum\",\"period\":60,\"recentDatapoints\":[],\"threshold\":4800.0}",
#       "Period": 60,
#       "StateValue": "INSUFFICIENT_DATA",
#       "Threshold": 4800,
#       "AlarmName": "Something-ReadCapacityUnitsLimit-BasicAlarm",
#       "Dimensions": [
#         {
#           "Name": "TableName",
#           "Value": "Something"
#         }
#       ],
#       "Statistic": "Sum",
#       "StateReason": "Insufficient Data: 5 datapoints were unknown.",
#       "InsufficientDataActions": [],
#       "OKActions": [],
#       "ActionsEnabled": true,
#       "MetricName": "ConsumedReadCapacityUnits"
#     },
#     {
#       "EvaluationPeriods": 5,
#       "AlarmArn": "arn:aws:cloudwatch:us-west-2:978708203214:alarm:Something-WriteCapacityUnitsLimit-BasicAlarm",
#       "StateUpdatedTimestamp": "2017-05-19T05:45:26.952Z",
#       "AlarmConfigurationUpdatedTimestamp": "2017-05-05T19:35:13.282Z",
#       "ComparisonOperator": "GreaterThanOrEqualToThreshold",
#       "AlarmActions": [
#         "arn:aws:sns:us-west-2:978708203214:dynamodb"
#       ],
#       "Namespace": "AWS/DynamoDB",
#       "StateReasonData": "{\"version\":\"1.0\",\"queryDate\":\"2017-05-19T05:45:26.953+0000\",\"startDate\":\"2017-05-19T05:41:00.000+0000\",\"statistic\":\"Sum\",\"period\":60,\"recentDatapoints\":[2.0],\"threshold\":4800.0}",
#       "Period": 60,
#       "StateValue": "OK",
#       "Threshold": 4800,
#       "AlarmName": "Something-WriteCapacityUnitsLimit-BasicAlarm",
#       "Dimensions": [
#         {
#           "Name": "TableName",
#           "Value": "Something"
#         }
#       ],
#       "Statistic": "Sum",
#       "StateReason": "Threshold Crossed: 1 datapoint (2.0) was not greater than or equal to the threshold (4800.0).",
#       "InsufficientDataActions": [],
#       "OKActions": [],
#       "ActionsEnabled": true,
#       "MetricName": "ConsumedWriteCapacityUnits"
#     }
#   ]
# }
