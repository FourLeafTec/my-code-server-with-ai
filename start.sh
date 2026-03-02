#!/bin/bash
set -e

echo "========================================="
echo "Code Server with AI - Process Compose"
echo "========================================="

USERNAME=${USERNAME:-coder}
USER_HOME="/home/coder"
CONFIG_DIR="$USER_HOME/.openclaw"
PC_CONFIG="/app/process-compose.yaml"
PC_SHORTCUTS="/home/coder/.config/process-compose"

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
      userdel $EXISTING_USER
    fi

    EXISTING_GROUP=$(getent group $TARGET_GID | cut -d: -f1)
    if [ -n "$EXISTING_GROUP" ] && [ "$EXISTING_GROUP" != "$USERNAME" ]; then
      if ! groups "$USERNAME" 2>/dev/null | grep -qw "$EXISTING_GROUP"; then
        usermod -aG "$EXISTING_GROUP" "$USERNAME"
      fi
    fi

    if [ "$CURRENT_UID" != "$TARGET_UID" ]; then
      usermod -u $TARGET_UID "$USERNAME"
    fi

    echo "UID/GID changed successfully to $(id -u "$USERNAME"):$(id -g "$USERNAME")"
  fi
fi

if [ "$USE_CDN_PROXY" = "true" ] && [ -n "$CDN_PROXY_HOST" ]; then
  echo "Applying CDN proxy configuration..."
  if [ -f /app/fix-cdn-proxy.sh ]; then
    CDN_PROXY_HOST="$CDN_PROXY_HOST" /app/fix-cdn-proxy.sh
  fi
fi

mkdir -p "$CONFIG_DIR"
mkdir -p "$PC_SHORTCUTS"
chown -R coder:coder "$USER_HOME"
if [ ! -f "$CONFIG_DIR/config.json" ]; then
  echo "Creating OpenClaw configuration..."
  cat > "$CONFIG_DIR/config.json" << EOF
{
  "gateway": {
    "mode": "local",
    "bind": "lan",
    "port": ${OPENCLAW_PORT:-18789},
    "auth": {
      "mode": "token",
      "token": "${OPENCLAW_GATEWAY_TOKEN:-}"
    },
    "controlUi": {
      "allowInsecureAuth": true
    }
  }
}
EOF
  chown -R coder:coder "$CONFIG_DIR"
fi

SETUID=$(id -u "$USERNAME")
SETGID=$(id -g "$USERNAME")

echo "========================================="
echo "Starting Process Compose..."
echo "========================================="
echo "VS Code Server: ${VSCODE_PORT:-8585}"
echo "OpenCode:       ${OPENCODE_PORT:-4096}"
echo "OpenClaw:       ${OPENCLAW_PORT:-18789}"
echo "========================================="

export HOME="$USER_HOME"

exec setpriv --reuid=$SETUID --regid=$SETGID --clear-groups -- \
  process-compose \
  -f "$PC_CONFIG" \
  up \
  -t=false
