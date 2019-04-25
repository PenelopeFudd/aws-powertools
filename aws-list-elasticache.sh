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


if [[ "$VERBOSE" == 0 ]]; then aws $PROFILE $REGION elasticache describe-replication-groups | jq -r '.ReplicationGroups[] | select(.Status != "deleting") | .ReplicationGroupId'; exit 0; fi
if [[ "$VERBOSE" == 1 ]]; then aws $PROFILE $REGION elasticache describe-replication-groups | jq .; exit 0; fi
# {
#   "ReplicationGroups": [
#     {
#       "Status": "available",
#       "Description": "Something Demo001 Redis server -- https://w.amazon.com/index.php/AWS/Something/Operations",
#       "NodeGroups": [
#         {
#           "Status": "available",
#           "NodeGroupMembers": [
#             {
#               "CurrentRole": "primary",
#               "PreferredAvailabilityZone": "us-west-2a",
#               "CacheNodeId": "0001",
#               "ReadEndpoint": {
#                 "Port": 6379,
#                 "Address": "something-001.jvxwxy.0001.usw2.cache.amazonaws.com"
#               },
#               "CacheClusterId": "something-001"
#             },
#             {
#               "CurrentRole": "replica",
#               "PreferredAvailabilityZone": "us-west-2b",
#               "CacheNodeId": "0001",
#               "ReadEndpoint": {
#                 "Port": 6379,
#                 "Address": "something-002.jvxwxy.0001.usw2.cache.amazonaws.com"
#               },
#               "CacheClusterId": "something-002"
#             },
#             {
#               "CurrentRole": "replica",
#               "PreferredAvailabilityZone": "us-west-2c",
#               "CacheNodeId": "0001",
#               "ReadEndpoint": {
#                 "Port": 6379,
#                 "Address": "something-003.jvxwxy.0001.usw2.cache.amazonaws.com"
#               },
#               "CacheClusterId": "something-003"
#             }
#           ],
#           "NodeGroupId": "0001",
#           "PrimaryEndpoint": {
#             "Port": 6379,
#             "Address": "something.jvxwxy.ng.0001.usw2.cache.amazonaws.com"
#           }
#         }
#       ],
#       "ClusterEnabled": false,
#       "ReplicationGroupId": "something",
#       "SnapshotRetentionLimit": 1,
#       "AutomaticFailover": "disabled",
#       "SnapshotWindow": "12:00-13:00",
#       "SnapshottingClusterId": "something-002",
#       "MemberClusters": [
#         "something-001",
#         "something-002",
#         "something-003"
#       ],
#       "CacheNodeType": "cache.r3.large",
#       "PendingModifiedValues": {}
#     },
#     {
#       "Status": "available",
#       "Description": "A redis server running with Events v0.3 to bridge between the old redis message bus and the new APIs",
#       "NodeGroups": [
#         {
#           "Status": "available",
#           "NodeGroupMembers": [
#             {
#               "CurrentRole": "primary",
#               "PreferredAvailabilityZone": "us-west-2c",
#               "CacheNodeId": "0001",
#               "ReadEndpoint": {
#                 "Port": 6379,
#                 "Address": "eventsv3redis-001.jvxwxy.0001.usw2.cache.amazonaws.com"
#               },
#               "CacheClusterId": "eventsv3redis-001"
#             },
#             {
#               "CurrentRole": "replica",
#               "PreferredAvailabilityZone": "us-west-2a",
#               "CacheNodeId": "0001",
#               "ReadEndpoint": {
#                 "Port": 6379,
#                 "Address": "eventsv3redis-002.jvxwxy.0001.usw2.cache.amazonaws.com"
#               },
#               "CacheClusterId": "eventsv3redis-002"
#             },
#             {
#               "CurrentRole": "replica",
#               "PreferredAvailabilityZone": "us-west-2b",
#               "CacheNodeId": "0001",
#               "ReadEndpoint": {
#                 "Port": 6379,
#                 "Address": "eventsv3redis-003.jvxwxy.0001.usw2.cache.amazonaws.com"
#               },
#               "CacheClusterId": "eventsv3redis-003"
#             }
#           ],
#           "NodeGroupId": "0001",
#           "PrimaryEndpoint": {
#             "Port": 6379,
#             "Address": "eventsv3redis.jvxwxy.ng.0001.usw2.cache.amazonaws.com"
#           }
#         }
#       ],
#       "ClusterEnabled": false,
#       "ReplicationGroupId": "eventsv3redis",
#       "SnapshotRetentionLimit": 1,
#       "AutomaticFailover": "disabled",
#       "SnapshotWindow": "11:30-12:30",
#       "SnapshottingClusterId": "eventsv3redis-002",
#       "MemberClusters": [
#         "eventsv3redis-001",
#         "eventsv3redis-002",
#         "eventsv3redis-003"
#       ],
#       "CacheNodeType": "cache.r3.large",
#       "PendingModifiedValues": {}
#     }
#   ]
# }
