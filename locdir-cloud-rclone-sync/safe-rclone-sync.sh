#!/bin/bash

# if --log-file option is provided then the script logs is written there, otherwise in the stdout.

script_name=$(basename "$0")
rclone_path="/usr/bin/rclone"
sync_command="$rclone_path sync"

args=$@
args_count=$#

source_path=$1
destination_path=$2

log_file=

tolerance_percent=20

usage() {
cat <<EOF

Description:
  The script aborts rclone sync if destination directory loses
  more than $tolerance_percent% of files during the sync.

Usage:
  $script_name source:path destination:path [flags]

Arguments:
  source:path             Path to source directory (remote or local).
  destination:path        Path to destination directory (remote or local).
  flags                   rclone flags, see 'man rclone'.
EOF
}

log() {
  if [[ -n "$log_file" ]]; then
    echo "$1" >> $log_file
  else
    echo "$1"
  fi
}

script_log()
{
  log "[$script_name]: $1"
}

info_log() {
  script_log "INFO : $1"
}

error_log() {
  script_log "ERROR : $1"
}

arguments_check() {
  if [[ $args_count -lt 2 ]]; then
    info_log "$(usage)"
    info_log "Invoked command: \"$script_name $args\""
    error_log "Minimum number of arguments is 2 but $args_count provided."
    exit 1
  fi

  if [[ "$source_path" =~ ^- ]]; then
    info_log "$(usage)"
    info_log "Invoked command: \"$script_name $args\""
    error_log "First argument starts with a hyphen. It seems a flag."
    exit 1
  fi

  if [[ "$destination_path" =~ ^- ]]; then
    info_log "$(usage)"
    info_log "Invoked command: \"$script_name $args\""
    error_log "Second argument starts with a hyphen. It seems a flag."
    exit 1
  fi
}

safety_sync_check() {

    source_json=$($rclone_path size $source_path --json 2>/dev/null)
    info_log "source size json: $source_json"

    # It is Hardcoded because I do not want to use jq, get number after "count" key
    source_count=$(echo $source_json | sed -E 's/.*"count":([0-9]+).*/\1/')
    if [[ ! $source_count =~ ^[0-9]+$ ]]; then
      error_log "Parsing failure. Got source files count is not a digit: count=$source_count"
      exit 1
    fi

    destination_json=$($rclone_path size $destination_path --json 2>/dev/null)
    info_log "destination size json: $destination_json"

    destination_count=$(echo $destination_json | sed -E 's/.*"count":([0-9]+).*/\1/')
    if [[ ! $destination_count =~ ^[0-9]+$ ]]; then
      error_log "Parsing failure. Got dest files count is not a digit: count=$destination_count"
      exit 1
    fi

    if [[ $destination_count -eq 0 ]]; then
      info_log "Lose nothing, continue sync"
      return 0
    fi

    diff=$(( $destination_count - $source_count ))

    diff_percent=$(( $diff * 100 / $destination_count ))

    if [[ $diff_percent -gt 0 && $diff_percent -gt $tolerance_percent ]]; then
      info_log "Stop sync."
      info_log "Invoked command: \"$script_name $args\""
      error_log "Safety check failed: source files count = $source_count, dest files count = $destination_count, diff = $diff_percent%, tolerance < $tolerance_percent%."

      exit 1
    fi
}

while test -n "$1" ; do
  case $1 in
    --log-file=*)
      log_file=${1#--log-file=}
      ;;
    --dry-run)
      info_log "--dry-run option is present."
      ;;
  esac
  shift 1
done

# separate outputs between syncs
log ""

if [[ ! -f $rclone_path ]]; then
  error_log "Provided path for execution - $rclone_path does not exist"
  exit 1
fi

arguments_check
safety_sync_check

# invoke rclone sync
info_log "Invoked command: \"$script_name $args\""
$sync_command $args

exit 0