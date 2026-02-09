# VS Code Server Docker 配置

基于 Debian 的 VS Code Server，支持 WebSocket、完整插件功能（包括 GitHub Copilot）。

功能特性：VS Code Server + OpenCode AI + OpenClaw AI 助手，WebSocket 支持，tini 进程管理。

## 快速开始

```bash
# 拉取镜像并运行
docker pull ghcr.io/nerasse/my-code-server:main
docker run -d -p 8585:8585 -e TOKEN=yourtoken ghcr.io/nerasse/my-code-server:main

# 或者用 docker-compose
docker compose up -d
```

访问地址：`http://localhost:8585?tkn=yourtoken`

## 安装

### 准备工作

- Docker
- Docker Compose（可选）
- 反向代理（生产环境可选）

### 方案一：使用预构建镜像

```bash
docker pull ghcr.io/nerasse/my-code-server:main
```

### 方案二：本地构建

```bash
# 推荐用 buildx
docker buildx build -t my-code-server:main .

# 或者用传统方式
docker build -t my-code-server:main .
```

## 使用方法

### Docker Compose（推荐）

**基础启动：**
```bash
docker compose up -d
```

**自定义配置（.env 文件）：**
```env
HOST_PORT=9090
CONTAINER_PORT=8585
TOKEN=mysecuretoken
PUID=1000
PGID=1000
```

**数据持久化：**
取消 `docker-compose.yml` 中 volumes 部分的注释：
```yaml
volumes:
  - /path/to/your/data:/home/vscodeuser
```

### Docker 直接运行

**基础命令：**
```bash
docker run -d -p 8585:8585 \
  -e PORT=8585 \
  -e TOKEN=sometoken \
  my-code-server:main
```

**带数据卷和自定义用户ID：**
```bash
docker run -d -p 8585:8585 \
  -e PORT=8585 \
  -e TOKEN=sometoken \
  -e PUID=$(id -u) \
  -e PGID=$(id -g) \
  -v /path/to/your/data:/home/vscodeuser \
  my-code-server:main
```

## 配置选项

### 环境变量

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `PORT` | VS Code Server 监听端口 | `8585` |
| `HOST` | 监听地址 | `0.0.0.0` |
| `TOKEN` | 连接认证 token | 无 |
| `TOKEN_FILE` | 包含 token 的文件路径 | - |
| `PUID` | 用户 ID（用于数据卷权限） | `1000` |
| `PGID` | 组 ID（用于数据卷权限） | `1000` |
| `SERVER_DATA_DIR` | 服务器数据存储目录 | - |
| `SERVER_BASE_PATH` | Web UI 基础路径 | - |
| `SOCKET_PATH` | Socket 文件路径 | - |
| `VERBOSE` | 启用详细输出 | `false` |
| `LOG_LEVEL` | 日志级别 | - |
| `CLI_DATA_DIR` | CLI 元数据目录 | - |
| `OPENCODE_PORT` | OpenCode 服务端口 | `4096` |
| `OPENCODE_HOST` | OpenCode 绑定地址 | `0.0.0.0` |
| `OPENCODE_SERVER_PASSWORD` | OpenCode web 密码（推荐） | - |
| `OPENCODE_SERVER_USERNAME` | OpenCode web 用户名 | `opencode` |
| `OPENCLAW_PORT` | OpenClaw 网关端口 | `18789` |
| `OPENCLAW_HOST` | OpenClaw 绑定地址 | `0.0.0.0` |
| `CLAW_GATEWAY_TOKEN` | OpenClaw 网关 token（推荐） | - |
| `LOG_RETENTION_DAYS` | 日志保留天数 | `3` |

### Docker Compose 变量

可以用环境变量或 `.env` 文件配置：

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `HOST_PORT` | 宿主机端口映射 | `8585` |
| `CONTAINER_PORT` | 容器端口 | `8585` |
| `TOKEN` | 认证 token | `sometoken` |
| `PUID` | 用户 ID | `1000` |
| `PGID` | 组 ID | `1000` |
| `OPENCODE_HOST_PORT` | OpenCode 宿主机端口 | `4096` |
| `OPENCODE_PORT` | OpenCode 容器端口 | `4096` |
| `OPENCLAW_HOST_PORT` | OpenClaw 宿主机端口 | `18789` |
| `OPENCLAW_PORT` | OpenClaw 容器端口 | `18789` |

### 自定义 UID/GID

为了避免数据卷的权限问题，容器支持动态调整 UID/GID：

**docker-compose 方式：** 设置 `PUID` 和 `PGID` 环境变量
**docker run 方式：** 使用 `-e PUID=$(id -u) -e PGID=$(id -g)`

容器启动时会自动调整用户权限。

## AI 服务（OpenCode & OpenClaw）

这个镜像预装了 AI 编程助手，作为后台服务运行。

### 可用服务

| 服务 | 说明 | 默认端口 | CLI 命令 |
|------|------|----------|----------|
| **OpenCode** | 带 TUI 的 AI 编程助手 | `4096` | `opencode` |
| **OpenClaw** | 个人 AI 助手网关 | `18789` | `openclaw` |

### 端口配置

通过环境变量配置服务端口：

```yaml
# docker-compose.yml
environment:
  - OPENCODE_HOST=0.0.0.0        # OpenCode 绑定地址
  - OPENCODE_PORT=4096           # OpenCode 服务端口
  - OPENCLAW_HOST=0.0.0.0        # OpenClaw 绑定地址
  - OPENCLAW_PORT=18789          # OpenClaw 网关端口
  - LOG_RETENTION_DAYS=3         # 日志保留天数（可选）

ports:
  - "8585:8585"                  # VS Code Server
  - "4096:4096"                  # OpenCode
  - "18789:18789"                # OpenClaw
```

或者用 `.env` 文件：
```env
OPENCODE_HOST=0.0.0.0
OPENCODE_PORT=4096
OPENCLAW_HOST=0.0.0.0
OPENCLAW_PORT=18789
OPENCODE_HOST_PORT=4096
OPENCLAW_HOST_PORT=18789
LOG_RETENTION_DAYS=3
```

### 认证配置（强烈建议）

**⚠️ 安全提示：** 生产环境或开放网络访问时，务必启用认证。

**OpenCode 认证（HTTP Basic Auth）：**
```yaml
environment:
  - OPENCODE_SERVER_USERNAME=admin       # 可选，默认：opencode
  - OPENCODE_SERVER_PASSWORD=your-secret-password
```

访问 OpenCode web 界面：
- 地址：`http://localhost:4096`
- 用户名：`$OPENCODE_SERVER_USERNAME`
- 密码：`$OPENCODE_SERVER_PASSWORD`

**OpenClaw 认证（Token 方式）：**
```yaml
environment:
  - CLAW_GATEWAY_TOKEN=your-secure-random-token
```

生成安全 token：
```bash
openssl rand -hex 32
```

访问 OpenClaw 网关：
- 在 API 请求头或参数中携带 token
- 详见 OpenClaw 文档了解详细认证方式

**完整认证配置示例：**
```yaml
environment:
  - TOKEN=vscode-secret-token
  - OPENCODE_SERVER_PASSWORD=opencode-secret
  - CLAW_GATEWAY_TOKEN=openclaw-secret-token
```

### 服务管理脚本

**restart.sh** - 重启服务（不用重启容器）：
```bash
# 重启所有 AI 服务
/app/restart.sh

# 重启指定服务
/app/restart.sh opencode
/app/restart.sh openclaw
```

**update.sh** - 更新服务到最新版：
```bash
# 更新所有 AI 服务
/app/update.sh

# 更新指定服务
/app/update.sh opencode
/app/update.sh openclaw
```

### 使用服务

- **OpenCode TUI**：运行 `docker exec -it my-code-server opencode`
- **OpenClaw 面板**：访问 `http://localhost:18789`
- **日志**：查看 `~/.ai/opencode.log` 和 `~/.ai/openclaw.log`

### 日志轮转

日志每天自动轮转，规则如下：
- 当前日志：`~/.ai/opencode.log` 或 `~/.ai/openclaw.log`
- 历史日志：`~/.ai/opencode.log.YYYYMMDD` 或 `~/.ai/openclaw.log.YYYYMMDD`
- **保留期限**：默认自动删除 3 天前的日志
- **自定义期限**：设置环境变量 `LOG_RETENTION_DAYS`（例如 `LOG_RETENTION_DAYS=7`）

查看日志：
```bash
# 查看 OpenCode 日志
docker exec my-code-server tail -f ~/.ai/opencode.log

# 查看 OpenClaw 日志
docker exec my-code-server tail -f ~/.ai/openclaw.log

# 列出所有日志文件
docker exec my-code-server ls -la ~/.ai/
```

### 自动重启和更新

服务通过 `while true` 循环监控：
- 崩溃后自动重启（3秒延迟）
- 每2秒检查一次更新/重启标志
- 启动时如果有 `.update` 标志先执行更新

## Nginx 反向代理配置

### 网络配置

- 容器名：`my-code-server`
- 网络：`vscode-server-network`

### HTTP 配置

```nginx
server {
    listen 80;
    server_name my-code-server.domain.com;

    location / {
        proxy_pass http://my-code-server.vscode-server-network:8585;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket 支持（必需）
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

### HTTPS/SSL 配置

```nginx
server {
    listen 443 ssl;
    server_name my-code-server.domain.com;

    ssl_certificate /ssl/.domain.com.cer;
    ssl_certificate_key /ssl/.domain.com.key;

    location / {
        proxy_pass http://my-code-server.vscode-server-network:8585;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket 支持（必需）
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

访问地址：`https://my-code-server.domain.com?tkn=yourtoken`

## 架构支持

- **amd64** (x86_64) - ✅ 完全支持
- **arm64** (aarch64) - ❓ 应该可以（未测试）
- **armv7** - ❌ 不支持

## 安全提示

⚠️ **重要：** 请把默认 token 换成安全的值，生产环境千万别用默认密码。

## 参与贡献

欢迎提交 PR 和 Issue！
