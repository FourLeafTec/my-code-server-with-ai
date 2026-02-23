#!/bin/bash

################################################################################
# VS Code Server CDN Proxy Fix Script (Minimal Version)
#
# Description:
#   This script patches ONLY the critical VS Code Server files that contain
#   functional CDN URLs affecting runtime behavior.
#
#   Files patched:
#   - product.json (11 CDN URLs - extensions, language packs, webviews)
#   - workbench.html (1 CDN URL - extension loading)
#   - CLI serve-web files (dynamic path, 5+ JS files + product.json)
#
#   Files NOT patched (debugging only):
#   - JavaScript source map references (debugging only)
#
# Usage:
#   docker exec -it my-code-server-with-cdn-fix /app/fix-cdn-proxy-minimal.sh
#
# Author: Auto-generated for my-code-server-with-cdn-fix
################################################################################

USERNAME=${USERNAME:-coder}
USER_HOME="/home/coder"

set -e

echo "=========================================="
echo "VS Code Server CDN Proxy Fix (Minimal)"
echo "=========================================="
echo ""
echo "Patching ONLY critical files (product.json, workbench.html)"
echo "Skipping non-critical files (source maps - debugging only)"
echo ""

if [ -z "$CDN_PROXY_HOST" ]; then
    echo "❌ Error: CDN_PROXY_HOST environment variable is required when USE_CDN_PROXY=true"
    echo ""
    echo "Please set CDN_PROXY_HOST to your reverse proxy host."
    echo "Example: CDN_PROXY_HOST=my-vscode-server.domain.com"
    echo ""
    exit 1
fi

PROXY_UNPKG_URL="https://${CDN_PROXY_HOST}/proxy-unpkg"
PROXY_CDN_URL="https://${CDN_PROXY_HOST}/proxy-cdn"

echo "Using CDN proxy host: $CDN_PROXY_HOST"
echo "Unpkg URL: $PROXY_UNPKG_URL"
echo "CDN URL: $PROXY_CDN_URL"
echo ""

# Ensure write permissions for /usr/share/code
if [ ! -w "/usr/share/code" ]; then
    echo "Fixing permissions for /usr/share/code..."
    sudo chmod -R u+w /usr/share/code
fi
echo ""

# Initialize CLI files counter
CLI_FILES_PATCHED=0
CLI_URLS_REPLACED=0
WORKBENCH_URLS_REPLACED=0
PRE_INDEX_URLS_REPLACED=0
PRODUCT_URLS_REPLACED=0

# ============================================================================
# PATCH PRODUCT.JSON
# ============================================================================

PRODUCT_JSON="/usr/share/code/resources/app/product.json"

if [ -f "$PRODUCT_JSON" ]; then
    echo "=========================================="
    echo "Patching product.json"
    echo "=========================================="

    # Backup original
    if [ ! -f "$PRODUCT_JSON.backup" ]; then
        sudo cp "$PRODUCT_JSON" "$PRODUCT_JSON.backup"
        echo "✓ Backup created: $PRODUCT_JSON.backup"
    else
        echo "✓ Backup already exists: $PRODUCT_JSON.backup"
    fi

    echo ""
    echo "Applying domain-based CDN replacements..."

    # unpkg.net replacements
    echo "  → Replacing www.vscode-unpkg.net → $PROXY_UNPKG_URL"
    sudo sed -i "s|https://www\.vscode-unpkg\.net|$PROXY_UNPKG_URL|g" "$PRODUCT_JSON"
    sudo sed -i "s|https://{publisher}\.vscode-unpkg\.net|$PROXY_UNPKG_URL|g" "$PRODUCT_JSON"

    # vscode-cdn.net replacements
    echo "  → Replacing main.vscode-cdn.net → $PROXY_CDN_URL"
    sudo sed -i "s|https://main\.vscode-cdn\.net|$PROXY_CDN_URL|g" "$PRODUCT_JSON"
    sudo sed -i "s|https://{{uuid}}\.vscode-cdn\.net|$PROXY_CDN_URL|g" "$PRODUCT_JSON"

    PRODUCT_URLS_REPLACED=$(grep -c "$PROXY_UNPKG_URL\|$PROXY_CDN_URL" "$PRODUCT_JSON" 2>/dev/null || true)
    PRODUCT_URLS_REPLACED=${PRODUCT_URLS_REPLACED:-0}
    echo ""
    echo "✅ product.json patched successfully!"
    echo "   CDN URLs replaced: $PRODUCT_URLS_REPLACED"
else
    echo "⚠️  WARNING: $PRODUCT_JSON not found"
    echo "   VS Code Server may not be installed yet"
    exit 1
fi

# ============================================================================
# PATCH WORKBENCH.HTML
# ============================================================================

WORKBENCH_HTML="/usr/share/code/resources/app/out/vs/code/electron-browser/workbench/workbench.html"

if [ -f "$WORKBENCH_HTML" ]; then
    echo ""
    echo "=========================================="
    echo "Patching workbench.html"
    echo "=========================================="

    # Backup original
    if [ ! -f "$WORKBENCH_HTML.backup" ]; then
        sudo cp "$WORKBENCH_HTML" "$WORKBENCH_HTML.backup"
        echo "✓ Backup created: $WORKBENCH_HTML.backup"
    else
        echo "✓ Backup already exists: $WORKBENCH_HTML.backup"
    fi

    # Check if file contains unpkg URLs
    if grep -q "vscode-unpkg\.net" "$WORKBENCH_HTML" 2>/dev/null; then
        echo ""
        echo "  → Replacing vscode-unpkg.net → $PROXY_UNPKG_URL"
        sudo sed -i "s|https://[^/]*vscode-unpkg\.net|$PROXY_UNPKG_URL|g" "$WORKBENCH_HTML"
        WORKBENCH_URLS_REPLACED=$(grep -c "$PROXY_UNPKG_URL" "$WORKBENCH_HTML" 2>/dev/null || true)
        WORKBENCH_URLS_REPLACED=${WORKBENCH_URLS_REPLACED:-0}
        echo ""
        echo "✅ workbench.html patched successfully!"
        echo "   CDN URLs replaced: $WORKBENCH_URLS_REPLACED"
    else
        echo ""
        echo "ℹ️  No CDN URLs found in workbench.html (already patched)"
    fi
else
    echo ""
    echo "⚠️  WARNING: $WORKBENCH_HTML not found"
fi

# ============================================================================
# PATCH PRE/INDEX.HTML (WEBVIEW PRELOADER)
# ============================================================================

PRE_INDEX_HTML="/usr/share/code/resources/app/out/vs/workbench/contrib/webview/browser/pre/index.html"

if [ -f "$PRE_INDEX_HTML" ]; then
    echo ""
    echo "=========================================="
    echo "Patching pre/index.html (webview preloader)"
    echo "=========================================="

    # Backup original
    if [ ! -f "$PRE_INDEX_HTML.backup" ]; then
        sudo cp "$PRE_INDEX_HTML" "$PRE_INDEX_HTML.backup"
        echo "✓ Backup created: $PRE_INDEX_HTML.backup"
    else
        echo "✓ Backup already exists: $PRE_INDEX_HTML.backup"
    fi

    # Check if file contains unpkg URLs
    if grep -q "vscode-unpkg\.net" "$PRE_INDEX_HTML" 2>/dev/null; then
        echo ""
        echo "  → Replacing vscode-unpkg.net → $PROXY_UNPKG_URL"
        sudo sed -i "s|https://[^/]*vscode-unpkg\.net|$PROXY_UNPKG_URL|g" "$PRE_INDEX_HTML"
        PRE_INDEX_URLS_REPLACED=$(grep -c "$PROXY_UNPKG_URL" "$PRE_INDEX_HTML" 2>/dev/null || true)
        PRE_INDEX_URLS_REPLACED=${PRE_INDEX_URLS_REPLACED:-0}
        echo ""
        echo "✅ pre/index.html patched successfully!"
        echo "   CDN URLs replaced: $PRE_INDEX_URLS_REPLACED"
    else
        echo ""
        echo "ℹ️  No CDN URLs found in pre/index.html (already patched)"
    fi
else
    echo ""
    echo "⚠️  WARNING: $PRE_INDEX_HTML not found"
    echo "   VS Code webview preloader may not be installed yet"
fi

# ============================================================================
# PATCH DYNAMIC CLI SERVE-WEB FILES
# ============================================================================

HASH_DIR=""

echo ""
echo "=========================================="
echo "Patching CLI Serve-Web Files (Dynamic Path)"
echo "=========================================="

# Find the dynamic hash directory (pattern: [a-f0-9]{40})
CLI_WEB_DIR="$USER_HOME/.vscode/cli/serve-web"
HASH_DIR=$(find "$CLI_WEB_DIR" -maxdepth 1 -type d -name '[a-f0-9]*' 2>/dev/null | head -1)

if [ -n "$HASH_DIR" ] && [ -d "$HASH_DIR" ]; then
    echo "Found dynamic目录: $(basename "$HASH_DIR")"
    echo ""

    # Ensure write permissions
    if [ ! -w "$HASH_DIR" ]; then
        echo "Fixing permissions for $HASH_DIR..."
        sudo chmod -R u+w "$HASH_DIR"
    fi

    echo "Searching for JavaScript files containing CDN URLs..."
    echo ""

    # Find all JS files containing CDN URLs, excluding source-map references
    # Store in temp file to avoid subshell issue with pipes
    TEMP_FILE_LIST=$(mktemp)
    find "$HASH_DIR" -type f -name "*.js" 2>/dev/null | while IFS= read -r file; do
        if grep -v "sourceMappingURL" "$file" 2>/dev/null | grep -q "vscode-cdn\.net\|vscode-unpkg\.net"; then
            echo "$file"
        fi
    done > "$TEMP_FILE_LIST"

    while IFS= read -r file; do
        if [ -z "$file" ]; then
            continue
        fi

        FILE_CHANGED=0
        FILENAME=$(basename "$file")

        BACKUP_EXISTS=0
        if [ ! -f "$file.backup" ]; then
            sudo cp "$file" "$file.backup"
            echo "  ✓ Backup created: $FILENAME"
        else
            BACKUP_EXISTS=1
        fi

        echo "  → Patching: $FILENAME"

        sudo sed -i "s|https://www\.vscode-unpkg\.net|$PROXY_UNPKG_URL|g" "$file"
        sudo sed -i "s|https://[^/]*vscode-unpkg\.net|$PROXY_UNPKG_URL|g" "$file"
        sudo sed -i "s|https://{publisher}\.vscode-unpkg\.net|$PROXY_UNPKG_URL|g" "$file"

        sudo sed -i "s|https://main\.vscode-cdn\.net|$PROXY_CDN_URL|g" "$file"
        sudo sed -i "s|https://{{uuid}}\.vscode-cdn\.net|$PROXY_CDN_URL|g" "$file"
        sudo perl -pi -e "s|https://vscode-cdn\.net|$PROXY_CDN_URL|g" "$file"
        sudo perl -pi -e "s|https://[^/]+\.vscode-cdn\.net|$PROXY_CDN_URL|g" "$file"
        sudo sed -i 's|"vscode-cdn\.net"|"$PROXY_CDN_URL"|g' "$file"
        sudo sed -i 's|"vscode-unpkg\.net"|"$PROXY_UNPKG_URL"|g' "$file"

        FILE_URLS_REPLACED=$(grep -v "sourceMappingURL" "$file" 2>/dev/null | grep -c "$PROXY_UNPKG_URL\|$PROXY_CDN_URL" || true)
        FILE_URLS_REPLACED=${FILE_URLS_REPLACED:-0}
        CLI_URLS_REPLACED=$((CLI_URLS_REPLACED + FILE_URLS_REPLACED))

        if grep -v "sourceMappingURL" "$file" 2>/dev/null | grep -q "vscode-cdn\.net\|vscode-unpkg\.net"; then
            echo "    ⚠️  Some CDN URLs remain in $FILENAME"
        else
            if [ "$BACKUP_EXISTS" -eq 1 ]; then
                echo "    ✅ All CDN URLs replaced (backup existed)"
            else
                echo "    ✅ All CDN URLs replaced"
            fi
            FILE_CHANGED=1
        fi

        if [ "$FILE_CHANGED" -eq 1 ]; then
            CLI_FILES_PATCHED=$((CLI_FILES_PATCHED + 1))
        fi
    done < "$TEMP_FILE_LIST"

    rm -f "$TEMP_FILE_LIST"

    echo ""
    echo "✅ CLI serve-web JavaScript files patched: $CLI_FILES_PATCHED"
    echo "   Total CDN URLs replaced: $CLI_URLS_REPLACED"

    # Patch CLI product.json
    CLI_PRODUCT_JSON="$HASH_DIR/product.json"
    if [ -f "$CLI_PRODUCT_JSON" ]; then
        echo ""
        echo "Patching CLI product.json..."

        if [ ! -f "$CLI_PRODUCT_JSON.backup" ]; then
            sudo cp "$CLI_PRODUCT_JSON" "$CLI_PRODUCT_JSON.backup"
            echo "  ✓ Backup created: product.json"
        fi

        sudo sed -i "s|https://www\.vscode-unpkg\.net|$PROXY_UNPKG_URL|g" "$CLI_PRODUCT_JSON"
        sudo sed -i "s|https://[^/]*vscode-unpkg\.net|$PROXY_UNPKG_URL|g" "$CLI_PRODUCT_JSON"
        sudo sed -i "s|https://{publisher}\.vscode-unpkg\.net|$PROXY_UNPKG_URL|g" "$CLI_PRODUCT_JSON"

        sudo sed -i "s|https://main\.vscode-cdn\.net|$PROXY_CDN_URL|g" "$CLI_PRODUCT_JSON"
        sudo sed -i "s|https://{{uuid}}\.vscode-cdn\.net|$PROXY_CDN_URL|g" "$CLI_PRODUCT_JSON"

        CLI_PRODUCT_URLS_REPLACED=$(grep -c "$PROXY_UNPKG_URL\|$PROXY_CDN_URL" "$CLI_PRODUCT_JSON" 2>/dev/null || true)
        CLI_PRODUCT_URLS_REPLACED=${CLI_PRODUCT_URLS_REPLACED:-0}
        CLI_URLS_REPLACED=$((CLI_URLS_REPLACED + CLI_PRODUCT_URLS_REPLACED))

        echo "  ✅ CLI product.json patched"
        echo "   CDN URLs replaced: $CLI_PRODUCT_URLS_REPLACED"
    fi
    
    # Patch all JavaScript files in CLI directory
    echo ""
    echo "Patching all JavaScript files in CLI directory..."
    
    find "$HASH_DIR" -name "*.js" -type f -exec grep -l "vscode-cdn\.net\|vscode-unpkg\.net" {} \; 2>/dev/null | while IFS= read -r file; do
        if [ -z "$file" ]; then
            continue
        fi
        
        cdn_count=$(grep -c "vscode-cdn\.net\|vscode-unpkg\.net" "$file" 2>/dev/null || true)
        
        if [ "$cdn_count" -gt 0 ]; then
            FILENAME=$(basename "$file")
            
            BACKUP_EXISTS=0
            if [ ! -f "$file.backup" ]; then
                sudo cp "$file" "$file.backup"
                BACKUP_EXISTS=1
            fi
            
            # Patch all CDN URL patterns
            sudo sed -i "s|https://main\.vscode-cdn\.net|$PROXY_CDN_URL|g" "$file"
            sudo sed -i "s|https://{{uuid}}\.vscode-cdn\.net|$PROXY_CDN_URL|g" "$file"
            sudo sed -i "s|https://www\.vscode-unpkg\.net|$PROXY_UNPKG_URL|g" "$file"
            sudo sed -i "s|https://[^/]*vscode-unpkg\.net|$PROXY_UNPKG_URL|g" "$file"
            
            CLI_FILES_PATCHED=$((CLI_FILES_PATCHED + 1))
        fi
    done
    
    echo "  ✅ All JavaScript files patched: $CLI_FILES_PATCHED"
else
    echo "ℹ️  No dynamic hash directory found in $CLI_WEB_DIR"
    echo "   CLI serve-web files may not be installed yet"
fi

# ============================================================================
# VERIFICATION
# ============================================================================

echo ""
echo "=========================================="
echo "Verification"
echo "=========================================="

PRODUCT_JSON_CDN_COUNT=0
WORKBENCH_HTML_CDN_COUNT=0
PRE_INDEX_HTML_CDN_COUNT=0
CLI_FILES_CDN_COUNT=0

if [ -f "$PRODUCT_JSON" ]; then
    PRODUCT_JSON_CDN_COUNT=$(grep -c 'vscode-cdn\.net\|vscode-unpkg\.net' "$PRODUCT_JSON" 2>/dev/null || true)
    PRODUCT_JSON_CDN_COUNT=${PRODUCT_JSON_CDN_COUNT:-0}
fi

if [ -f "$WORKBENCH_HTML" ]; then
    WORKBENCH_HTML_CDN_COUNT=$(grep -c 'vscode-unpkg\.net' "$WORKBENCH_HTML" 2>/dev/null || true)
    WORKBENCH_HTML_CDN_COUNT=${WORKBENCH_HTML_CDN_COUNT:-0}
fi

if [ -f "$PRE_INDEX_HTML" ]; then
    PRE_INDEX_HTML_CDN_COUNT=$(grep -c 'vscode-unpkg\.net' "$PRE_INDEX_HTML" 2>/dev/null || true)
    PRE_INDEX_HTML_CDN_COUNT=${PRE_INDEX_HTML_CDN_COUNT:-0}
fi

if [ -n "$HASH_DIR" ] && [ -d "$HASH_DIR" ]; then
    # Count remaining CDN URLs in CLI files (excluding source-map)
    CLI_FILES_CDN_COUNT=$(find "$HASH_DIR" -type f -name "*.js" -exec grep -v "sourceMappingURL" {} \; 2>/dev/null | grep -c 'vscode-cdn\.net\|vscode-unpkg\.net' || true)
    CLI_FILES_CDN_COUNT=${CLI_FILES_CDN_COUNT:-0}

    # Check CLI product.json
    CLI_PRODUCT_JSON="$HASH_DIR/product.json"
    if [ -f "$CLI_PRODUCT_JSON" ]; then
        CLI_PRODUCT_CDN_COUNT=$(grep -c 'vscode-cdn\.net\|vscode-unpkg\.net' "$CLI_PRODUCT_JSON" 2>/dev/null || true)
        CLI_PRODUCT_CDN_COUNT=${CLI_PRODUCT_CDN_COUNT:-0}
        CLI_FILES_CDN_COUNT=$((CLI_FILES_CDN_COUNT + CLI_PRODUCT_CDN_COUNT))
    fi
fi

echo ""
echo "product.json remaining CDN URLs: $PRODUCT_JSON_CDN_COUNT"
echo "workbench.html remaining CDN URLs: $WORKBENCH_HTML_CDN_COUNT"
echo "pre/index.html remaining CDN URLs: $PRE_INDEX_HTML_CDN_COUNT"
echo "CLI serve-web files remaining CDN URLs: $CLI_FILES_CDN_COUNT"
echo ""

if [ "$PRODUCT_JSON_CDN_COUNT" -eq 0 ] && [ "$WORKBENCH_HTML_CDN_COUNT" -eq 0 ] && [ "$PRE_INDEX_HTML_CDN_COUNT" -eq 0 ] && [ "$CLI_FILES_CDN_COUNT" -eq 0 ]; then
    echo "✅ All critical files patched successfully!"
else
    echo "❌ Some CDN URLs remain. Please check the errors above."
    exit 1
fi

# ============================================================================
# SUMMARY
# ============================================================================

echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="
echo "Critical files patched: 4 types"
echo "  - product.json ($PRODUCT_URLS_REPLACED URLs)"
echo "  - workbench.html ($WORKBENCH_URLS_REPLACED URLs)"
echo "  - pre/index.html ($PRE_INDEX_URLS_REPLACED URLs)"
echo "  - CLI serve-web files ($CLI_FILES_PATCHED files, $CLI_URLS_REPLACED URLs, excluding source-map)"
echo ""
echo "Total CDN URLs replaced: $((PRODUCT_URLS_REPLACED + WORKBENCH_URLS_REPLACED + PRE_INDEX_URLS_REPLACED + CLI_URLS_REPLACED))"
echo ""
echo "Non-critical files skipped:"
echo "  - JavaScript source map references (debugging only)"
echo ""

# ============================================================================
# NEXT STEPS
# ============================================================================

echo "=========================================="
echo "Next Steps: Configure Nginx Reverse Proxy"
echo "=========================================="
echo ""
echo "IMPORTANT: Configure your reverse proxy (e.g., Nginx) to forward"
echo "the /proxy-unpkg and /proxy-cdn paths to the original CDN URLs."
echo ""
echo "Your CDN proxy host is: $CDN_PROXY_HOST"
echo ""
echo "Required Nginx configuration on $CDN_PROXY_HOST:"
echo ""
echo "  location /proxy-unpkg/ {"
echo "      rewrite ^/proxy-unpkg/(.*)$ /\$1 break;"
echo "      proxy_pass https://www.vscode-unpkg.net;"
echo "      proxy_set_header Host www.vscode-unpkg.net;"
echo "      proxy_ssl_server_name on;"
echo "      proxy_ssl_protocols TLSv1.2 TLSv1.3;"
echo "  }"
echo ""
echo "  location /proxy-cdn/ {"
echo "      rewrite ^/proxy-cdn/(.*)$ /\$1 break;"
echo "      proxy_pass https://main.vscode-cdn.net;"
echo "      proxy_set_header Host main.vscode-cdn.net;"
echo "      proxy_ssl_server_name on;"
echo "      proxy_ssl_protocols TLSv1.2 TLSv1.3;"
echo "  }"
echo ""
echo "=========================================="
echo ""
echo "IMPORTANT: Configure your reverse proxy (e.g., Nginx) to forward"
echo "the proxy paths to the original CDN URLs."
echo ""
echo "Required Nginx configuration:"
echo ""
echo "  location /proxy-unpkg/ {"
echo "      # 将请求转发到目标服务器"
echo "      # 注意：末尾的 / 很重要，它会把 "/proxy-unpkg/" 替换为 "/""
echo "      proxy_pass https://www.vscode-unpkg.net/;"
echo "      # 常用代理请求头设置"
echo "      proxy_set_header Host www.vscode-unpkg.net;"
echo "      proxy_set_header X-Real-IP $remote_addr;"
echo "      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;"
echo "      proxy_set_header X-Forwarded-Proto $scheme;"
echo "      # 解决可能出现的重定向问题"
echo "      proxy_redirect off;"
echo "  }"
echo ""
echo "  location /proxy-cdn/ {"
echo "      # 将请求转发到目标服务器"
echo "      # 注意：末尾的 / 很重要，它会把 "/proxy-cdn/" 替换为 "/""
echo "      proxy_pass https://main.vscode-cdn.net/;"
echo "      # 常用代理请求头设置"
echo "      proxy_set_header Host main.vscode-cdn.net;"
echo "      proxy_set_header X-Real-IP $remote_addr;"
echo "      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;"
echo "      proxy_set_header X-Forwarded-Proto $scheme;"
echo "      # 解决可能出现的重定向问题"
echo "      proxy_redirect off;"
echo "  }"
echo ""
echo "=========================================="
echo "Script completed successfully!"
echo "=========================================="
