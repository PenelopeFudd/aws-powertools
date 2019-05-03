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

PKGDIR=$(dirname "$0")
PROGRAMS=( $PKGDIR/aws-list-*.sh )

for n in "${PROGRAMS[@]}"; do

  # Don't run ourselves:
  if [[ "$n" == "$0" ]]; then continue; fi

  NAME=$(basename "$n" .sh | sed 's/^aws-list-//')

  # Skip events, rules, activities:
  if [[ "$NAME" =~ events ]]; then continue; fi
  if [[ "$NAME" == sg-rules ]]; then continue; fi
  if [[ "$NAME" == scaling-activities ]]; then continue; fi

  echo "#=== ${NAME}:"
  OUTPUT=$($n $PROFILE $REGION $VERBOSE)
  if [[ "$OUTPUT" == "" ]]; then
    echo "#  none";
  else
    echo "$OUTPUT" | sed 's/^/   /';
  fi
done
