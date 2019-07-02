#!/bin/bash

function main() {
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
    echo "Usage: ${0##*/} [-p profile] [-r region] CloudfrontEndpoint"
    echo "  This script traces all resources related to a given endpoint."
    echo "Example:"
    echo "  ${0##*/} -p prod.admin dafut1tgd1vs6.cloudfront.net"
    exit 1
  fi

  if ! distribution=$(find_distribution_by_endpoint "$1"); then exit 1; fi
  echo "# See the cloudfront distribution here:"
  echo "#    https://console.aws.amazon.com/cloudfront/home?#distribution-settings:$distribution"
  echo "aws $PROFILE $REGION cloudfront get-distribution --id $distribution"
  echo ""

  if ! s3bucket=$(find_s3_by_endpoint "$1"); then exit 1; fi
  echo "# See the s3 bucket here:"
  echo "#    https://s3.console.aws.amazon.com/s3/buckets/$s3bucket/?region=us-west-2&tab=overview"
  echo "aws $PROFILE $REGION s3 ls s3://$s3bucket"
  echo ""

  if ! apigw=$(find_apigw_by_endpoint "$1"); then exit 1; fi
  echo "# See the api gateway here:"
  echo "#    https://us-west-2.console.aws.amazon.com/apigateway/home?region=us-west-2#/apis/$apigw/dashboard"
  echo "aws $PROFILE $REGION apigateway get-rest-api --rest-api-id $apigw"
  echo "aws $PROFILE $REGION apigateway get-resources --rest-api-id $apigw"
  echo ""

  if ! auth=$(find_authorizers_by_apigw "$apigw"); then exit 1; fi
  echo "# See the cognito user pool here:"
  echo "#    https://us-west-2.console.aws.amazon.com/cognito/users?region=us-west-2#/pool/$auth/details"
  # ?_k=hhfqe5"
  echo "aws $PROFILE $REGION cognito-idp describe-user-pool --user-pool-id $auth"
  echo "aws $PROFILE $REGION cognito-idp list-users --user-pool-id $auth"
  echo ""

}

function myaws() { aws $PROFILE $REGION "$@"; }

function find_distribution_by_endpoint () {
   if ! a=$(myaws cloudfront list-distributions ); then echo "Error: $a" >&2; return 1; fi
   b=$(echo "$a" | jq --arg ep "$1" -r '.DistributionList.Items[] | select( .DomainName == $ep) | .Id')
   if [[ "$b" != "" ]]; then echo "$b"; return ; fi
   echo "Error: $b"
   return 1
}

function find_s3_by_endpoint () {
   if ! a=$(myaws cloudfront list-distributions ); then echo "Error: $a" >&2; return 1; fi
   b=$(echo "$a" | jq --arg ep "$1" -r '
     .DistributionList.Items[] 
     | select( .DomainName == $ep) 
     | .Origins.Items[].DomainName')
   if [[ "$b" == "" ]]; then echo "Error: Could not find Origins.Items[].DomainName for endpoint $1" >&2; return 1; fi
   echo "${b%%.*}"
}

function find_apigw_by_endpoint () {
   url="https://$1"
   if ! html=$(curl -sS "$url"); then echo "Error: Couldn't retrieve starting page $url" >&2; return 1; fi

   if ! relurl2=$(echo "$html" | grep -o '/static/js/main[^"]*'); then echo "Error: Can't find /static/js/main at $url" >&2; return 1; fi

   url2="$url$relurl2"
   if ! html2=$(curl -sS "$url2"); then echo "Error: Can't load page $url2" >&2; return 1; fi

   if ! apigw=$(echo "$html2" | grep -o '[a-z0-9.-]*execute-api.us-west-2.amazonaws.com' | head -n 1); then
     echo "Error: Can't find execute-api.us-west-2.amazonaws.com in $url2" >&2
     return 1
   fi
   echo "${apigw%%.*}"
}

function find_authorizers_by_apigw () {
   if ! a=$(myaws apigateway get-authorizers --rest-api-id $1 ); then echo "Error: $a" >&2; return 1; fi
   b=$(echo "$a" | jq -r '.items[0].providerARNs[0]')
   if [[ "$b" == "" ]]; then echo "Error: Could not find cognito_user_pool for apigw $1" >&2; return 1; fi
   echo "${b##*/}"
}


function find_latestdeployment_by_apigw () {
   if ! a=$(myaws apigateway get-deployments --rest-api-id $1 ); then echo "Error: $a" >&2; return 1; fi
   b=$(echo "$a" | jq -r '.items | sort_by(.createdDate)[-1].id')
   if [[ "$b" == "" ]]; then echo "Error: Could not find last deployment for apigw $1" >&2; return 1; fi
   echo "${b##*/}"
}

main "$@"
