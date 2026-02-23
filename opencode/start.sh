#!/bin/bash

USERNAME=${USERNAME:-coder}
USER_HOME="/home/coder"

if [ -n "$PUID" ] || [ -n "$PGID" ]; then
  CURRENT_UID=$(id -u "$USERNAME")
  CURRENT_GID=$(id -g "$USERNAME")
  TARGET_UID=${PUID:-$CURRENT_UID}
  TARGET_GID=${PGID:-$CURRENT_GID}

  if [ "$CURRENT_UID" != "$TARGET_UID" ] || [ "$CURRENT_GID" != "$TARGET_GID" ]; then
    echo "Changing $USERNAME UID:GID from $CURRENT_UID:$CURRENT_GID to $TARGET_UID:$TARGET_GID"

    EXISTING_USER=$(getent passwd $TARGET_UID | cut -d: -f1)
    if [ -n "$EXISTING_USER" ] && [ "$EXISTING_USER" != "$USERNAME" ]; then
      echo "WARNING: UID $TARGET_UID already exists for user '$EXISTING_USER'"
      echo "Removing conflicting user '$EXISTING_USER'"
      userdel $EXISTING_USER
    fi

    EXISTING_GROUP=$(getent group $TARGET_GID | cut -d: -f1)

    if [ -n "$EXISTING_GROUP" ] && [ "$EXISTING_GROUP" != "$USERNAME" ]; then
      echo "GID $TARGET_GID already exists as group '$EXISTING_GROUP', adding $USERNAME to it"
      if ! groups "$USERNAME" 2>/dev/null | grep -qw "$EXISTING_GROUP"; then
        usermod -aG "$EXISTING_GROUP" "$USERNAME"
      fi
    fi

    if [ "$CURRENT_UID" != "$TARGET_UID" ]; then
      usermod -u $TARGET_UID "$USERNAME"
    fi

    echo "UID/GID changed successfully to $(id -u "$USERNAME"):$(id -g "$USERNAME")"
  else
    echo "Using default UID:GID $CURRENT_UID:$CURRENT_GID"
  fi
else
  echo "Using default UID:GID $(id -u "$USERNAME"):$(id -g "$USERNAME")"
fi

export PATH="/usr/local/bin:$PATH"

OPENCODE_PORT=${OPENCODE_PORT:-4096}
OPENCODE_HOST=${OPENCODE_HOST:-${HOST:-0.0.0.0}}
OPENCODE_SERVER_PASSWORD=${OPENCODE_SERVER_PASSWORD:-}
OPENCODE_SERVER_USERNAME=${OPENCODE_SERVER_USERNAME:-opencode}

echo "Starting OpenCode..."
echo "Host: $OPENCODE_HOST, Port: $OPENCODE_PORT"

if [ -n "$OPENCODE_SERVER_PASSWORD" ]; then
  echo "Authentication enabled (user: $OPENCODE_SERVER_USERNAME)"
else
  echo "WARNING: OPENCODE_SERVER_PASSWORD not set - OpenCode will be accessible without authentication"
fi

export OPENCODE_SERVER_PASSWORD
export OPENCODE_SERVER_USERNAME

GOSU_GROUP="$USERNAME"
if [ -n "$PGID" ]; then
  PGID_GROUP=$(getent group $PGID | cut -d: -f1)
  if [ -n "$PGID_GROUP" ] && [ "$PGID_GROUP" != "$USERNAME" ]; then
    GOSU_GROUP="$PGID_GROUP"
  fi
fi

exec gosu "$USERNAME:$GOSU_GROUP" opencode serve --hostname "$OPENCODE_HOST" --port "$OPENCODE_PORT"
