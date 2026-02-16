#!/bin/bash

echo "my-code-server debian container"

if [ -d /home/vscodeuser ]; then
    current_owner=$(stat -c %U:%G /home/vscodeuser 2>/dev/null || stat -f %u:%g /home/vscodeuser 2>/dev/null)
    vscodeuser_uid=$(id -u vscodeuser)
    vscodeuser_gid=$(id -g vscodeuser)
    expected_owner="${vscodeuser_uid}:${vscodeuser_gid}"
    
    if [ "$current_owner" != "$expected_owner" ]; then
        echo "Fixing /home/vscodeuser permissions (current: $current_owner, expected: $expected_owner)..."
        chown -R "$expected_owner" /home/vscodeuser
        chmod -R 755 /home/vscodeuser
        echo "Permissions fixed successfully"
    fi
else
    echo "Creating /home/vscodeuser directory with correct ownership..."
    vscodeuser_uid=$(id -u vscodeuser)
    vscodeuser_gid=$(id -g vscodeuser)
    mkdir -p /home/vscodeuser
    chown -R "${vscodeuser_uid}:${vscodeuser_gid}" /home/vscodeuser
    chmod -R 755 /home/vscodeuser
    echo "Directory created and permissions set"
fi

# Handle UID/GID changes if environment variables are set
if [ -n "$PUID" ] || [ -n "$PGID" ]; then
  CURRENT_UID=$(id -u vscodeuser)
  CURRENT_GID=$(id -g vscodeuser)
  TARGET_UID=${PUID:-$CURRENT_UID}
  TARGET_GID=${PGID:-$CURRENT_GID}
  
  if [ "$CURRENT_UID" != "$TARGET_UID" ] || [ "$CURRENT_GID" != "$TARGET_GID" ]; then
    echo "Changing vscodeuser UID:GID from $CURRENT_UID:$CURRENT_GID to $TARGET_UID:$TARGET_GID"
    
    # Check if target UID already exists
    EXISTING_USER=$(getent passwd $TARGET_UID | cut -d: -f1)
    if [ -n "$EXISTING_USER" ] && [ "$EXISTING_USER" != "vscodeuser" ]; then
      echo "WARNING: UID $TARGET_UID already exists for user '$EXISTING_USER'"
      echo "Removing conflicting user '$EXISTING_USER'"
      userdel $EXISTING_USER
    fi
    
    # Check if target GID already exists
    EXISTING_GROUP=$(getent group $TARGET_GID | cut -d: -f1)
    
    if [ -n "$EXISTING_GROUP" ] && [ "$EXISTING_GROUP" != "vscodeuser" ]; then
      # GID exists, use the existing group
      echo "GID $TARGET_GID already exists as group '$EXISTING_GROUP', using it"
      usermod -u $TARGET_UID -g $TARGET_GID vscodeuser
    else
      # GID doesn't exist or belongs to vscodeuser, safe to modify
      if [ "$CURRENT_GID" != "$TARGET_GID" ]; then
        groupmod -g $TARGET_GID vscodeuser
      fi
      if [ "$CURRENT_UID" != "$TARGET_UID" ]; then
        usermod -u $TARGET_UID vscodeuser
      fi
    fi
    
    # Fix permissions on home directory
    chown -R $TARGET_UID:$TARGET_GID /home/vscodeuser
    
    echo "UID/GID changed successfully to $(id -u vscodeuser):$(id -g vscodeuser)"
  else
    echo "Using default UID:GID $CURRENT_UID:$CURRENT_GID"
  fi
else
  echo "Using default UID:GID $(id -u vscodeuser):$(id -g vscodeuser)"
fi

# Check if PORT environment variable is set, default to 8585 if not
if [ -z "$PORT" ]; then
  echo "No PORT provided, using default port: 8585"
  PORT=8585
else
  echo "Using provided port: $PORT"
fi

# Check if HOST environment variable is set, default to 0.0.0.0 if not
if [ -z "$HOST" ]; then
  echo "No HOST provided, using default host: 0.0.0.0"
  HOST=0.0.0.0
else
  echo "Using provided host: $HOST"
fi

# Initialize the base command
CMD="code serve-web --host $HOST --port $PORT"

# Check for SERVER_DATA_DIR and add to command if set
if [ -n "$SERVER_DATA_DIR" ]; then
  echo "Using server data directory: $SERVER_DATA_DIR"
  CMD="$CMD --server-data-dir $SERVER_DATA_DIR"
fi

# Check for SERVER_BASE_PATH and add to command if set
if [ -n "$SERVER_BASE_PATH" ]; then
  echo "Using server base path: $SERVER_BASE_PATH"
  CMD="$CMD --server-base-path $SERVER_BASE_PATH"
fi

# Check if SOCKET_PATH environment variable is set
if [ -n "$SOCKET_PATH" ]; then
  echo "Using socket path: $SOCKET_PATH"
  CMD="$CMD --socket-path $SOCKET_PATH"
fi

# Check if TOKEN or TOKEN_FILE environment variable is set
if [ -n "$TOKEN" ]; then
  echo "Starting with token: $TOKEN"
  CMD="$CMD --connection-token $TOKEN"
elif [ -n "$TOKEN_FILE" ]; then
  echo "Using token file: $TOKEN_FILE"
  CMD="$CMD --connection-token-file $TOKEN_FILE"
else
  echo "No TOKEN or TOKEN_FILE provided, starting without token"
  CMD="$CMD --without-connection-token"
fi

# Always accept the server license terms
echo "Server license terms accepted"
CMD="$CMD --accept-server-license-terms"

# Add verbosity options if set
if [ -n "$VERBOSE" ] && [ "$VERBOSE" = "true" ]; then
  echo "Running in verbose mode"
  CMD="$CMD --verbose"
fi

# Add log level if set
if [ -n "$LOG_LEVEL" ]; then
  echo "Using log level: $LOG_LEVEL"
  CMD="$CMD --log $LOG_LEVEL"
fi

# Add CLI data directory if set
if [ -n "$CLI_DATA_DIR" ]; then
  echo "Using CLI data directory: $CLI_DATA_DIR"
  CMD="$CMD --cli-data-dir $CLI_DATA_DIR"
fi

# Start AI services in background
echo "Starting AI services..."
su - vscodeuser -c "export CDN_PROXY_HOST=\"${CDN_PROXY_HOST}\"; export USE_CDN_PROXY=\"${USE_CDN_PROXY}\"; export OPENCODE_HOST=\"${OPENCODE_HOST}\"; export OPENCODE_PORT=\"${OPENCODE_PORT}\"; export OPENCLAW_HOST=\"${OPENCLAW_HOST}\"; export OPENCLAW_PORT=\"${OPENCLAW_PORT}\"; export OPENCODE_SERVER_PASSWORD=\"${OPENCODE_SERVER_PASSWORD}\"; export OPENCODE_SERVER_USERNAME=\"${OPENCODE_SERVER_USERNAME}\"; export CLAW_GATEWAY_TOKEN=\"${CLAW_GATEWAY_TOKEN}\"; /app/start_ai.sh"

echo "Executing via VSCode wrapper: $CMD"
exec su - vscodeuser -c "export CDN_PROXY_HOST=\"${CDN_PROXY_HOST}\"; export USE_CDN_PROXY=\"${USE_CDN_PROXY}\"; /app/vscode-wrapper.sh $CMD"
