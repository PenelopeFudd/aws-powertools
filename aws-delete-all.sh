#!/bin/bash

# Exit if errors happen:
set -e

# Parse arguments:
while getopts ":r:p:c:v" opt; do
  case $opt in
    c) CONFIRM="$OPTARG";;
    r) REGION="-r $OPTARG ";;
    p) PROFILE="-p $OPTARG ";;
    v) VERBOSE="-v $VERBOSE";;
    :) echo "Option -$OPTARG requires an argument." >&2; exit 1;;
    \?) echo "Invalid option: -$OPTARG" >&2;;
  esac
done
shift $((OPTIND-1))

NOW=$(date +"%F-%H:%M")
if [[ "$CONFIRM" != "$NOW" ]]; then
  echo "Usage: ${0##*/} [-p profile] [-r region] [-c confirmstring] [-v]"
  echo ""
  echo "__        ___    ____  _   _ ___ _   _  ____ _ "
  echo "\ \      / / \  |  _ \| \ | |_ _| \ | |/ ___| |"
  echo " \ \ /\ / / _ \ | |_) |  \| || ||  \| | |  _| |"
  echo "  \ V  V / ___ \|  _ <| |\  || || |\  | |_| |_|"
  echo "   \_/\_/_/   \_\_| \_\_| \_|___|_| \_|\____(_)"
  echo "                                               "
  echo ""
  echo "  This command will **DELETE** all[1] resources in the specified"
  echo "  region of the given AWS account."
  echo ""
  echo "  [1]: Here, 'all' means:"
  echo "    * Autoscaling groups"
  echo "    * Instances"
  echo "    * Launch configurations"
  echo "    * ELB load balancers"
  echo "    * ELBv2/ALB load balancers"
  echo "    * Elastic Network Interfaces"
  echo "    * Virtual Private Clusters (VPC)"
  echo "    * Subnets"
  echo "    * Security groups"
  echo "    * Gateways"
  echo "    * CloudFormation templates and everything they created"
  echo "    * ConfigService"
  echo "    * DynamoDB Tables"
  echo "    * EBS Volumes"
  echo "    * Elastic IPs"
  echo "    * ElastiCache"
  echo "    * Kinesis Streams"
  echo "    * Lambda Functions"
  echo "    * RDS Databases"
  echo "    * SQS Queues"
  echo ""
  echo "      It does not delete S3 objects or buckets.  To do that, run 'aws-list-s3.sh | xargs -n 1 aws-delete-s3-bucket.sh' separately."
  echo ""
  echo "Options:"
  echo "  -p profile: specify the profile for authentication and region selection (see $HOME/.aws/config)"
  echo "  -r region: specify the region, eg. us-west-2.  The default region comes from the profile."
  echo "  -v: run in verbose mode"
  echo "  -c confirmstring: confirm you actually want to delete everything."
  echo "      Run this to confirm:"
  echo "        ${0##*/} $PROFILE$REGION$VERBOSE-c $NOW"
  exit 1
fi

echo "       **** Deleting almost everything in profile $PROFILE and region $REGION"
echo ""

function doit() { parallel -j 20 --tag "$@";}

echo Deleting CloudFormation Stacks:
aws-list-cloudformation.sh    $PROFILE $REGION $VERBOSE | doit aws-delete-cloudformation.sh    $PROFILE $REGION $VERBOSE

echo Deleting ASGs:
aws-list-asgs.sh              $PROFILE $REGION $VERBOSE | doit aws-delete-asg.sh               $PROFILE $REGION $VERBOSE
echo Deleting Instances:
aws-list-instances.sh         $PROFILE $REGION $VERBOSE | doit aws-delete-instance.sh          $PROFILE $REGION $VERBOSE
echo Deleting LCs:
aws-list-lcs.sh               $PROFILE $REGION $VERBOSE | doit aws-delete-lcs.sh               $PROFILE $REGION $VERBOSE
echo Deleting LBs:
aws-list-lbs.sh               $PROFILE $REGION $VERBOSE | doit aws-delete-lb.sh                $PROFILE $REGION $VERBOSE
echo Deleting LBV2s:
aws-list-lbv2s.sh             $PROFILE $REGION $VERBOSE | doit aws-delete-lbv2.sh              $PROFILE $REGION $VERBOSE


echo Deleting CLOUDWATCH-ALARMSs:
aws-list-cloudwatch-alarms.sh $PROFILE $REGION $VERBOSE | doit aws-delete-cloudwatch-alarms.sh $PROFILE $REGION $VERBOSE
echo Deleting CONFIGSERVICEs:
aws-list-configservice.sh     $PROFILE $REGION $VERBOSE | doit aws-delete-configservice.sh     $PROFILE $REGION $VERBOSE
echo Deleting DYNAMODBs:
aws-list-dynamodb.sh          $PROFILE $REGION $VERBOSE | doit aws-delete-dynamodb.sh          $PROFILE $REGION $VERBOSE
echo Deleting EBS-VOLUMESs:
aws-list-ebs-volumes.sh       $PROFILE $REGION $VERBOSE | doit aws-delete-ebs-volumes.sh       $PROFILE $REGION $VERBOSE
echo Deleting ELASTICACHEs:
aws-list-elasticache.sh       $PROFILE $REGION $VERBOSE | doit aws-delete-elasticache.sh       $PROFILE $REGION $VERBOSE
echo Deleting KINESISs:
aws-list-kinesis.sh           $PROFILE $REGION $VERBOSE | doit aws-delete-kinesis.sh           $PROFILE $REGION $VERBOSE
echo Deleting LAMBDAs:
aws-list-lambda.sh            $PROFILE $REGION $VERBOSE | doit aws-delete-lambda.sh            $PROFILE $REGION $VERBOSE
echo Deleting RDSs:
aws-list-rds.sh               $PROFILE $REGION $VERBOSE | doit aws-delete-rds.sh               $PROFILE $REGION $VERBOSE
#echo Deleting S3s:
#aws-list-s3.sh                $PROFILE $REGION $VERBOSE | doit aws-delete-s3-bucket.sh         $PROFILE $REGION $VERBOSE
echo Deleting SQSs:
aws-list-sqs.sh               $PROFILE $REGION $VERBOSE | doit aws-delete-sqs.sh               $PROFILE $REGION $VERBOSE

echo Deleting GWs:
aws-list-gw.sh                $PROFILE $REGION $VERBOSE | doit aws-delete-gw.sh                $PROFILE $REGION $VERBOSE
echo Deleting EIPs:
aws-list-eip.sh               $PROFILE $REGION $VERBOSE | doit aws-delete-eip.sh               $PROFILE $REGION $VERBOSE
echo Deleting ENIs:
aws-list-eni.sh               $PROFILE $REGION $VERBOSE | doit aws-delete-eni.sh               $PROFILE $REGION $VERBOSE
echo Deleting Subnets:
aws-list-subnets.sh           $PROFILE $REGION $VERBOSE | doit aws-delete-subnet.sh            $PROFILE $REGION $VERBOSE
echo Deleting SGs:
aws-list-sg.sh                $PROFILE $REGION $VERBOSE | doit aws-delete-sg.sh                $PROFILE $REGION $VERBOSE

echo Deleting VPCs:
aws-list-vpcs.sh              $PROFILE $REGION $VERBOSE | doit aws-delete-vpc.sh               $PROFILE $REGION $VERBOSE
