#!/bin/bash

if ! command -v jq &>/dev/null; then
  echo "jq is not installed. Please install jq before running this script."
  exit 1
fi

if [ -z "$1" ]; then
  echo "Usage: $0 <source_file> [--branch <branch>] [--owner <owner>] [--poll-for-source-changes <true|false>] [--configuration <config>]"
  exit 1
fi

source_file="$1"
source_file_without_extension=$(basename "$source_file" | cut -d. -f1)
output_file="$source_file_without_extension-$(date +'%Y-%m-%d').json"

branch="main"
pollForSourceChanges="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
  --branch)
    branch="$2"
    shift
    ;;
  --owner)
    owner="$2"
    shift
    ;;
  --poll-for-source-changes)
    pollForSourceChanges="$2"
    shift
    ;;
  --configuration)
    configuration="$2"
    shift
    ;;
  esac
  shift
done

filter="
  del(.metadata) |
  .pipeline.version += 1 |
  .pipeline.stages[0].actions[0].configuration.Branch = \"$branch\" |
  .pipeline.stages[0].actions[0].configuration.PollForSourceChanges = \"$pollForSourceChanges\"
"

if [ -n "$configuration" ]; then
  build_config_json="{\"name\":\"BUILD_CONFIGURATION\",\"value\":\"$configuration\",\"type\":\"PLAINTEXT\"}"
  filter="$filter | .pipeline.stages[].actions[].configuration += {\"EnvironmentVariables\": [$build_config_json]}"
fi

if [ -n "$owner" ]; then
  filter="$filter | .pipeline.stages[0].actions[0].configuration.Owner = \"$owner\""
fi

jq "$filter" "$source_file" >tmp.$$.json && mv tmp.$$.json "$output_file"

echo "Modified JSON saved as $output_file"
