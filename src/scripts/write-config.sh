#!/bin/sh
set -e

# Define the path for the borgmatic configuration file
CONFIG_PATH="/etc/borgmatic.d/config.yaml"

STOP_BEFORE_BACKUP="${STOP_BEFORE_BACKUP}"
REMOTE_PATH="${REMOTE_PATH:-your-bucket/your-backup-path}"
DOCKER_HOST="${DOCKER_HOST:-http://socket-proxy:2375}"

NEW_CONFIG=$(cat <<EOF
source_directories:
  - /mnt/sources

repositories:
  - path: /opt/backup
    label: local_staging

compression: lz4
archive_name_format: '{hostname}-{now:%Y-%m-%d-%H%M%S}'
EOF
)

if [ -n "$POSTGRES_PASSWORD" ]; then
  if [ -z "$POSTGRES_DB" ]; then
    echo "POSTGRES_DB is not set. Using default database 'postgres'."
  fi

  NEW_CONFIG=$(cat <<EOF
${NEW_CONFIG}

postgresql_databases:
  - name: ${POSTGRES_DB}
    hostname: ${POSTGRES_HOST:-postgres}
    port: ${POSTGRES_PORT:-5432}
    password: ${POSTGRES_PASSWORD}
    username: ${POSTGRES_USER:-postgres}

EOF
)
fi

if [ -n "$MYSQL_PASSWORD" ]; then
  NEW_CONFIG=$(cat <<EOF
${NEW_CONFIG}
mysql_databases:
  - name: ${MYSQL_DB}
    hostname: ${MYSQL_HOST:-mysql}
    port: ${MYSQL_PORT:-3306}
    password: ${MYSQL_PASSWORD}
    username: ${MYSQL_USER:-root}

EOF
)
fi

if [ -n "$MONGODB_PASSWORD" ]; then
  NEW_CONFIG=$(cat <<EOF
${NEW_CONFIG}
mongodb_databases:
  - name: ${MONGODB_DB}
    hostname: ${MONGODB_HOST:-mongodb}
    port: ${MONGODB_PORT:-27017}
    password: ${MONGODB_PASSWORD}
    username: ${MONGODB_USER:-root}
EOF
)
fi

BEFORE_EVERYTHING="${BEFORE_EVERYTHING:-}"
BEFORE_BACKUP="${BEFORE_BACKUP:-}"
AFTER_BACKUP="${AFTER_BACKUP:-}" # Only on success
AFTER_EVERYTHING="${AFTER_EVERYTHING:-}"


exit 0

if [ -n "$REMOTE_PATH" ]; then
  NEW_CONFIG=$(cat <<EOF
${NEW_CONFIG}





# Add commands section conditionally based on STOP_BEFORE_BACKUP
if [ -n "$STOP_BEFORE_BACKUP" ]; then
  # If STOP_BEFORE_BACKUP is set, include both before and after commands
  cat <<EOF >> "$CONFIG_PATH"
commands:
  - before: everything
    run:
      - "echo 'Stopping services: $STOP_BEFORE_BACKUP'"
      - |
        for SERVICE in \$(echo "$STOP_BEFORE_BACKUP" | tr ',' ' '); do
          echo "Stopping service: \$SERVICE"
          curl -X POST -H "Content-Type: application/json" "$DOCKER_HOST/containers/\$SERVICE/stop" -d '{"t": 30}'
        done

  - after: everything
    states: [finish]
    run:
      - "echo 'Starting services again: $STOP_BEFORE_BACKUP'"
      - |
        for SERVICE in \$(echo "$STOP_BEFORE_BACKUP" | tr ',' ' '); do
          echo "Starting service: \$SERVICE"
          curl -X POST -H "Content-Type: application/json" "$DOCKER_HOST/containers/\$SERVICE/start"
        done
      - "echo 'Copying local staging repository to remote storage...'"
      - "rclone copy /opt/backup main-repo:${RCLONE_REMOTE_PATH} --progress"
      - "echo 'Pruning old remote backups...'"
      - "rclone delete --min-age 80d main-repo:${RCLONE_REMOTE_PATH} --progress"
EOF
else
  # If STOP_BEFORE_BACKUP is not set, only include the rclone commands
  cat <<EOF >> "$CONFIG_PATH"
commands:
  - after: everything
    states: [finish]
    run:
      - "echo 'Copying local staging repository to remote storage...'"
      - "rclone copy /opt/backup main-repo:${RCLONE_REMOTE_PATH} --progress"
      - "echo 'Pruning old remote backups...'"
      - "rclone delete --min-age 80d main-repo:${RCLONE_REMOTE_PATH} --progress"
EOF
fi

# Add a final newline if necessary for YAML parsers or file handling
echo "" >> "$CONFIG_PATH"

echo "Borgmatic configuration written successfully to $CONFIG_PATH."

# Validate the generated configuration
echo "Validating borgmatic configuration..."
borgmatic config validate --verbosity 1

echo "Borgmatic configuration validation successful."