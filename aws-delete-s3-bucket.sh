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

if [[ "$1" == "" ]]; then
  echo "Usage: ${0##*/} s3://name-of-bucket-to-delete"
  echo "  This will delete all of the bucket's objects in parallel, then delete the bucket."
  exit 0
fi

BUCKET="$1"
if [[ ! "$1" =~ ^s3:// ]]; then BUCKET="s3://$1"; fi

TEMPFILE=$(mktemp)
trap "rm -f ${TEMPFILE}" EXIT
aws $PROFILE $REGION s3 ls --recursive "$BUCKET" | cut -c32- > "$TEMPFILE"
if [[ -s "$TEMPFILE" ]]; then
  parallel -j 10 --eta "aws $PROFILE $REGION s3 rm $BUCKET/{}" :::: "$TEMPFILE" | grep -v ^delete:
fi
aws $PROFILE $REGION s3 rb "$BUCKET"
