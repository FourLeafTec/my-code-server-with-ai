#!/bin/bash

FLAG_DIR="/tmp"

echo "[VSCode Restart] Received restart signal..."

local vscode_pid=$(pgrep -f "code serve-web" | head -1)
if [ -n "$vscode_pid" ]; then
    echo "[VSCode Restart] Stopping VSCode Server (PID: $vscode_pid)..."
    kill $vscode_pid 2>/dev/null
    echo "[VSCode Restart] VSCode Server stopped, waiting for auto-restart..."
else
    echo "[VSCode Restart] No running VSCode Server process found"
fi
