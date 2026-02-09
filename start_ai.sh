#!/bin/bash

FLAG_DIR="/tmp"
LOG_DIR="/home/vscodeuser/.ai"
CONFIG_DIR="/home/vscodeuser/.openclaw"

# Default ports and hosts
OPENCODE_PORT="${OPENCODE_PORT:-4096}"
OPENCODE_HOST="${OPENCODE_HOST:-0.0.0.0}"
OPENCLAW_PORT="${OPENCLAW_PORT:-18789}"
OPENCLAW_HOST="${OPENCLAW_HOST:-0.0.0.0}"

# Authentication (optional)
OPENCODE_SERVER_PASSWORD="${OPENCODE_SERVER_PASSWORD:-}"
OPENCODE_SERVER_USERNAME="${OPENCODE_SERVER_USERNAME:-opencode}"
CLAW_GATEWAY_TOKEN="${CLAW_GATEWAY_TOKEN:-}"

# Log retention days (default: 3)
LOG_RETENTION_DAYS="${LOG_RETENTION_DAYS:-3}"

# Create directories
mkdir -p "$LOG_DIR"
mkdir -p "$CONFIG_DIR"

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

# Setup OpenClaw config with authentication if token is provided
setup_openclaw_config() {
    if [ -n "$CLAW_GATEWAY_TOKEN" ]; then
        echo "[OpenClaw] Setting up authentication..."
        cat > "$CONFIG_DIR/config.json" << CONFIG_EOF
{
  "gateway": {
    "bind": "$OPENCLAW_HOST",
    "port": $OPENCLAW_PORT,
    "auth": {
      "mode": "token",
      "token": "$CLAW_GATEWAY_TOKEN"
    }
  }
}
CONFIG_EOF
        echo "[OpenClaw] Token authentication configured"
    else
        echo "[WARNING] CLAW_GATEWAY_TOKEN not set - OpenClaw will use default configuration"
        echo "[WARNING] For security, please set CLAW_GATEWAY_TOKEN environment variable"
    fi
}

# Rotate logs on startup
rotate_log "$LOG_DIR/opencode.log"
rotate_log "$LOG_DIR/openclaw.log"

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

# Start OpenCode with auto-restart, update checking and log rotation
(
    while true; do
        # Rotate log before starting
        rotate_log "$LOG_DIR/opencode.log"
        
        echo "[OpenCode] Starting on $OPENCODE_HOST:$OPENCODE_PORT..."
        if [ -n "$OPENCODE_SERVER_PASSWORD" ]; then
            echo "[OpenCode] Authentication enabled (user: $OPENCODE_SERVER_USERNAME)"
        else
            echo "[WARNING] OPENCODE_SERVER_PASSWORD not set - OpenCode will be accessible without authentication"
        fi
        
        opencode serve --host "$OPENCODE_HOST" --port "$OPENCODE_PORT" >> "$LOG_DIR/opencode.log" 2>&1 &
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
    while true; do
        # Rotate log before starting
        rotate_log "$LOG_DIR/openclaw.log"
        
        echo "[OpenClaw] Starting gateway on $OPENCLAW_HOST:$OPENCLAW_PORT..."
        
        # Check if config exists
        if [ -f "$CONFIG_DIR/config.json" ]; then
            openclaw gateway >> "$LOG_DIR/openclaw.log" 2>&1 &
        else
            openclaw gateway --host "$OPENCLAW_HOST" --port "$OPENCLAW_PORT" >> "$LOG_DIR/openclaw.log" 2>&1 &
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

echo "AI services started in background"
