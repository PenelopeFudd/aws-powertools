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

aws $PROFILE $REGION elasticache describe-events  \
    | cat

#  | jq -r '.Events[] | [ (.Date |.[0:19]), .SourceIdentifier, .SourceType, .Message ] | @tsv' | sort

  #| jq -r '.Events[] | [ (.Date.[0::19] | strptime("%Y-%m-%dT%H:%M:%S")|mktime|todate), .SourceIdentifier, .SourceType, .Message ] | @tsv' | sort
# {
#     "Events": [
#         {
#             "Date": "2017-04-05T18:29:46.754Z",
#             "Message": "Replication group something-juancho created",
#             "SourceIdentifier": "something-juancho",
#             "SourceType": "replication-group"
#         },
# 

