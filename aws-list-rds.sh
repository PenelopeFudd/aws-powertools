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


if [[ "$VERBOSE" == 0 ]]; then
  aws $PROFILE $REGION rds describe-db-instances | jq -r '.DBInstances[] | select ( .DBInstanceStatus != "deleting" ) | .DBInstanceIdentifier'
  exit 0
fi
if [[ "$VERBOSE" == 1 ]]; then
  aws $PROFILE $REGION rds describe-db-instances 
  exit 0
fi
# {
#     "DBInstances": [
#         {
#             "PubliclyAccessible": true, 
#             "MasterUsername": "dbadmin", 
#             "MonitoringInterval": 60, 
#             "LicenseModel": "postgresql-license", 
#             "VpcSecurityGroups": [
#                 {
#                     "Status": "active", 
#                     "VpcSecurityGroupId": "sg-78d01d03"
#                 }
#             ], 
#             "InstanceCreateTime": "2017-04-06T21:47:24.143Z", 
#             "CopyTagsToSnapshot": true, 
#             "OptionGroupMemberships": [
#                 {
#                     "Status": "in-sync", 
#                     "OptionGroupName": "default:postgres-9-5"
#                 }
#             ], 
#             "PendingModifiedValues": {}, 
#             "Engine": "postgres", 
#             "MultiAZ": true, 
#             "LatestRestorableTime": "2018-01-19T19:42:58Z", 
#             "DBSecurityGroups": [], 
#             "DBParameterGroups": [
#                 {
#                     "DBParameterGroupName": "default.postgres9.5", 
#                     "ParameterApplyStatus": "in-sync"
#                 }
#             ], 
#             "PerformanceInsightsEnabled": false, 
#             "AutoMinorVersionUpgrade": true, 
#             "PreferredBackupWindow": "12:16-12:46", 
#             "DBSubnetGroup": {
#                 "Subnets": [
#                     {
#                         "SubnetStatus": "Active", 
#                         "SubnetIdentifier": "subnet-0ecda069", 
#                         "SubnetAvailabilityZone": {
#                             "Name": "us-west-2b"
#                         }
#                     }, 
#                     {
#                         "SubnetStatus": "Active", 
#                         "SubnetIdentifier": "subnet-0474f34d", 
#                         "SubnetAvailabilityZone": {
#                             "Name": "us-west-2a"
#                         }
#                     }, 
#                     {
#                         "SubnetStatus": "Active", 
#                         "SubnetIdentifier": "subnet-73716f2b", 
#                         "SubnetAvailabilityZone": {
#                             "Name": "us-west-2c"
#                         }
#                     }
#                 ], 
#                 "DBSubnetGroupName": "default", 
#                 "VpcId": "vpc-eb56008c", 
#                 "DBSubnetGroupDescription": "default", 
#                 "SubnetGroupStatus": "Complete"
#             }, 
#             "SecondaryAvailabilityZone": "us-west-2a", 
#             "ReadReplicaDBInstanceIdentifiers": [], 
#             "AllocatedStorage": 100, 
#             "DBInstanceArn": "arn:aws:rds:us-west-2:811512070518:db:something-jira-prod", 
#             "BackupRetentionPeriod": 7, 
#             "DBName": "somethingjira1", 
#             "PreferredMaintenanceWindow": "thu:10:42-thu:11:12", 
#             "Endpoint": {
#                 "HostedZoneId": "Z1PVIF0B656C1W", 
#                 "Port": 5432, 
#                 "Address": "something-jira-prod.cyrgehrbr8o0.us-west-2.rds.amazonaws.com"
#             }, 
#             "DBInstanceStatus": "available", 
#             "IAMDatabaseAuthenticationEnabled": false, 
#             "EngineVersion": "9.5.4", 
#             "EnhancedMonitoringResourceArn": "arn:aws:logs:us-west-2:811512070518:log-group:RDSOSMetrics:log-stream:db-EGD4JTLTO4TSEEFMC7SA2K57RY", 
#             "AvailabilityZone": "us-west-2c", 
#             "DomainMemberships": [], 
#             "MonitoringRoleArn": "arn:aws:iam::811512070518:role/rds-monitoring-role", 
#             "StorageType": "io1", 
#             "DbiResourceId": "db-EGD4JTLTO4TSEEFMC7SA2K57RY", 
#             "CACertificateIdentifier": "rds-ca-2015", 
#             "Iops": 1000, 
#             "StorageEncrypted": false, 
#             "DBInstanceClass": "db.m3.xlarge", 
#             "DbInstancePort": 0, 
#             "DBInstanceIdentifier": "something-jira-prod"
#         }
#     ]
# }
