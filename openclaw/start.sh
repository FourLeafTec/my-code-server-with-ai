#!/bin/bash

USERNAME=${USERNAME:-openclawuser}
USER_HOME="/home/$USERNAME"
CONFIG_DIR="$USER_HOME/.openclaw"

OPENCLAW_PORT=${OPENCLAW_PORT:-18789}
OPENCLAW_HOST=${OPENCLAW_HOST:-${HOST:-0.0.0.0}}
OPENCLAW_GATEWAY_TOKEN=${OPENCLAW_GATEWAY_TOKEN:-}
OPENCLAW_TRUSTED_PROXIES=${OPENCLAW_TRUSTED_PROXIES:-}

mkdir -p "$CONFIG_DIR" 2>/dev/null || sudo mkdir -p "$CONFIG_DIR"

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
      echo "GID $TARGET_GID already exists as group '$EXISTING_GROUP', using it"
      usermod -u $TARGET_UID -g $TARGET_GID "$USERNAME"
    else
      if [ "$CURRENT_GID" != "$TARGET_GID" ]; then
        groupmod -g $TARGET_GID "$USERNAME"
      fi
      if [ "$CURRENT_UID" != "$TARGET_UID" ]; then
        usermod -u $TARGET_UID "$USERNAME"
      fi
    fi

    chown -R $TARGET_UID:$TARGET_GID "$USER_HOME"

    echo "UID/GID changed successfully to $(id -u "$USERNAME"):$(id -g "$USERNAME")"
  else
    echo "Using default UID:GID $CURRENT_UID:$CURRENT_GID"
  fi
else
  echo "Using default UID:GID $(id -u "$USERNAME"):$(id -g "$USERNAME")"
fi

if [ "$OPENCLAW_HOST" = "0.0.0.0" ] || [ "$OPENCLAW_HOST" = "0.0.0.0/0" ] || [ "$OPENCLAW_HOST" = "" ]; then
    BIND_MODE="lan"
else
    BIND_MODE="loopback"
fi

if [ -n "$OPENCLAW_TRUSTED_PROXIES" ]; then
    echo "[OpenClaw] Setting up trusted-proxy authentication mode..."
    echo "[OpenClaw] Trusted proxies: $OPENCLAW_TRUSTED_PROXIES"
    cat > "$CONFIG_DIR/config.json" << CONFIG_EOF
{
  "gateway": {
    "mode": "local",
    "bind": "$BIND_MODE",
    "port": $OPENCLAW_PORT,
    "trustedProxies": $OPENCLAW_TRUSTED_PROXIES,
    "auth": {
      "mode": "trusted-proxy",
      "trustedProxy": {
        "userHeader": "x-forwarded-user"
      }
    },
    "controlUi": {
      "allowInsecureAuth": true  
    }
  }
}
CONFIG_EOF
    echo "[OpenClaw] Trusted-proxy authentication configured (bind mode: $BIND_MODE)"
    export OPENCLAW_TRUSTED_PROXIES
elif [ -z "$OPENCLAW_GATEWAY_TOKEN" ] && [ "$BIND_MODE" = "lan" ]; then
    OPENCLAW_GATEWAY_TOKEN=$(openssl rand -hex 32 2>/dev/null || echo "default-token-$(date +%s)")
    echo "[OpenClaw] Generated default token for lan mode: $OPENCLAW_GATEWAY_TOKEN"
    echo "[OpenClaw] For production, set OPENCLAW_GATEWAY_TOKEN environment variable"

    if [ -n "$OPENCLAW_GATEWAY_TOKEN" ]; then
        cat > "$CONFIG_DIR/config.json" << CONFIG_EOF
{
  "gateway": {
    "mode": "local",
    "bind": "$BIND_MODE",
    "port": $OPENCLAW_PORT,
    "auth": {
      "mode": "token",
      "token": "$OPENCLAW_GATEWAY_TOKEN"
    },
    "controlUi": {
      "allowInsecureAuth": true  
    }
  }
}
CONFIG_EOF
        echo "[OpenClaw] Token authentication configured (bind mode: $BIND_MODE)"
        export OPENCLAW_GATEWAY_TOKEN
    fi
elif [ -n "$OPENCLAW_GATEWAY_TOKEN" ]; then
    cat > "$CONFIG_DIR/config.json" << CONFIG_EOF
{
  "gateway": {
    "mode": "local",
    "bind": "$BIND_MODE",
    "port": $OPENCLAW_PORT,
    "auth": {
      "mode": "token",
      "token": "$OPENCLAW_GATEWAY_TOKEN"
    },
    "controlUi": {
      "allowInsecureAuth": true  
    }
  }
}
CONFIG_EOF
    echo "[OpenClaw] Token authentication configured (bind mode: $BIND_MODE)"
    export OPENCLAW_GATEWAY_TOKEN
else
    echo "[WARNING] OPENCLAW_GATEWAY_TOKEN not set - OpenClaw will start without authentication"
    echo "[WARNING] For security, please set OPENCLAW_GATEWAY_TOKEN environment variable"
fi

echo "Starting OpenClaw..."
echo "Host: $OPENCLAW_HOST, Port: $OPENCLAW_PORT"

export OPENCLAW_CONFIG_PATH="$CONFIG_DIR/config.json"

exec su "$USERNAME" -c "openclaw gateway"
