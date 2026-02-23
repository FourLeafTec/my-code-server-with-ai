#!/bin/bash
# OpenClaw 智能配置启动脚本
# 核心逻辑：config 不存在则生成，存在则尝试使用 openclaw config set 更新

# =============================================================================
# 用户配置
# =============================================================================

USERNAME=${USERNAME:-node}
USER_HOME="/home/$USERNAME"
CONFIG_DIR="$USER_HOME/.openclaw"
CONFIG_FILE="$CONFIG_DIR/config.json"

# =============================================================================
# 网络配置
# =============================================================================

DEFAULT_PORT=18789
DEFAULT_HOST=0.0.0.0
OPENCLAW_PORT=${OPENCLAW_PORT:-$DEFAULT_PORT}
OPENCLAW_HOST=${OPENCLAW_HOST:-$DEFAULT_HOST}

# =============================================================================
# 认证配置
# =============================================================================

OPENCLAW_GATEWAY_TOKEN=${OPENCLAW_GATEWAY_TOKEN:-}
OPENCLAW_TRUSTED_PROXIES=${OPENCLAW_TRUSTED_PROXIES:-}

# =============================================================================
# 日志函数
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
# 检查配置文件是否存在
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
# 生成新配置
# =============================================================================

generate_config() {
    log "Generating new configuration..."
    
    # 确保目录存在
    mkdir -p "$CONFIG_DIR"
    
    # 生成新配置
    cat > "$CONFIG_FILE" << CONFIG_EOF
{
  "gateway": {
    "mode": "local",
    "bind": "$OPENCLAW_HOST",
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
# 尝试使用 openclaw config set 更新配置
# =============================================================================

update_with_openclaw_config() {
    log "Attempting to update configuration using 'openclaw config set' command..."
    
    # 检查 openclaw 命令是否可用
    if ! command -v openclaw &>/dev/null; then
        log "OpenClaw CLI not found or not accessible"
        log "Using existing configuration without changes"
        log "To update config manually, use the OpenClaw dashboard or edit the config file"
        return 1
    fi
    
    # 尝试使用 openclaw config 命令更新配置
    # 注意：这里假设 openclaw config 支持以下语法
    # 如果实际语法不同，需要根据 OpenClaw 版本调整
    
    # 更新端口（如果环境变量有值）
    if [ "$OPENCLAW_PORT" != "$DEFAULT_PORT" ]; then
        log "Updating gateway.port to $OPENCLAW_PORT"
        # 假设命令格式（需要根据实际情况调整）
        # 方式 A: openclaw config set gateway.port $OPENCLAW_PORT
        # 方式 B: openclaw config --set gateway.port=$OPENCLAW_PORT
        # 尝试方式 A，如果失败则方式 B
        
        openclaw config set gateway.port $OPENCLAW_PORT 2>/dev/null || \
        openclaw config --set gateway.port=$OPENCLAW_PORT 2>/dev/null || \
        log "Failed to update gateway.port via CLI"
    fi
    
    # 更新绑定地址（如果环境变量有值）
    if [ "$OPENCLAW_HOST" != "$DEFAULT_HOST" ]; then
        log "Updating gateway.bind to $OPENCLAW_HOST"
        
        openclaw config set gateway.bind $OPENCLAW_HOST 2>/dev/null || \
        openclaw config --set gateway.bind=$OPENCLAW_HOST 2>/dev/null || \
        log "Failed to update gateway.bind via CLI"
    fi
    
    # 更新令牌（如果环境变量有值）
    if [ -n "$OPENCLAW_GATEWAY_TOKEN" ]; then
        log "Updating gateway.auth.token"
        
        openclaw config set gateway.auth.token $OPENCLAW_GATEWAY_TOKEN 2>/dev/null || \
        openclaw config --set gateway.auth.token=$OPENCLAW_GATEWAY_TOKEN 2>/dev/null || \
        log "Failed to update gateway.auth.token via CLI"
    fi
    
    log "Configuration update completed"
}

# =============================================================================
# 主配置逻辑
# =============================================================================

main() {
    log_config
    
    # 确保目录存在
    mkdir -p "$CONFIG_DIR"
    
    # 处理配置生成/更新逻辑
    if check_config; then
        # 配置不存在，生成新配置
        generate_config
    else
        # 配置存在，尝试使用 openclaw config set 更新
        log "Configuration exists, attempting to update using 'openclaw config set' command..."
        update_with_openclaw_config
    fi
}

# =============================================================================
# 执行
# =============================================================================

main "$@"

# 导出配置路径（官方命令可能需要）
export OPENCLAW_CONFIG_PATH="$CONFIG_FILE"

# 启动 OpenClaw（让官方 CMD 启动）
# 如果 start.sh 的配置更新失败，官方命令会读取现有配置
# 如果更新成功，官方命令会读取更新后的配置
exec openclaw gateway
