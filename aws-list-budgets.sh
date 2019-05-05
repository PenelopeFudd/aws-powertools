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

if ! account=$(aws sts get-caller-identity --output text | gawk '{print $1}'); then
  echo "# Unable to determine account number" >&2
  exit 1
fi

if ! budgets=$(aws $PROFILE $REGION budgets describe-budgets --account-id "$account"); then
  echo "# Unable to get budget information." >&2
  exit 1
fi

if [[ "$VERBOSE" == 0 ]]; then
  echo "$budgets" | jq -r '.Budgets[] | .BudgetName'
  exit 0
fi

if [[ "$VERBOSE" == 1 ]]; then
  (echo $'# Start,End,Name,Limit,Spent'
  echo "$budgets" | jq -r '
  .Budgets[]
  | (.TimePeriod.Start | tonumber | todate) as $tp_start
  | (.TimePeriod.End   | tonumber | todate) as $tp_end
  | ( if ( $tp_end > "2080" ) then "now" else $tp_end end ) as $realend

  | (.BudgetLimit.Amount // 0 | tonumber | . * 100 | floor / 100) as $limit
  | (.CalculatedSpend.ActualSpend.Amount  // 0 | tonumber | . * 100 | floor / 100) as $spent

  | [$tp_start,$realend,.BudgetName,$limit,$spent]
  | @csv') | column -t -s,
  exit 0
fi

if [[ "$VERBOSE" == 2 ]]; then
  echo "$budgets" | jq -r \
    --arg acct "$account" \
    '
  .Budgets[]
  | (.BudgetName | gsub("[ .]";"_") ) as $name

  | (.BudgetLimit.Amount // 0 | tonumber | . * 100 | floor / 100) as $limit
  | (.CalculatedSpend.ActualSpend.Amount // 0 | tonumber | . * 100 | floor / 100) as $spend
  | ($spend/$limit * 10000 | floor | . / 100) as $budgetpercentused

  | (now | floor) as $now
  | (now | gmtime |             .[2]=1 | .[3,4,5] = 0 | mktime) as $monthstart
  | (now | gmtime | .[1] += 1 | .[2]=1 | .[3,4,5] = 0 | mktime) as $monthend
  | ($monthend - $monthstart) as $monthlength
  | (now - $monthstart) as $monthused
  | ($monthused/$monthlength * 10000 | floor | . / 100) as $monthpercentused
  | [
     "aws.\($acct).budget.\($name).limit \($limit) \($now)\n",
     "aws.\($acct).budget.\($name).spend \($spend) \($now)\n",
     "aws.\($acct).budget.\($name).budgetpercentused \($budgetpercentused) \($now)\n",
     "aws.\($acct).budget.\($name).monthpercentused \($monthpercentused) \($now)"
     ]
     | join("")'
  exit 0
fi

echo "$budgets"
