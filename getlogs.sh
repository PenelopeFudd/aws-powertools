#!/bin/bash

# Main code, placed here for ease of reading, but called after functions defined, at end:
function main() {
  check_executables
  parse_arguments "$@"
  check_profile
  if [[ "$GROUP"  == ""  ]]; then show_groups;       exit $?; fi
  if [[ "$FILTER" != ""  ]]; then filter_log_events; exit $?; fi
  if [[ "$STREAM" == ""  ]]; then show_streams;      exit $?; fi
  if [[ "$STREAM" != "*" ]]; then get_stream;        exit $?; fi
  get_all_streams
  exit $? 
}


function check_executables() {
  check_date
  AWSCMD=$(check_cmd aws)
  JQ=$(check_cmd jq)
}

function check_date() {
  if ! datecmd=$(which gdate 2>/dev/null) && ! datecmd=$(which date 2>/dev/null); then
    echo "Neither gdate nor date were found, aborting." >&2
    exit 1
  fi
  if ! $datecmd -d@1518047339 > /dev/null 2>&1; then
    echo "Error, $datecmd command doesn't understand GNU options." >&2
    echo " Please install GNU date as 'gdate' in your path." >&2
    exit 1
  fi
}

function check_cmd() {
  if CMD=$(which $1 2>/dev/null); then echo "$CMD"; return 0; fi
  echo "The '$1' command wasn't found, aborting." >&2
  exit 1
}

function parse_arguments() {
  # Defaults:
  REGION="us-west-2"
  PAGER=${PAGER:-more}

  # Parse arguments:
  while getopts ":b:de:f:F:g:lp:r:s:S:u:w" opt; do
    case $opt in
       b)          BEGIN="$OPTARG";;
       d)          DEBUG=1;;
       e)            END="$OPTARG";;
       f)         FILTER="\"$OPTARG\"";;
       F)         FILTER="$OPTARG";;
       g)          GROUP="$OPTARG";;
       l)           LIST=1;;
       p)        PROFILE="$OPTARG";;
       r)         REGION="$OPTARG";;
       s)         STREAM="$OPTARG";;
       S)          STAGE="$OPTARG";;
       u)            URL="$OPTARG";;
       w)            RAW=1;;
       :) echo "Option -$OPTARG requires an argument." >&2; exit 1;;
       \?) echo "Invalid option: -$OPTARG" >&2;;
    esac
  done
  shift $((OPTIND-1))

  if [[ "$URL" == "" && "$LIST" == "" && "$GROUP" == "" ]]; then
    echo "Usage: ${0##*/} [-d][-w] [-p profile] -l"
    echo "       ${0##*/} [-d][-w] [-p profile] -g log-group"
    echo "       ${0##*/} [-d][-w] [-p profile] -g log-group -s log-stream           [-b begin-time -e end-time] > output.txt"
    echo "       ${0##*/} [-d][-w] [-p profile] -g log-group -s '*'                  [-b begin-time -e end-time] > output.txt"
    echo "       ${0##*/} [-d][-w] [-p profile] -g log-group [-f|-F] 'search-string' [-b begin-time -e end-time] > output.txt"
    echo "       ${0##*/} [-d][-w] [-p profile] -u 'https://us-west-2.console.aws.amazon.com/cloudwatch....' [-b begin-time -e end-time] > output.txt"
    echo ""
    echo "  This will dump CloudWatch logs to standard output."
    echo ""
    echo "Options:"
    echo "  -d"
    echo "      Turn on debugging (show the aws commands used)"
    echo "  -w"
    echo "      Turn on raw output (show the json output from the aws commands)"
    echo "  -l"
    echo "      List all log groups"
    echo "  -r region"
    echo "      Look at logs in this region.  Defaults to 'us-west-2'."
    echo "  -p profile-name"
    echo "      Use this AWS CLI profile."
    echo "  -g log-group-name"
    echo "      Select this log group.  If not specified, list available log groups."
    echo "  -s log-stream-name"
    echo "      Dump the particular log stream.  If given as '*', dump all of them."
    echo "  -f string"
    echo "      Search for a string and return matching records."
    echo "  -F search-expression"
    echo "      Search using the given search expression."
    echo "      See https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/FilterAndPatternSyntax.html"
    echo "  -u url"
    echo "      Extract log group and log stream from cloudwatch console url."
    echo "  -b timestamp"
    echo "      Beginning time in any format recognized by the 'date' command."
    echo "  -e timestamp"
    echo "      Ending time in any format recognized by the 'date' command."
    echo ""
    echo "Examples:"
    echo ""
    echo "  # List the log groups for the default profile:"
    echo "  ${0##*/} -l"
    echo ""
    echo "  # List the log groups for the alpha profile:"
    echo "  ${0##*/} -p alpha -l"
    echo ""
    echo "  # List the log streams in a log group:"
    echo "  ${0##*/} -g SomethingNotification/service_log"
    echo ""
    echo "  # List the most recent 10,000 log events (not lines) or 1MB, whichever is less:"
    echo "  ${0##*/} -g SomethingNotification/service_log -s ip-10-0-49-97"
    echo ""
    echo "  # List the log events between two times in a single log stream:"
    echo "  ${0##*/} -g SomethingNotification/service_log -s ip-10-0-49-97 -b '5 minutes ago' -e 'now'"
    echo ""
    echo "  # List the log events between two times for all log streams in the log group:"
    echo "  ${0##*/} -g SomethingNotification/service_log -s '*' -b '5 minutes ago' -e 'now'"
    echo ""
    echo "  # Search for the string 'foobar' in all log streams of a log group since the dawn of time (verrry slowwww):"
    echo "  ${0##*/} -g SomethingNotification/service_log -f foobar"
    echo ""
    echo "  # Search for JSON-formatted records that have a certain value in a field since the dawn of time (also slowwwww):"
    echo "  ${0##*/} -p alpha.ReadOnly -g SomethingNotification/service_log -F '{ $.eventType = \"UpdateTrail\" }'"
    echo "  # See https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/FilterAndPatternSyntax.html"
    echo ""
    echo "Creating logs:"
    echo ""
    echo "  aws --profile=Admin logs create-log-group --log-group-name Test"
    echo ""
    echo "  aws --profile=Admin logs create-log-stream --log-group-name Test --log-stream-name TestStream"
    echo ""
    echo "  nt=\$(aws --profile=Admin logs put-log-events --log-group-name Test --log-stream-name TestStream \\"
    echo "         --log-events \"timestamp=\$(date +%s000),message='This is the first log message'\"  \\"
    echo "         | jq -r .nextSequenceToken )"
    echo ""
    echo "  nt=\$(aws --profile=Admin logs put-log-events --log-group-name Test --log-stream-name TestStream \\"
    echo "         --sequence-token=\$nt \\"
    echo "         --log-events \"timestamp=\$(date +%s000),message='This is the second log message'\" \\"
    echo "         | jq -r .nextSequenceToken )"
    echo ""
    echo "  getlogs.sh -l"
    echo ""
    echo "  Output:"
    echo "  | # Log groups for profile default:"
    echo "  | getlogs.sh -p 'default' -g 'Test'"
    echo ""
    echo "  getlogs.sh -p 'default' -g 'Test'"
    echo ""
    echo "  Output:"
    echo "  | # Log streams:"
    echo "  | getlogs.sh -p 'default' -g 'Test' -s 'TestStream'"
    echo ""
    echo "  getlogs.sh -p 'default' -g 'Test' -s 'TestStream'"
    echo ""
    echo "  Output:"
    echo "  | This is the first log message"
    echo "  | This is the second log message"
    echo ""

    exit 1
  fi

  # Validation:
  parse_times
  parse_url
}

function convert_time() {
  # No input was given:
  if [[ "$1" == "" ]]; then return 1; fi

  # Process it:
  local result=$("$datecmd" -d"$1" +%s 2>/dev/null)
  if [[ "$result" == "" ]]; then
    echo "${0##*/}: Time '$1' unrecognized by '$datecmd' command, aborting." >&2
    exit 1
  fi
  echo "$result"
}

function parse_times() {
  if BEGIN_TIME=$(convert_time "$BEGIN"); then
    BEGIN_AGAIN="-b @$BEGIN_TIME"
    BEGIN_ARG="--start-time ${BEGIN_TIME}000"
  fi

  if END_TIME=$(convert_time "$END"); then
    END_AGAIN="-e @$END_TIME"
    END_ARG="--end-time ${END_TIME}000"
  fi
}

function parse_url() {
  if [[ "$URL" != "" ]]; then
    # Extract account and role from url:

    # https://isengard.amazon.com/federate\
    #   ?account=123456789012\
    #   &role=ReadOnly\
    #   &destination=\
    #   cloudwatch%2Fhome%3Fregion%3Dus-west-2%23logEvent\
    #   %3Agroup%3DBONESBootstrap-BATSLogGroup-VUV6X2ZMDLF8\
    #   %3Bstream%3D434f2f4b-54d2-4d0a-9e31-965a3cea47bb

    if [[ "$URL" =~ ^https://isengard.amazon.com/federate ]]; then
      if ! urlparts=($(echo "$URL" | gawk 'match($0,"account=([0-9]*)&role=([a-zA-Z0-9._-]*)&destination=(.*)",a){ok=1;print a[1],a[2],a[3]};END{exit 1-ok}')); then
        echo "Could not find 'account=....&role=......' in url, aborting." >&2
        echo "URL given: $URL" >&2
        exit 1
      fi
      AWS="${urlparts[0]}"
      ROLE="${urlparts[1]}"
      URL=$(echo "${urlparts[2]}" | sed 's/%3A/:/g; s/%3D/=/g; s/%3B/;/g')
    fi
    if [[ "$AWS" == "" && "$PROFILE" == "" ]]; then
      echo "Error, could not find account or role in url and none specified on command line; aborting." >&2
      exit 1
    fi

    # Extract group+stream from url:

    #https://us-west-2.console.aws.amazon.com/cloudwatch/home\
      #  ?region=us-west-2#logEventViewer\
      #  :group=BONESBootstrap-BATSLogGroup-VUV6X2ZMDLF8\
      #  ;stream=434f2f4b-54d2-4d0a-9e31-965a3cea47bb
    if urlparts=($(echo "$URL" | gawk 'match($0,"group=([^;]*)",a){ok=1;group=a[1]};match($0,"stream=([a-f0-9-]*)",a){stream=a[1]};END{if(ok){print group,stream};exit 1-ok}')); then
      GROUP="${urlparts[0]}"
      STREAM="${urlparts[1]}"
    fi
  fi
}

# Consolidate all aws cli calls here:
function awslogs() {
  local cmd=(aws --region "$REGION" --profile=$PROFILE logs "$@")
  if [[ "$DEBUG" != "" ]]; then echo "  ${cmd[@]}" >&2; fi

  # Make the call and capture stdout, stderr and rc in variables:
  local t_err t_std t_ret
  eval "$( (
    "${cmd[@]}"
    ) 2> >(t_err=$(cat); typeset -p t_err) > >(t_std=$(cat); typeset -p t_std); t_ret=$?; typeset -p t_ret )"


  # No error:
  if [[ "$t_err" == "" ]]; then echo "$t_std"; return $t_ret; fi

  # Error found:
  if [[ "$t_err" =~ An\ error\ occurred\ .ExpiredTokenException ]]; then
    return $t_ret
  fi
  if [[ "$t_err" =~ Unable\ to\ locate\ credentials ]]; then
    return $t_ret
  fi
  if [[ "$t_err" =~ The\ security\ token\ included\ in\ the\ request\ is\ invalid. ]]; then
    return $t_ret
  fi

  # Unknown error:
  echo "$t_err" >&2
  return $t_ret
}

function check_profile() {
  if [[ "$PROFILE" == "" ]]; then PROFILE="default"; fi
}

function show_groups() {
  if [[ "$GROUPS_JSON" == "" ]]; then
    GROUPS_JSON=$(awslogs describe-log-groups)
  fi

  if [[ "$GROUPS_JSON" == "" ]]; then
    echo "# No groups found." >&2
    exit 0
  fi

  if [[ "$RAW" != "" ]]; then echo "$GROUPS_JSON"; return; fi

  out=$(echo "$GROUPS_JSON" \
      | jq -r \
        --arg cmd "${0##*/} -p '$PROFILE' $BEGIN_AGAIN $END_AGAIN" \
        '.logGroups[].logGroupName | "\($cmd) -g \(. | @sh)"' )
  if [[ "$out" == "" ]]; then
    echo "# No log groups were found."
    echo "# Create one with a command like this:"
    echo "#   aws --profile=Admin logs create-log-group --log-group-name Test"
    return 1
  fi
  echo "# Log groups for profile ${PROFILE}:"
  echo "$out"
}



function get_log_events () {
  local group="$1"
  local stream="$2"
  local begin_time="$3"
  local end_time="$4"

  local nextBackwardToken=""
  local lastToken=""

  local data_seen=""

  while true; do
    NBT=""
    if [[ "$nextBackwardToken" != "" ]]; then NBT="--next-token $nextBackwardToken"; fi

    a=$(awslogs get-log-events --log-group-name "$group" --log-stream-name "$stream" \
      $NBT \
      $begin_time $end_time )

    lastToken="$nextBackwardToken"
    nextBackwardToken=$(echo "$a" | jq -r '.nextBackwardToken' 2>/dev/null)
    if [[ "$lastToken" == "$nextBackwardToken" ]]; then break; fi

    if [[ "$RAW" != "" ]]; then echo "$a"; continue; fi

    out=$(echo "$a" | jq -r '.events[].message')
    if [[ "$?" != 0 ]]; then
      echo "jq failed, input:"
      echo "$a"
      exit 1
    fi

    if [[ "$out" != "" ]]; then echo "$out";data_seen=1; fi

  done

  if [[ "$data_seen" == "" ]]; then
    echo "# No log data found for profile $PROFILE, log group $group, log stream $stream in the given time range."
    echo "# Maybe try a bigger time range?"
    return 1
  fi
}

function filter_log_events() {
  local group="$GROUP"
  local stream="$STREAM"
  local begin_time="$BEGIN_ARG"
  local end_time="$END_ARG"
  local filter_pattern="$FILTER"

  local nextBackwardToken=""
  local lastToken=""

  GROUPS_JSON=$(awslogs describe-log-groups)
  count=$(echo "$GROUPS_JSON"  \
      | jq -r \
        --arg group "${group}" \
        '.logGroups[].logGroupName | select (. == $group)')
  if [[ "$count" == "" ]]; then
    echo "Error, '$group' does not exist." >&2
    echo "Valid groups:" >&2
    echo "" >&2
    echo "$GROUPS_JSON" \
        | jq -r '.logGroups[].logGroupName' | sort >&2
    exit 1
  fi


  # Log stream is optional:
  local lsname
  if [[ "$stream" != "" && "$stream" != "*" ]]; then lsname="--log-stream-names $stream"; fi

  local lastToken
  local data_seen
  while true; do

    # Pagination support:
    local NBT=""
    if [[ "$nextBackwardToken" == null ]]; then break; fi
    if [[ "$nextBackwardToken" != "" ]]; then NBT="--next-token $nextBackwardToken"; fi

    # Execute the command:
    a=$(awslogs filter-log-events --log-group-name "$group"  \
      $lsname \
      $NBT \
      $begin_time $end_time \
      --filter-pattern "$filter_pattern" \
      )

    if [[ "$a" == "" ]]; then exit 1; fi

    if [[ ! "$a" =~ ^\{.*\}$ ]]; then
      echo "$a" >&2
      exit 1
    fi

    lastToken="$nextBackwardToken"
    nextBackwardToken=$(echo "$a" | jq -r '.nextBackwardToken' 2>/dev/null)
    if [[ "$lastToken" == "$nextBackwardToken" ]]; then break; fi

    if [[ "$RAW" != "" ]]; then echo "$a"; continue; fi
    out=$(echo "$a" | jq -r '.events[].message' 2>/dev/null)

    if [[ "$out" != "" ]]; then echo "$out"; data_seen=1; fi

  done

  if [[ "$data_seen" == "" ]]; then
    echo "# No log data found for profile $PROFILE, log group $group, log stream $stream "
    echo "# in the given time range and with the given search filter '$filter_pattern'."
    echo "# Maybe try a bigger time range or a different search filter?"
    return 1
  fi

  return 0
}

function describe_log_streams () {
  local group="$1"

  if [[ "$RAW" != "" ]]; then
    awslogs describe-log-streams --log-group-name "$group"
  else
    awslogs describe-log-streams --log-group-name "$group" \
      | jq -r '.logStreams[].logStreamName' 2>/dev/null
  fi
}

function show_streams() {
  STREAMS_JSON=$(awslogs describe-log-streams --log-group-name "$GROUP")

  if [[ "$RAW" != "" ]]; then echo "$STREAMS_JSON"; return; fi

  CMD="${0##*/} -p '$PROFILE' -g '$GROUP' $BEGIN_AGAIN $END_AGAIN"

  out=$(echo "$STREAMS_JSON" \
      | jq -r --arg cmd "$CMD" \
         '.logStreams[].logStreamName | "\($cmd) -s \(. | @sh)" ')

  if [[ "$out" == "" ]]; then 
    echo "# No log streams were found in profile $PROFILE and log group $GROUP."
    echo "# Create one with a command like this:"
    echo "#   aws --profile=Admin logs create-log-stream --log-group-name Test --log-stream-name TestStream"
    return 1
  fi
  echo "# Log streams in profile $PROFILE and group ${GROUP}:"
  echo "$out"
}

# Normal 'display a stream':
function get_stream() {
  get_log_events "$GROUP" "$STREAM" "$BEGIN_ARG" "$END_ARG"
}

# Wildcard 'display all streams':
function get_all_streams() {
  for n in $(describe_log_streams "$GROUP"); do
    get_log_events "$GROUP" "$n" "$BEGIN_ARG" "$END_ARG"
  done
}

# Finally, start the program:
main "$@"
