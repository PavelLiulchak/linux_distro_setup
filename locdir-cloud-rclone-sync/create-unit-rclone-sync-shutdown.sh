#!/bin/bash

pushd "$(dirname "$(which "$0")")" >/dev/null
script_dir="$(pwd -P)"
popd >/dev/null

script_name=$(basename "$0")

exec_path="/usr/bin/rclone"
sync_command="$exec_path sync"

safe_rclone_sync_script="safe-rclone-sync.sh"
safe_rclone_sync_script_path=$script_dir/$safe_rclone_sync_script

user_unit_files_path="$HOME/.config/systemd/user"
unit_file_name="locdir-cloud-rclone-sync-user.service"
unit_file_path=$user_unit_files_path/$unit_file_name

rclone_args=()

usage() {
cat <<EOF

Description:
  The script generates a user .service file that runs 'rclone sync' command
  before the system shutdown. The generated file is placed in
  $user_unit_files_path directory.
  If --use-safe-script option is provided then $safe_rclone_sync_script script is
  used instead of pure 'rclone sync' command.

Usage:
  $script_name source:path destination:path [rclone flags] [options]

rclone sync options:
  source:path                   Path to source directory (remote or local).
  destination:path              Path to destination directory (remote or local).
  rclone flags                  rclone flags, see 'man rclone'.

Options:
  --unit-file-name=<name>       Name of unit file to be generated. It has to end with ".service" suffix.
  --use-safe-script             Use safe rclone sync wrapper instead of rclone.
  --help                        Prints this message.

Note:
  The script checks that no other unit file contains the mention of destination directory.
  If any are found, a warning is shown.

CAUTION!
  Check the passing aruments carefully. There is no arguments correctness check.
EOF
}

generate_systemd_unit() {
  cat <<EOF
[Unit]
Description=Sync Directory with cloud before shutdown
Requires=default.target

[Service]
Type=oneshot
RemainAfterExit=yes
TimeoutStopSec=300
ExecStart=/bin/true
ExecStop=/bin/bash -c "$sync_command ${rclone_args[@]}"

[Install]
WantedBy=default.target
EOF
}

get_correct_yes_no_response() {
  while true; do
    read -r -p "$1" response

    response=${response,,}

    case "$response" in
        y|yes)
            echo -n "yes"
            break
            ;;
        n|no)
            echo -n "no"
            break
            ;;
    esac
done
}

check_file() {
  echo "$unit_file_name file is generated. Performing checks..."
  echo "Check syntax: systemd-analyze --user verify $unit_file_name"
  systemd-analyze --user verify $unit_file_name

  echo "Check status: systemctl --user status $unit_file_name"
  systemctl --user status $unit_file_name

  echo "Check logs: journalctl --user -u $unit_file_name"
  journalctl --user -u $unit_file_name
}

# extract rclone args from command line
for arg in "$@"; do
    if [[ "$arg" == --unit-file-name=* ]]; then
        continue
    fi

    if [[ "$arg" == --use-safe-script ]]; then
        continue
    fi

    rclone_args+=("$arg")
done

while test -n "$1" ; do
  case $1 in
    --unit-file-name=*)
      unit_file_name=${1#--unit-file-name=}
      unit_file_path=$user_unit_files_path/$unit_file_name
      ;;
    --use-safe-script)
      exec_path=$safe_rclone_sync_script_path
      sync_command=$safe_rclone_sync_script_path
      ;;
    --help|-h)
      usage
      exit 0
      ;;
  esac
  shift 1
done

if [[ ! -f $exec_path ]]; then
  echo "Provided path for execution - $exec_path does not exist"
  exit 1
fi

if [[ ${#unit_file_name} -gt 255 || ${#unit_file_name} -eq 0 ]] ; then
  echo "Provided unit file name length = ${#unit_file_name} but it has to be > 0 and <= 255 characters"
  exit 1
fi

unit_file_name_allowable_pattern='^[A-Za-z0-9:_.\\-]*$'
if [[ ! $unit_file_name =~ $unit_file_name_allowable_pattern ]]; then
  echo "Provided unit file name \"$unit_file_name\" contains unallowable characters."
  echo "Allowable pattern is $unit_file_name_allowable_pattern"
  exit 1
fi

if [[ ! $unit_file_name == *.service ]] ; then
  echo "Provided unit file name - $unit_file_name has to end with \".service\""
  exit 1
fi

rclone_args_count=${#rclone_args[@]}
if [[ $rclone_args_count -lt 2 ]]; then
    echo "$(usage)"
    echo "Invoked command: \"$sync_command ${rclone_args[@]}\""
    echo "Minimum number of arguments is 2 but $rclone_args_count provided. See 'man rclone'"
    exit 1
fi

if [[ -f $unit_file_path ]] ; then

  echo "Unit file $unit_file_path exists"
  response=$(get_correct_yes_no_response "Rewrite it? Type Y/n ")

  if [[ $response == yes ]] ; then
    echo "$(generate_systemd_unit)" > $unit_file_path

    systemctl --user daemon-reload
    check_file
  fi

  exit 0
fi

pushd "$user_unit_files_path" >/dev/null
# files that contain the mention of dest directory
dest_directory=${rclone_args[1]}
files=($(grep -lr $dest_directory))
files_count=${#files[@]}

if [[ $files_count -gt 0 ]]; then
    echo "Found existing systemd unit files that already contain the mention of directory - \"$dest_directory\""
    echo "Files: ${files[@]}"
    echo "WARN: If you have a systemd that already syncs into the same destination directory, collisions may occur."
    response=$(get_correct_yes_no_response "Is it ok? Type Y/n ")

    if [[ $response == no ]] ; then
      echo "Exiting..."
      exit 0
    fi
fi
popd >/dev/null

echo "$(generate_systemd_unit)" > $unit_file_path

systemctl --user enable $unit_file_name
systemctl --user start $unit_file_name
check_file

exit 0