#!/bin/bash

# Parse arguments:
TEMP=$(getopt -o p:vj -l profile:,verbose,json -- "$@")
if [ $? != 0 ]; then 
  echo "Usage: $0 [-p profile] [-v] [-j] function"
  echo "  This will generate the aws cli commands to recreate permissions"
  echo "  on the given function."
  echo "  Options:"
  echo "    -v: Be verbose"
  echo "    -j: Dump json output"
  echo "    -p profile: Use a non-default aws profile from ~/.aws/config"
  exit 1
fi
eval set -- "$TEMP"
while [[ "$1" != "" ]] ; do
  case "$1" in
    -p|--profile) PROFILE="--profile $2"; shift ;;
    -v|--verbose) VERBOSE=1;;
    -j|--json) JSON=1;;
    --) shift; break;;
    *) FUNC="$1"; break;;
  esac
  shift
done

a=$(aws $PROFILE lambda get-policy --function-name "$FUNC" 2>&1)
if [[ "$a" =~ The\ config\ profile\ .*\ could\ not\ be\ found ]]; then echo "Error: $a" >&2 ; exit 1; fi
if [[ "$a" =~ An\ error\ occurred ]]; then echo "Error: $a" >&2; exit 1; fi

echo "$a"
exit 0
if [[ "$JSON" == 1 ]]; then echo "$a" | jq -S '.Functions | sort_by(.FunctionName | ascii_downcase)' ; exit 0; fi
#if [[ "$VERBOSE" == 1 ]]; then echo "$a" | jq .; exit 0; fi
echo "$a" | jq -r ".Functions[].FunctionName" | sort
FUNC="$1"
if [[ "$FUNC" == "" ]]; then
  echo "Usage: $0 lambda-function"
  echo "  This will generate the aws cli commands to recreate permissions"
  echo "  on the given function."
  exit 1
fi

a=$(aws lambda get-policy --function-name $FUNC 2>&1)
if [[ "$a" =~ An.error.occurred. ]]; then echo "Error: $a" | fmt; exit 1; fi

# The permissions are escaped json inside the Policy value:
b=$(echo "$a" | jq -r .Policy)

# How many statements?
count=$(echo "$b" | jq '.Statement | length')

# For each statement:
for n in $(seq 0 $(( $count - 1 )) ); do 
  # Get the nth statement:
  STATEMENT=$(echo "$b" | jq --argjson n $n '.Statement[$n]')

  # Extract the values:
  STATEMENT_ID=$(echo "$STATEMENT" | jq -r .Sid)
  ACTION=$(echo "$STATEMENT" | jq -r .Action)
  PRINCIPAL=$(echo "$STATEMENT" | jq -r .Principal.Service)
  SOURCE_ARN=$(echo "$STATEMENT" | jq -r '.["Condition"]["ArnLike"]["AWS:SourceArn"]' )

  echo aws lambda remove-permission --function-name "${FUNC}" --statement-id "${STATEMENT_ID}"
  echo aws lambda add-permission              \
            --function-name "${FUNC}"         \
            --statement-id  "${STATEMENT_ID}" \
            --action        "${ACTION}"       \
            --principal     "${PRINCIPAL}"    \
            --source-arn    "${SOURCE_ARN}"
  echo ""
done

exit 0
