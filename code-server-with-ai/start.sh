#!/bin/bash

echo "Building and starting VS Code Server with AI assistants..."

docker compose build

if [ $? -eq 0 ]; then
    echo "Build successful, starting containers..."
    docker compose up -d
    echo "All containers started successfully"
    echo ""
    echo "=========================================="
    echo "Services:"
    echo "=========================================="
    echo "  - VS Code Server:"
    echo "    URL: http://localhost:${HOST_PORT:-8585}"
    echo "    Token: ${TOKEN:-sometoken}"
    echo ""
    echo "  - OpenCode AI:"
    echo "    URL: http://localhost:${OPENCODE_HOST_PORT:-4096}"
    [ -n "$OPENCODE_SERVER_PASSWORD" ] && echo "    Password: ${OPENCODE_SERVER_PASSWORD}"
    echo ""
    echo "  - OpenClaw AI:"
    echo "    URL: http://localhost:${OPENCLAW_HOST_PORT:-18789}"
    [ -n "$OPENCLAW_GATEWAY_TOKEN" ] && echo "    Token: ${OPENCLAW_GATEWAY_TOKEN}"
    echo "=========================================="
    echo ""
    echo "Useful commands:"
    echo "  - Stop all:  docker compose down"
    echo "  - Restart:   docker compose restart"
    echo "  - Logs:      docker compose logs -f [service-name]"
    echo "  - Status:    docker compose ps"
else
    echo "Build failed, please check error messages above"
    exit 1
fi
