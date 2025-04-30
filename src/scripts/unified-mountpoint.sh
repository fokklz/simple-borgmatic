#!/bin/sh
set -e

BORGMATIC_MOUNT="/root/borgmatic"

if [ ! -d "$BORGMATIC_MOUNT" ]; then
    echo "Mount point $BORGMATIC_MOUNT does not exist. Creating it."
    mkdir -p "$BORGMATIC_MOUNT"
else
    echo "Mount point $BORGMATIC_MOUNT already exists."
fi

# Define target directories within the mount point
TARGET_ETC_D="$BORGMATIC_MOUNT/etc.d"
TARGET_CONFIG="$BORGMATIC_MOUNT/config"
TARGET_REPO="$BORGMATIC_MOUNT/repo"
TARGET_STATE="$BORGMATIC_MOUNT/state"
TARGET_CACHE="$BORGMATIC_MOUNT/cache"
RCLONE_CONFIG="$BORGMATIC_MOUNT/rclone"

# Create target directories
mkdir -p "$TARGET_ETC_D"
mkdir -p "$TARGET_CONFIG"
mkdir -p "$TARGET_REPO"
mkdir -p "$TARGET_STATE"
mkdir -p "$TARGET_CACHE"
mkdir -p "$RCLONE_CONFIG"

# Create symbolic links
# Ensure parent directories for links exist
mkdir -p /etc
mkdir -p /opt
mkdir -p /root/.config
mkdir -p /root/.local/state
mkdir -p /root/.cache
mkdir -p /root/.config/rclone

ln -sf "$TARGET_ETC_D" /etc/borgmatic.d
ln -sf "$TARGET_CONFIG" /root/.config/borg
ln -sf "$TARGET_REPO" /opt/backup
ln -sf "$TARGET_STATE" /root/.local/state/borgmatic
ln -sf "$TARGET_CACHE" /root/.cache/borg
ln -sf "$RCLONE_CONFIG" /root/.config/rclone

echo "Symbolic links created successfully."