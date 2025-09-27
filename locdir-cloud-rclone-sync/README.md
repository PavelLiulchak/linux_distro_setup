# Synchronization of local directory with the cloud one.

## 1. safe-rclone-sync.sh

The script is a safe wrapper around `rclone sync` that aborts synchronization if destination directory will lose
more than `20%` of files during the sync. It takes rclone specific arguments, options and flags that are passing to the
`rclone sync` if the condition is met.

## 2 create-unit-rclone-sync-shutdown.sh

The script generates a user systemd unit file that performs directories sync via `rclone sync` or via safe wrapper
`safe-rclone-sync.sh` before the system shutdown. It takes rclone specific arguments, options, flags and the script specific options (see --help).
The generated file is placed into `$HOME/.config/systemd/user` directory, the new generated service is enabled, the daemon is reloaded if needed.

Example:
```bash
./create-unit-rclone-sync-shutdown.sh $HOME/Documents/PARA mailru:PARA --backup-dir mailru:Backups/PARA/\$\(date \-I\) -vv --log-file=$HOME/Logs/para-cloud-rclone-sync.log --unit-file-name=para-cloud-rclone-sync.service --use-safe-script
```