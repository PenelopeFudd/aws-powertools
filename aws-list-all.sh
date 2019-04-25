#!/bin/bash

# Parse arguments:
while getopts ":r:p:v" opt; do
  case $opt in
    r) REGION="-r $OPTARG";;
    p) PROF="$OPTARG";;
    v) VERBOSE=$(( VERBOSE + 1 ));;
    :) echo "Option -$OPTARG requires an argument." >&2; exit 1;;
    \?) echo "Invalid option: -$OPTARG" >&2;;
  esac
done
shift $((OPTIND-1))

if [[ "$PROF" == "" ]]; then PROF=default; fi
AWSPROFILE="--profile $PROF"
PROFILE="-p $PROF"
if ! aws $AWSPROFILE sts get-caller-identity > /dev/null 2>&1; then
  echo "Error: Is the profile '$PROF' currently valid?" >&2
  exit 1
fi

echo '#=== ASGS:'
aws-list-asgs.sh $PROFILE $REGION $VERBOSE
echo '#=== AUTOSCALING-INSTANCES:'
aws-list-autoscaling-instances.sh $PROFILE $REGION $VERBOSE
echo '#=== CLOUDWATCH-ALARMS:'
aws-list-cloudwatch-alarms.sh $PROFILE $REGION $VERBOSE
echo '#=== CONFIGSERVICE:'
aws-list-configservice.sh $PROFILE $REGION $VERBOSE
echo '#=== DYNAMODB:'
aws-list-dynamodb.sh $PROFILE $REGION $VERBOSE
echo '#=== EBS-VOLUMES:'
aws-list-ebs-volumes.sh $PROFILE $REGION $VERBOSE
echo '#=== EIPs:'
aws-list-eip.sh $PROFILE $REGION $VERBOSE
echo '#=== ELASTICACHE:'
aws-list-elasticache.sh $PROFILE $REGION $VERBOSE
echo '#=== ENI:'
aws-list-eni.sh $PROFILE $REGION $VERBOSE
echo '#=== GW:'
aws-list-gw.sh $PROFILE $REGION $VERBOSE
echo '#=== INSTANCES:'
aws-list-instances.sh $PROFILE $REGION $VERBOSE
echo '#=== KINESIS:'
aws-list-kinesis.sh $PROFILE $REGION $VERBOSE
echo '#=== LAMBDA:'
aws-list-lambda.sh $PROFILE $REGION $VERBOSE
echo '#=== LBS:'
aws-list-lbs.sh $PROFILE $REGION $VERBOSE
echo '#=== LBV2S:'
aws-list-lbv2s.sh $PROFILE $REGION $VERBOSE
echo '#=== LCS:'
aws-list-lcs.sh $PROFILE $REGION $VERBOSE
echo '#=== RDS:'
aws-list-rds.sh $PROFILE $REGION $VERBOSE
echo '#=== S3:'
aws-list-s3.sh $PROFILE $REGION $VERBOSE
echo '#=== SG:'
aws-list-sg.sh $PROFILE $REGION $VERBOSE
echo '#=== SQS:'
aws-list-sqs.sh $PROFILE $REGION $VERBOSE
echo '#=== SUBNETS:'
aws-list-subnets.sh $PROFILE $REGION $VERBOSE
echo '#=== VPCS:'
aws-list-vpcs.sh $PROFILE $REGION $VERBOSE
echo '#=== CLOUDFORMATION STACKS:'
aws-list-cloudformation.sh $PROFILE $REGION $VERBOSE
