#!/bin/sh
set -e

### Environment Variables
# TYPE: string
#   - currently supported: b2

STORAGE_TYPE="${BORG_STORAGE_TYPE:-b2}"
B2_ACCOUNT="${BORG_B2_ACCOUNT:-???}"
B2_KEY="${BORG_B2_KEY:-???}"

if [ "$STORAGE_TYPE" = "b2" ]; then
    ### Check for required environment variables
    if [ "$B2_ACCOUNT" = "???" ] || [ "$B2_KEY" = "???" ]; then
        echo "B2_ACCOUNT and B2_KEY must be set via environment variables."
        exit 1
    fi

    echo "Writing rclone configuration to /root/.config/rclone/rclone.conf"
    mkdir -p "/root/.config/rclone"
    cat <<EOF > "/root/.config/rclone/rclone.conf"
[main-repo]
type = b2
account = ${B2_ACCOUNT}
key = ${B2_KEY}
hard_delete = true
EOF
    echo "Rclone configuration written successfully."
else
    echo "Unsupported storage type: $STORAGE_TYPE"
    exit 1
fi