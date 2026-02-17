#!/bin/bash

SERVICE="${1:-all}"
FLAG_DIR="/tmp"

case "$SERVICE" in
    opencode)
        echo "Restarting OpenCode..."
        touch "$FLAG_DIR/opencode.restart"
        ;;
    openclaw)
        echo "Restarting OpenClaw..."
        touch "$FLAG_DIR/openclaw.restart"
        ;;
    all)
        echo "Restarting all AI services..."
        touch "$FLAG_DIR/opencode.restart"
        touch "$FLAG_DIR/openclaw.restart"
        ;;
    *)
        echo "Usage: $0 [opencode|openclaw|all]"
        echo "  opencode  - Restart only OpenCode"
        echo "  openclaw  - Restart only OpenClaw"
        echo "  all       - Restart all services (default)"
        exit 1
        ;;
esac

echo "Restart signal sent. Services will restart shortly."
