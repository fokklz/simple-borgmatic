#!/bin/bash
set -e

RCLONE_CONFIG_PATH="/etc/borgmatic.d/rclone.conf"
CONFIG_PATH="/etc/borgmatic.d/config.yaml"

# Ensure mountpoint and symlinks exist
if [[ ! -L "/etc/borgmatic.d" ]]; then # Check if the symlink exists, implying unified-mountpoint ran
    echo "Unified mountpoint structure not found. Running setup..."
    bash /scripts/unified-mountpoint.sh
else
    echo "Unified mountpoint structure already exists."
fi


if [[ ! -f "$CONFIG_PATH" ]]; then
    echo "Borgmatic configuration file not found. Running write-config script..."
    bash /scripts/write-config.sh
    bash /scripts/write-crontab.sh
fi
# Prepare rclone config if it doesn't exist
if [ ! -f "$RCLONE_CONFIG_PATH" ]; then
    echo "Rclone config $RCLONE_CONFIG_PATH not found. Running preparation script..."
    bash /scripts/prepare-rclone.sh
else
    echo "Rclone config $RCLONE_CONFIG_PATH already exists."
fi

if [ ! -f "/opt/backup/config" ]; then
    echo "Borg repository not found or not initialized at /opt/backup. Initializing..."
    # Ensure the directory exists
    mkdir -p "/opt/backup"
    borgmatic config validate && borgmatic init --encryption keyfile-blake2
    INIT_STATUS=$?
    if [ $INIT_STATUS -ne 0 ]; then
        echo "Borgmatic initialization failed with status $INIT_STATUS."
        exit $INIT_STATUS;
    fi
    echo "Borg repository initialized.";
else
    echo "Borg repository already initialized at /opt/backup."
fi



# Run Borgmatic with the provided arguments
echo "Starting cron daemon for scheduled borgmatic tasks..."
exec crond -f -d 8