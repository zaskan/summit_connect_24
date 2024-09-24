#!/bin/bash

# Default values
otel_host="localhost"
dryrun=false
title="Title_$(date +%s)"
id="ID_$(uuidgen)"
description="This is a dynamic description generated at $(date)."
action="Action_$(shuf -n 1 -e CREATE UPDATE DELETE)"
status="Status_$(shuf -n 1 -e SUCCESS FAILURE PENDING)"
case_number="N/A"

# Function to display help information
show_help() {
    echo "Usage: ./send_trace.sh [-a action] [-H otel_host] [case_number] [--dryrun]"
    echo
    echo "Options:"
    echo "  -a    Action to perform. Valid values are 'trigger' or 'solve'."
    echo "  -H    Hostname of the OpenTelemetry Collector. Default is 'localhost'."
    echo "  --dryrun   Print the JSON payload without sending it."
    echo "  --help, -h   Show this help message."
    echo "  case_number    Required if '-a solve' is used."
    echo
    echo "Examples:"
    echo "  ./send_trace.sh -a trigger"
    echo "  ./send_trace.sh -a solve CASE12345"
    echo "  ./send_trace.sh -H otel-host.com -a solve CASE12345"
    echo "  ./send_trace.sh --dryrun -a trigger"
}

# Check if no arguments were passed or --help/-h is used
if [[ $# -eq 0 || $1 == "--help" || $1 == "-h" ]]; then
    show_help
    exit 1
fi

# Parse the -a, -H, and --dryrun arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -a)
      shift
      if [[ $1 == "trigger" ]]; then
        title="Incident detected"
        description="The website is not responding."
        action="open_case"
        status="alarm"
      elif [[ $1 == "solve" ]]; then
        title="Incident Fixed"
        description="The website has been fixed."
        action="close_case"
        status="solved"
        # Capture the case number as the next argument
        shift
        case_number="$1"
        if [[ -z $case_number ]]; then
            echo "Error: Case number must be provided when using -a solve"
            exit 1
        fi
      else
        echo "Error: Unknown action '$1'. Use 'trigger' or 'solve'."
        show_help
        exit 1
      fi
      ;;
    -H)
      shift
      otel_host="$1"
      ;;
    --dryrun)
      dryrun=true
      ;;
    *)
      echo "Invalid option: $1"
      show_help
      exit 1
      ;;
  esac
  shift
done

# Correct the usage of date to avoid the warning
start_time=$(date +%s%N)
end_time=$((start_time + 1000000000))

# Create the JSON payload dynamically
json_payload=$(cat <<EOF
{
  "resourceSpans": [
    {
      "resource": {
        "attributes": [
          {
            "key": "service.name",
            "value": {
              "stringValue": "example-service"
            }
          }
        ]
      },
      "scopeSpans": [
        {
          "scope": {
            "name": "example-instrumentation"
          },
          "spans": [
            {
              "traceId": "$(uuidgen | tr -d '-')",
              "spanId": "$(printf '%016x' $(( RANDOM * RANDOM )))",
              "name": "example-span",
              "startTimeUnixNano": "$start_time",
              "endTimeUnixNano": "$end_time",
              "attributes": [
                {
                  "key": "title",
                  "value": {
                    "stringValue": "$title"
                  }
                },
                {
                  "key": "id",
                  "value": {
                    "stringValue": "$id"
                  }
                },
                {
                  "key": "description",
                  "value": {
                    "stringValue": "$description"
                  }
                },
                {
                  "key": "action",
                  "value": {
                    "stringValue": "$action"
                  }
                },
                {
                  "key": "status",
                  "value": {
                    "stringValue": "$status"
                  }
                },
                {
                  "key": "case_number",
                  "value": {
                    "stringValue": "$case_number"
                  }
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}
EOF
)

# Print the JSON payload to the console (for debugging purposes)
echo "$json_payload"

# Send the JSON payload to the OpenTelemetry Collector, unless in dryrun mode
if [ "$dryrun" = false ]; then
    curl -X POST http://${otel_host}:4318/v1/traces -H "Content-Type: application/json" -d "$json_payload"
    echo "Trace sent to ${otel_host} with title: $title, id: $id, description: $description, action: $action, status: $status, case_number: $case_number"
else
    echo "Dry run mode: Trace not sent."
fi

