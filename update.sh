#!/bin/bash

SERVICE="${1:-all}"

echo "Updating AI services..."

case "$SERVICE" in
    opencode)
        echo "Updating OpenCode..."
        npm update -g @opencode-ai/cli
        echo "OpenCode updated."
        /app/restart.sh opencode
        ;;
    openclaw)
        echo "Updating OpenClaw..."
        npm update -g openclaw
        echo "OpenClaw updated."
        /app/restart.sh openclaw
        ;;
    all)
        echo "Updating all AI services..."
        echo "Updating OpenCode..."
        npm update -g @opencode-ai/cli
        echo "Updating OpenClaw..."
        npm update -g openclaw
        echo "All services updated."
        /app/restart.sh all
        ;;
    *)
        echo "Usage: $0 [opencode|openclaw|all]"
        echo "  opencode  - Update and restart only OpenCode"
        echo "  openclaw  - Update and restart only OpenClaw"
        echo "  all       - Update and restart all services (default)"
        exit 1
        ;;
esac
