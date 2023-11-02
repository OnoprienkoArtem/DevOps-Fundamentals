#!/bin/bash

if ! command -v jq &>/dev/null; then
  echo "jq is not installed. Please install jq before running this script."

  if [ "$(uname)" == "Darwin" ]; then
    echo "To install jq on macOS, you can use Homebrew:"
    echo "brew install jq"
  elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    echo "To install jq on most Linux distributions, you can use your package manager. For example, on Ubuntu, run:"
    echo "sudo apt-get install jq"
  elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ] || [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
    echo "To install jq on Windows, you can use tools like Chocolatey or scoop. For Chocolatey, run:"
    echo "choco install jq"
  else
    echo "Please install jq on your platform following the official documentation: https://jqlang.github.io/jq/"
  fi
  exit 1
fi

source_file="$1"
source_file_without_extension=$(basename "$source_file" | cut -d. -f1)
output_file="$source_file_without_extension-$(date +'%Y-%m-%d').json"

if ! jq -e '
  .pipeline.version and
  .pipeline.stages[0].actions[0].configuration.Branch and
  .pipeline.stages[0].actions[0].configuration.PollForSourceChanges and
  .pipeline.stages[0].actions[0].configuration.Owner
' "$source_file" &>/dev/null; then
  echo "Error: The JSON definition is missing required properties. Please ensure that 'version', 'Branch', 'PollForSourceChanges' and 'Owner' are defined."
  exit 1
fi

if [ -z "$1" ]; then
  echo "Usage: $0 <source_file> [--branch <branch>] [--owner <owner>] [--poll-for-source-changes <true|false>] [--configuration <config>]"
  exit 1
fi

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
