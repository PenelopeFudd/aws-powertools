#!/bin/bash

# Parse arguments:
while getopts ":r:p:" opt; do
  case $opt in
    r) REGION="--region $OPTARG";;
    p) PROFILE="--profile $OPTARG";;
    :) echo "Option -$OPTARG requires an argument." >&2; exit 1;;
    \?) echo "Invalid option: -$OPTARG" >&2;;
  esac
done
shift $((OPTIND-1))

if [[ "$1" == "" ]]; then
  echo "Usage: ${0##*/} [-p profile] [-r region] lambda-function [base-filename]"
  echo "  This script will create these files:"
  echo ""
  echo "     base-filename.create.sh: script to create the function"
  echo "     base-filename.env: environment for the function"
  echo "     base-filename.json: output from the get-function command"
  echo "     base-filename.policy.sh: script to create the function policy"
  echo "     base-filename.zip: the function's code"
  echo ""
  echo "  If base-filename isn't specified, it's the same as the lambda-function."
  exit 1
fi

base="$2"
if [[ "$base" == "" ]]; then base="$1"; fi

if ! a=$(aws $PROFILE $REGION lambda get-function --function-name "$1" 2>&1); then echo "Error: $a" >&2; exit 1; fi
echo "$a" > "$base.json"

url=$(echo "$a" | jq -r .Code.Location)
curl -sS "$url" > "$base.zip"

envstring=$(echo "$a" | jq -c .Configuration.Environment)
echo "$envstring" > "$base.env"

if ! policy=$(aws $PROFILE $REGION lambda get-policy --function-name "$1" 2>&1); then policy=""; fi

echo "$policy" \
  | jq -r ".Policy 
    | fromjson 
    | .Statement[] 
    | (.Resource | gsub(\".*:\"; \"\")) as \$func
    | \"# Lambda permissions for \(\$func):\naws $PROFILE $REGION lambda add-permission  \\\\
      --function-name \(\$func) \\\\
      --statement-id \(.Sid)  \\\\
      --action \(.Action) \\\\
      --principal \(.Principal.Service) \\\\
      --source-arn '\(.Condition.ArnLike.\"AWS:SourceArn\")'\n\"" \
  > "$base.policy.sh"

json=$(echo "$a" | jq -c --arg base "$base" '
    .Configuration as $c
    | $c
    | { "FunctionName": .FunctionName,     "Code": { "ZipFile": "fileb://\($base).zip" }}
    | if $c.Description       then . += {"Description":       $c.Description}      else . end
    | if $c.Environment       then . += {"Environment":       $c.Environment}      else . end
    | if $c.Handler           then . += {"Handler":           $c.Handler}          else . end
    | if $c.MemorySize        then . += {"MemorySize":        $c.MemorySize}       else . end
    | if $c.Role              then . += {"Role":              $c.Role}             else . end
    | if $c.Runtime           then . += {"Runtime":           $c.Runtime}          else . end
    | if $c.Timeout           then . += {"Timeout":           $c.Timeout}          else . end
    | if $c.TracingConfig     then . += {"TracingConfig":     $c.TracingConfig}    else . end
    | if $c.VpcConfig         then . += {"VpcConfig":         $c.VpcConfig} | del(.VpcConfig.VpcId) else . end

    |     "These are untested:" as $comment
    | if $c.Tags              then . += {"Tags":              $c.Tags}             else . end
    | if $c.Publish           then . += {"Publish":           $c.Publish}          else . end
    | if $c.Layers            then . += {"Layers":            $c.Layers}           else . end
    | if $c.KMSKeyArn         then . += {"KMSKeyArn":         $c.KMSKeyArn}        else . end
    | if $c.DeadLetterConfig  then . += {"DeadLetterConfig":  $c.DeadLetterConfig} else . end
')

echo "aws $PROFILE $REGION lambda create-function --cli-input-json '$json'" > "$base.create.sh"
chmod a+rx "$base.create.sh" "$base.zip" "$base.json" "$base.env" "$base.policy.sh"
ls -l "$base.create.sh" "$base.zip" "$base.json" "$base.env" "$base.policy.sh"
