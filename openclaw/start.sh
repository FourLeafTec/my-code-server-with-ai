#!/bin/bash
# OpenClaw configuration startup script
# Core logic: generate config if not exists, update with openclaw config set if exists

# =============================================================================
# User configuration
# =============================================================================

USERNAME=${USERNAME:-coder}
USER_HOME="/home/coder"
CONFIG_DIR="$USER_HOME/.openclaw"
CONFIG_FILE="$CONFIG_DIR/config.json"

# =============================================================================
# UID/GID handling
# =============================================================================

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

# Add /usr/local/openclaw/bin to PATH for openclaw
export PATH="/usr/local/openclaw/bin:/home/coder/.npm-global/bin:/usr/local/bin:/usr/sbin:$PATH"

# =============================================================================
# Network configuration
# =============================================================================

DEFAULT_PORT=18789
DEFAULT_HOST=0.0.0.0
OPENCLAW_PORT=${OPENCLAW_PORT:-$DEFAULT_PORT}
OPENCLAW_HOST=${OPENCLAW_HOST:-$DEFAULT_HOST}

# =============================================================================
# Authentication configuration
# =============================================================================

OPENCLAW_GATEWAY_TOKEN=${OPENCLAW_GATEWAY_TOKEN:-}
OPENCLAW_TRUSTED_PROXIES=${OPENCLAW_TRUSTED_PROXIES:-}

# =============================================================================
# Logging functions
# =============================================================================

log() {
    echo "[Start] $*"
}

log_config() {
    echo "========================================="
    log "Configuration Setup"
    echo "========================================="
    log "Config Path: $CONFIG_FILE"
    log "User: $USERNAME"
    log "Home: $USER_HOME"
    log "Host: $OPENCLAW_HOST"
    log "Port: $OPENCLAW_PORT"
    echo "========================================="
}

# =============================================================================
# Check if config file exists
# =============================================================================

check_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log "Configuration file not found, will create new one"
        return 1
    else
        log "Configuration file exists: $CONFIG_FILE"
        return 0
    fi
}

# =============================================================================
# Generate new configuration
# =============================================================================

generate_config() {
    log "Generating new configuration..."
    
    mkdir -p "$CONFIG_DIR"
    
    cat > "$CONFIG_FILE" << CONFIG_EOF
{
  "gateway": {
    "mode": "local",
    "bind": "lan",
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
    
    log "New config generated at: $CONFIG_FILE"
    return 0
}

# =============================================================================
# Update configuration with openclaw config set
# =============================================================================

update_with_openclaw_config() {
    log "Attempting to update configuration using 'openclaw config set' command..."
    
    if ! command -v openclaw &>/dev/null; then
        log "OpenClaw CLI not found or not accessible"
        log "Using existing configuration without changes"
        log "To update config manually, use the OpenClaw dashboard or edit config file"
        return 1
    fi
    
    if [ "$OPENCLAW_PORT" != "$DEFAULT_PORT" ]; then
        log "Updating gateway.port to $OPENCLAW_PORT"
        openclaw config set gateway.port $OPENCLAW_PORT 2>/dev/null || \
        openclaw config --set gateway.port=$OPENCLAW_PORT 2>/dev/null || \
        log "Failed to update gateway.port via CLI"
    fi
    
    if [ "$OPENCLAW_HOST" != "$DEFAULT_HOST" ]; then
        log "Updating gateway.bind to $OPENCLAW_HOST"
        openclaw config set gateway.bind $OPENCLAW_HOST 2>/dev/null || \
        openclaw config --set gateway.bind=$OPENCLAW_HOST 2>/dev/null || \
        log "Failed to update gateway.bind via CLI"
    fi
    
    if [ -n "$OPENCLAW_GATEWAY_TOKEN" ]; then
        log "Updating gateway.auth.token"
        openclaw config set gateway.auth.token $OPENCLAW_GATEWAY_TOKEN 2>/dev/null || \
        openclaw config --set gateway.auth.token=$OPENCLAW_GATEWAY_TOKEN 2>/dev/null || \
        log "Failed to update gateway.auth.token via CLI"
    fi
    
    log "Configuration update completed"
}

# =============================================================================
# Main configuration logic
# =============================================================================

main() {
    log_config
    
    mkdir -p "$CONFIG_DIR"
    
    if check_config; then
        log "Configuration exists, attempting to update using 'openclaw config set' command..."
        update_with_openclaw_config
    else
        generate_config
    fi
}

# =============================================================================
# Execute
# =============================================================================

main "$@"

# Export config path (official command may need it)
export OPENCLAW_CONFIG_PATH="$CONFIG_FILE"

SETUID=$(id -u "$USERNAME")
SETGID=$(id -g "$USERNAME")
SETGROUPS="--clear-groups"

if [ -n "$EXTRA_GID" ]; then
  SETGROUPS="--groups=$EXTRA_GID"
fi

exec setpriv --reuid=$SETUID --regid=$SETGID $SETGROUPS -- /usr/local/openclaw/bin/openclaw gateway
