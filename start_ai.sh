#!/bin/bash

FLAG_DIR="/tmp"
LOG_DIR="/home/vscodeuser/.ai"
CONFIG_DIR="/home/vscodeuser/.openclaw"

# Default ports and hosts
OPENCODE_PORT="${OPENCODE_PORT:-4096}"
OPENCODE_HOST="${OPENCODE_HOST:-${HOST:-0.0.0.0}}"
OPENCLAW_PORT="${OPENCLAW_PORT:-18789}"
OPENCLAW_HOST="${OPENCLAW_HOST:-${HOST:-0.0.0.0}}"

# Authentication (optional)
OPENCODE_SERVER_PASSWORD="${OPENCODE_SERVER_PASSWORD:-}"
OPENCODE_SERVER_USERNAME="${OPENCODE_SERVER_USERNAME:-opencode}"
CLAW_GATEWAY_TOKEN="${CLAW_GATEWAY_TOKEN:-}"

# Log retention days (default: 3)
LOG_RETENTION_DAYS="${LOG_RETENTION_DAYS:-3}"

# Create directories
mkdir -p "$LOG_DIR" 2>/dev/null || sudo mkdir -p "$LOG_DIR" || {
    echo "[ERROR] Failed to create log directory: $LOG_DIR"
    exit 1
}
mkdir -p "$CONFIG_DIR" 2>/dev/null || sudo mkdir -p "$CONFIG_DIR" || {
    echo "[ERROR] Failed to create config directory: $CONFIG_DIR"
    exit 1
}

# Log rotation function - rotates daily, keeps last N days
rotate_log() {
    local log_file="$1"
    local base_name=$(basename "$log_file" .log)
    local current_date=$(date +%Y%m%d)
    
    # Check if log exists and needs rotation (new day)
    if [ -f "$log_file" ]; then
        local file_date=$(stat -c %Y "$log_file" 2>/dev/null || stat -f %m "$log_file" 2>/dev/null)
        local current_timestamp=$(date +%s)
        local days_old=$(( (current_timestamp - file_date) / 86400 ))
        
        # Rotate if file is from a different day
        if [ $days_old -ge 1 ]; then
            mv "$log_file" "${log_file}.${current_date}"
        fi
    fi
    
    # Clean up old logs (keep only last N days)
    find "$LOG_DIR" -name "${base_name}.log.*" -type f -mtime +$LOG_RETENTION_DAYS -delete 2>/dev/null
}

monitor_path_state() {
    local log_file="$LOG_DIR/path-state.log"
    local cli_web_dir="/home/vscodeuser/.vscode/cli/serve-web"
    local state_file="/home/vscodeuser/.vscode-server-patch-state/cli-hashes-patched"
    local state_dir="/home/vscodeuser/.vscode-server-patch-state"
    local check_interval="${PATH_STATE_CHECK_INTERVAL:-60}"

    mkdir -p "$state_dir" 2>/dev/null

    rotate_log "$log_file"

    echo "==========================================" | tee -a "$log_file"
    echo "Path State Monitor Started" | tee -a "$log_file"
    echo "==========================================" | tee -a "$log_file"
    echo "Check interval: ${check_interval}s" | tee -a "$log_file"
    echo "Monitoring: $cli_web_dir" | tee -a "$log_file"
    echo "State file: $state_file" | tee -a "$log_file"
    echo "" | tee -a "$log_file"

    while true; do
        local new_hash_found=0
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

        if [ ! -d "$cli_web_dir" ]; then
            echo "[$timestamp] CLI web directory not found yet, waiting..." | tee -a "$log_file"
            sleep $check_interval
            continue
        fi

        local hash_dirs=$(find "$cli_web_dir" -maxdepth 1 -type d -name '[a-f0-9]*' 2>/dev/null)

        if [ -z "$hash_dirs" ]; then
            echo "[$timestamp] No hash directories found" | tee -a "$log_file"
        else
            for hash_dir in $hash_dirs; do
                local hash=$(basename "$hash_dir")

                if [ ! -f "$state_file" ] || ! grep -qx "$hash" "$state_file" 2>/dev/null; then
                    new_hash_found=1
                    echo "[$timestamp] ➜ New hash detected: $hash" | tee -a "$log_file"
                fi
            done
        fi

        if [ "$new_hash_found" -eq 1 ] && [ "$USE_CDN_PROXY" = "true" ]; then
            echo "[$timestamp] 🔄 Applying CDN proxy patches..." | tee -a "$log_file"

            mkdir -p "$FLAG_DIR"
            touch "$FLAG_DIR/.patch-cdn"

            if CDN_PROXY_HOST="$CDN_PROXY_HOST" /app/fix-cdn-proxy.sh >> "$log_file" 2>&1; then
                echo "[$timestamp] ✅ CDN proxy patches applied successfully" | tee -a "$log_file"

                echo "" > "$state_file"
                for hash_dir in $hash_dirs; do
                    local hash=$(basename "$hash_dir")
                    echo "$hash" >> "$state_file"
                done
                echo "[$timestamp] ✓ Updated state file with $(wc -l < "$state_file") hashes" | tee -a "$log_file"

                restart_vscode_server | tee -a "$log_file"
            else
                echo "[$timestamp] ❌ CDN proxy patching failed (not updating state file)" | tee -a "$log_file"
            fi

            rm -f "$FLAG_DIR/.patch-cdn"
            echo "" | tee -a "$log_file"
        elif [ "$new_hash_found" -eq 1 ] && [ "$USE_CDN_PROXY" != "true" ]; then
            echo "[$timestamp] ℹ️  New hash detected but CDN proxy is disabled (USE_CDN_PROXY=$USE_CDN_PROXY)" | tee -a "$log_file"
            echo "[$timestamp]   Skipping patch. Set USE_CDN_PROXY=true to enable auto-patching." | tee -a "$log_file"
            echo "" | tee -a "$log_file"
        else
            echo "[$timestamp] ✓ All hashes patched, no changes detected" | tee -a "$log_file"
        fi

        rotate_log "$log_file"

        sleep $check_interval
    done
}

restart_vscode_server() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] Restarting VSCode Server..."

    local vscode_pid=$(pgrep -f "code serve-web" | head -1)
    if [ -n "$vscode_pid" ]; then
        echo "[$timestamp] Stopping VSCode Server (PID: $vscode_pid)..."
        kill $vscode_pid 2>/dev/null
        sleep 3
        echo "[$timestamp] VSCode Server stopped, will be auto-restarted"
    else
        echo "[$timestamp] No running VSCode Server process found"
    fi
}

# Setup OpenClaw config with authentication if token is provided
setup_openclaw_config() {
    # Determine bind mode based on OPENCLAW_HOST
    # Use 'lan' for external access (0.0.0.0), 'loopback' for localhost only
    if [ "$OPENCLAW_HOST" = "0.0.0.0" ] || [ "$OPENCLAW_HOST" = "0.0.0.0/0" ] || [ "$OPENCLAW_HOST" = "" ]; then
        BIND_MODE="lan"
    else
        BIND_MODE="loopback"
    fi

    # If no token provided, generate a default one for lan mode
    if [ -z "$CLAW_GATEWAY_TOKEN" ] && [ "$BIND_MODE" = "lan" ]; then
        CLAW_GATEWAY_TOKEN=$(openssl rand -hex 32 2>/dev/null || echo "default-token-$(date +%s)")
        echo "[OpenClaw] Generated default token for lan mode: $CLAW_GATEWAY_TOKEN"
        echo "[OpenClaw] For production, set CLAW_GATEWAY_TOKEN environment variable"
    fi

    if [ -n "$CLAW_GATEWAY_TOKEN" ]; then
        echo "[OpenClaw] Setting up authentication..."
        cat > "$CONFIG_DIR/config.json" << CONFIG_EOF
{
  "gateway": {
    "mode": "local",
    "bind": "$BIND_MODE",
    "port": $OPENCLAW_PORT,
    "auth": {
      "mode": "token",
      "token": "$CLAW_GATEWAY_TOKEN"
    }
  }
}
CONFIG_EOF
        echo "[OpenClaw] Token authentication configured (bind mode: $BIND_MODE)"
        # Export for use in gateway command
        export CLAW_GATEWAY_TOKEN
    else
        echo "[WARNING] CLAW_GATEWAY_TOKEN not set - OpenClaw will start without authentication"
        echo "[WARNING] For security, please set CLAW_GATEWAY_TOKEN environment variable"
    fi
}

# Rotate logs on startup
rotate_log "$LOG_DIR/opencode.log"
rotate_log "$LOG_DIR/openclaw.log"
rotate_log "$LOG_DIR/path-state.log"

echo "Starting AI services..."
echo "[OpenCode] Host: $OPENCODE_HOST, Port: $OPENCODE_PORT"
echo "[OpenClaw] Host: $OPENCLAW_HOST, Port: $OPENCLAW_PORT"
echo "[Log] Directory: $LOG_DIR (retention: $LOG_RETENTION_DAYS days)"

# Setup OpenClaw config
setup_openclaw_config

# Check for pending updates on startup
if [ -f "$FLAG_DIR/opencode.update" ]; then
    echo "[OpenCode] Pending update detected, updating before start..."
    npm update -g @opencode-ai/cli 2>&1
    rm -f "$FLAG_DIR/opencode.update"
fi

if [ -f "$FLAG_DIR/openclaw.update" ]; then
    echo "[OpenClaw] Pending update detected, updating before start..."
    npm update -g openclaw 2>&1
    rm -f "$FLAG_DIR/openclaw.update"
fi

# Export OpenCode auth environment variables
export OPENCODE_SERVER_PASSWORD
export OPENCODE_SERVER_USERNAME
export CDN_PROXY_HOST

if [ "$HOLD_CONTAINER" = "true" ]; then
    echo "Starting VSCode Server..."

    HOST="${HOST:-0.0.0.0}"
    PORT="${PORT:-8585}"
    CMD="/usr/bin/code serve-web --host $HOST --port $PORT"

    if [ -n "$TOKEN" ]; then
        CMD="$CMD --connection-token $TOKEN"
    elif [ -n "$TOKEN_FILE" ]; then
        CMD="$CMD --connection-token-file $TOKEN_FILE"
    else
        CMD="$CMD --without-connection-token"
    fi

    if [ -n "$SERVER_DATA_DIR" ]; then
        CMD="$CMD --server-data-dir $SERVER_DATA_DIR"
    fi

    if [ -n "$SERVER_BASE_PATH" ]; then
        CMD="$CMD --server-base-path $SERVER_BASE_PATH"
    fi

    if [ -n "$SOCKET_PATH" ]; then
        CMD="$CMD --socket-path $SOCKET_PATH"
    fi

    CMD="$CMD --accept-server-license-terms"

    (
        while true; do
            echo "[VSCode Server] Starting..."

            if CDN_PROXY_HOST="$CDN_PROXY_HOST" USE_CDN_PROXY="$USE_CDN_PROXY" /app/vscode-wrapper.sh $CMD; then
                echo "[VSCode Server] Exited normally"
            else
                echo "[VSCode Server] Exited with error"
            fi

            echo "[VSCode Server] Restarting in 5 seconds..."
            sleep 5
        done
    ) &
    VSCODE_PID=$!
    echo "[VSCode Server] Started (PID: $VSCODE_PID)"
fi


# Start OpenCode with auto-restart, update checking and log rotation
(
    while true; do
        # Ensure log directory exists and is writable
        mkdir -p "$LOG_DIR" 2>/dev/null || {
            echo "[ERROR] Cannot create or access log directory: $LOG_DIR"
            sleep 5
            continue
        }

        # Rotate log before starting
        rotate_log "$LOG_DIR/opencode.log"

        echo "[OpenCode] Starting on $OPENCODE_HOST:$OPENCODE_PORT..."
        if [ -n "$OPENCODE_SERVER_PASSWORD" ]; then
            echo "[OpenCode] Authentication enabled (user: $OPENCODE_SERVER_USERNAME)"
        else
            echo "[WARNING] OPENCODE_SERVER_PASSWORD not set - OpenCode will be accessible without authentication"
        fi

        opencode serve --hostname "$OPENCODE_HOST" --port "$OPENCODE_PORT" >> "$LOG_DIR/opencode.log" 2>&1 &
        PID=$!
        
        # Monitor process and check for restart/update flags
        while kill -0 $PID 2>/dev/null; do
            if [ -f "$FLAG_DIR/opencode.restart" ]; then
                echo "[OpenCode] Restart flag detected, stopping..."
                rm -f "$FLAG_DIR/opencode.restart"
                kill $PID 2>/dev/null
                break
            fi
            if [ -f "$FLAG_DIR/opencode.update" ]; then
                echo "[OpenCode] Update flag detected, updating and restarting..."
                rm -f "$FLAG_DIR/opencode.update"
                kill $PID 2>/dev/null
                npm update -g @opencode-ai/cli 2>&1
                break
            fi
            sleep 2
        done
        
        wait $PID 2>/dev/null
        echo "[OpenCode] Process exited, restarting in 3 seconds..."
        sleep 3
    done
) &

# Start OpenClaw with auto-restart, update checking and log rotation
(
    # Export config directory for this subprocess
    export CONFIG_DIR
    export OPENCLAW_CONFIG_PATH="$CONFIG_DIR/config.json"
    
    while true; do
        # Ensure log directory exists and is writable
        mkdir -p "$LOG_DIR" 2>/dev/null || {
            echo "[ERROR] Cannot create or access log directory: $LOG_DIR"
            sleep 5
            continue
        }

        # Rotate log before starting
        rotate_log "$LOG_DIR/openclaw.log"

        echo "[OpenClaw] Starting gateway on $OPENCLAW_HOST:$OPENCLAW_PORT..."

        # Check if config exists
        if [ -f "$CONFIG_DIR/config.json" ]; then
            openclaw gateway >> "$LOG_DIR/openclaw.log" 2>&1 &
        else
            openclaw gateway --bind lan --port "$OPENCLAW_PORT" --allow-unconfigured >> "$LOG_DIR/openclaw.log" 2>&1 &
        fi
        PID=$!
        
        # Monitor process and check for restart/update flags
        while kill -0 $PID 2>/dev/null; do
            if [ -f "$FLAG_DIR/openclaw.restart" ]; then
                echo "[OpenClaw] Restart flag detected, stopping..."
                rm -f "$FLAG_DIR/openclaw.restart"
                kill $PID 2>/dev/null
                break
            fi
            if [ -f "$FLAG_DIR/openclaw.update" ]; then
                echo "[OpenClaw] Update flag detected, updating and restarting..."
                rm -f "$FLAG_DIR/openclaw.update"
                kill $PID 2>/dev/null
                npm update -g openclaw 2>&1
                break
            fi
            sleep 2
        done
        
        wait $PID 2>/dev/null
        echo "[OpenClaw] Gateway exited, restarting in 3 seconds..."
        sleep 3
    done
) &

# Start path state monitor if CDN proxy is enabled
if [ "$USE_CDN_PROXY" = "true" ]; then
    if [ "$HOLD_CONTAINER" = "true" ]; then
        echo "Starting path state monitor as container holder..."
        monitor_path_state
    else
        echo "Starting path state monitor..."
        monitor_path_state &
        PATH_STATE_PID=$!
        echo "Path state monitor started (PID: $PATH_STATE_PID)"
        echo "AI services started"
    fi
else
    if [ "$HOLD_CONTAINER" = "true" ]; then
        echo "HOLD_CONTAINER=true but USE_CDN_PROXY=$USE_CDN_PROXY"
        echo "Starting a simple keep-alive loop..."
        echo "AI services started"
        while true; do
            sleep 60
        done
    else
        echo "Path state monitor disabled (USE_CDN_PROXY=$USE_CDN_PROXY)"
        echo "Set USE_CDN_PROXY=true to enable automatic path state monitoring"
        echo "AI services started"
    fi
fi

