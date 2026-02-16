#!/bin/bash

################################################################################
# VSCode Server Wrapper Script
#
# Description:
#   This script wraps the VSCode Server startup to ensure CDN proxy/local CDN
#   configuration is applied after VSCode updates itself. VSCode Server updates
#   on first access, so we need to patch the files AFTER the update happens.
#
# This wrapper:
#   - Checks if CDN proxy or local CDN mode is enabled
#   - Applies the appropriate patches BEFORE starting VSCode Server
#   - Tracks patch state to avoid unnecessary re-patching
#
# Usage:
#   This script is called by start.sh to wrap the code serve-web command
################################################################################

set -e

echo "=========================================="
echo "VSCode Server Wrapper"
echo "=========================================="

STATE_DIR="$HOME/.vscode-server-patch-state"
PATCH_STATE_FILE="$STATE_DIR/patched"
VERSION_FILE="$STATE_DIR/version"
CLI_PATCH_STATE_FILE="$STATE_DIR/cli-hashes-patched"

mkdir -p "$STATE_DIR"

get_cli_hashes() {
    local cli_web_dir="$HOME/.vscode/cli/serve-web"
    if [ -d "$cli_web_dir" ]; then
        find "$cli_web_dir" -maxdepth 1 -type d -name '[a-f0-9]*' -exec basename {} \; 2>/dev/null | sort
    else
        echo ""
    fi
}

hash_needs_patching() {
    local hash="$1"

    if [ ! -f "$CLI_PATCH_STATE_FILE" ]; then
        return 0
    fi

    if ! grep -qx "$hash" "$CLI_PATCH_STATE_FILE" 2>/dev/null; then
        return 0
    fi

    return 1
}

mark_hash_patched() {
    local hash="$1"
    mkdir -p "$STATE_DIR"
    if ! grep -qx "$hash" "$CLI_PATCH_STATE_FILE" 2>/dev/null; then
        echo "$hash" >> "$CLI_PATCH_STATE_FILE"
        sort -u "$CLI_PATCH_STATE_FILE" -o "${CLI_PATCH_STATE_FILE}.tmp" && mv "${CLI_PATCH_STATE_FILE}.tmp" "$CLI_PATCH_STATE_FILE"
        echo "  ✓ Hash $hash marked as patched"
    fi
}

need_patch() {
    local mode="$1"

    if [ ! -f "$PATCH_STATE_FILE" ]; then
        echo "  No patch state found, patching required"
        return 0
    fi

    local last_patched_mode=$(cat "$PATCH_STATE_FILE" 2>/dev/null || echo "")
    if [ "$last_patched_mode" != "$mode" ]; then
        echo "  Mode changed from '$last_patched_mode' to '$mode', re-patching required"
        return 0
    fi

    local vscode_server_dir="$HOME/.vscode-server"
    if [ ! -d "$vscode_server_dir" ]; then
        echo "  VSCode Server directory not found yet, will patch when available"
        return 0
    fi

    if [ -f "$VERSION_FILE" ]; then
        local last_patch_time=$(stat -c %Y "$VERSION_FILE" 2>/dev/null || echo 0)
        local latest_mod_time=$(find "$vscode_server_dir" -type f \( -name "*.js" -o -name "*.mjs" \) -printf '%T@\n' 2>/dev/null | sort -n | tail -1)

        if [ -n "$latest_mod_time" ]; then
            local latest_mod_int=${latest_mod_time%.*}
            if [ "$latest_mod_int" -gt "$last_patch_time" ]; then
                echo "  VSCode Server files modified since last patch, re-patching required"
                return 0
            fi
        fi
    fi

    echo "  Already patched, no changes needed"
    return 1
}

mark_patched() {
    local mode="$1"
    echo "$mode" > "$PATCH_STATE_FILE"
    touch "$VERSION_FILE"
    echo "  Patch state updated: mode=$mode"
}

if [ "$USE_CDN_PROXY" = "true" ]; then
    echo ""
    echo "Checking CDN proxy patch state..."

    CLI_WEB_DIR="$HOME/.vscode/cli/serve-web"
    NEW_HASH_FOUND=0

    if [ -d "$CLI_WEB_DIR" ]; then
        echo "Checking CLI serve-web directories..."
        echo ""

        CURRENT_HASHES=$(get_cli_hashes)
        if [ -n "$CURRENT_HASHES" ]; then
            echo "Found hash directories:"
            for hash in $CURRENT_HASHES; do
                if hash_needs_patching "$hash"; then
                    echo "  → New/unpatched hash: $hash"
                    NEW_HASH_FOUND=1
                else
                    echo "  ✓ Already patched: $hash"
                fi
            done
            echo ""
        else
            echo "ℹ️  No CLI serve-web directories found yet"
        fi
    fi

    if [ "$NEW_HASH_FOUND" -eq 1 ] || need_patch "cdn-proxy"; then
        echo "Applying CDN proxy configuration..."
        if CDN_PROXY_HOST="$CDN_PROXY_HOST" /app/fix-cdn-proxy.sh; then
            mark_patched "cdn-proxy"

            if [ -d "$CLI_WEB_DIR" ]; then
                echo ""
                echo "Marking CLI hashes as patched..."
                for hash in $(get_cli_hashes); do
                    mark_hash_patched "$hash"
                done
            fi

            echo "✅ CDN proxy configuration applied"
        else
            echo "⚠️  CDN proxy configuration failed, continuing with default configuration"
        fi
    else
        echo "✅ CDN proxy already configured and up to date"
    fi
    echo ""
fi

echo "=========================================="
echo "Starting VSCode Server..."
echo "=========================================="

exec /usr/bin/code "$@"
