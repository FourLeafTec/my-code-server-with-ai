# VS Code Server - Docker 镜像

基于 Debian 的官方 VS Code Server Docker 镜像，支持 WebSocket，完全兼容扩展（包括 GitHub Copilot）。

这是独立的 VS Code Server 镜像。如需包含 AI 助手（OpenCode 和 OpenClaw）的完整设置，请参阅 [../code-server-with-ai](../code-server-with-ai) 目录。

## 快速开始

### 构建和运行

```bash
# 构建镜像
docker build -t my-code-server-with-cdn-fix:main .

# 运行容器
docker run -d -p 8585:8585 -e TOKEN=yourtoken my-code-server-with-cdn-fix:main
```

访问地址：`http://localhost:8585?tkn=yourtoken`

### 使用 Docker Compose

如需包含 AI 助手的完整设置，请使用 [../code-server-with-ai](../code-server-with-ai) 目录。

## 功能特性

- 官方 VS Code Server
- WebSocket 支持
- 完全兼容扩展（包括 GitHub Copilot）
- CDN 代理支持（用于受限网络环境）
- 动态 UID/GID 支持
- 多架构支持（amd64、arm64）

## 环境变量

| 变量 | 描述 | 默认值 |
|------|------|--------|
| `PORT` | VS Code Server 监听端口 | `8585` |
| `HOST` | 主机接口 | `0.0.0.0` |
| `TOKEN` | 连接令牌（用于认证） | 无 |
| `TOKEN_FILE` | 包含令牌的文件路径 | - |
| `PUID` | 用户 ID（用于卷权限） | `1000` |
| `PGID` | 组 ID（用于卷权限） | `998` |
| `SERVER_DATA_DIR` | 服务器数据存储目录 | - |
| `SERVER_BASE_PATH` | Web UI 基础路径 | - |
| `SOCKET_PATH` | 服务器套接字路径 | - |
| `VERBOSE` | 启用详细输出 | `false` |
| `LOG_LEVEL` | 日志级别 | - |
| `CLI_DATA_DIR` | CLI 元数据目录 | - |
| `USE_CDN_PROXY` | 启用 CDN 代理模式 | `false` |
| `CDN_PROXY_HOST` | CDN 代理主机（USE_CDN_PROXY=true 时必需） | - |

## CDN 代理

VS Code Server 需要 CDN 资源（扩展、UI 资产）。对于受限网络环境，请配置 CDN 代理。

### 启用 CDN 代理

```bash
docker run -d -p 8585:8585 \
  -e TOKEN=yourtoken \
  -e USE_CDN_PROXY=true \
  -e CDN_PROXY_HOST=your-proxy.domain.com \
  my-code-server-with-cdn-fix:main
```

### 工作原理

启用 CDN 代理时：
1. **每次容器启动时**：自动调用 `fix-cdn-proxy.sh`
2. VS Code Server 文件被修改为使用您的反向代理
3. 扩展和 UI 资产通过您的代理加载

这确保 CDN 配置始终保持最新，即使 VS Code Server 自动更新。

### Nginx 配置

在与 `CDN_PROXY_HOST` 相同的主机上，将以下位置添加到您的 nginx 配置：

```nginx
server {
    listen 80;
    server_name your-proxy.domain.com;

    # VS Code Server
    location / {
        proxy_pass http://localhost:8585;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # VS Code 扩展代理
    location /proxy-unpkg/ {
        rewrite ^/proxy-unpkg/(.*)$ /$1 break;
        proxy_pass https://www.vscode-unpkg.net;
        proxy_set_header Host www.vscode-unpkg.net;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_ssl_server_name on;
        proxy_ssl_protocols TLSv1.2 TLSv1.3;
        proxy_connect_timeout 60s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
    }

    # VS Code CDN 代理
    location /proxy-cdn/ {
        rewrite ^/proxy-cdn/(.*)$ /$1 break;
        proxy_pass https://main.vscode-cdn.net;
        proxy_set_header Host main.vscode-cdn.net;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_ssl_server_name on;
        proxy_ssl_protocols TLSv1.2 TLSv1.3;
        proxy_connect_timeout 60s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
    }
}
```

更新 nginx 后：`sudo nginx -t && sudo nginx -s reload`

## 自定义 UID/GID

为避免挂载卷的权限问题：

```bash
docker run -d -p 8585:8585 \
  -e TOKEN=yourtoken \
  -e PUID=$(id -u) \
  -e PGID=$(id -g) \
  -v /path/to/data:/home/coder \
  my-code-server-with-cdn-fix:main
```

## 架构支持

- **amd64** (x86_64) - ✅ 完全支持
- **arm64** (aarch64) - ✅ 支持
- **armv7** - ❌ 不支持

## 安全

⚠️ **重要提示：**
- 生产环境请始终使用强令牌
- 永远不要将令牌提交到版本控制
- 生产环境请使用 HTTPS（配置 nginx SSL）

## 相关项目

| 项目 | 描述 |
|------|------|
| [../opencode](../opencode) | OpenCode AI 编程助手 |
| [../openclaw](../openclaw) | OpenClaw AI 网关 |
| [../code-server-with-ai](../code-server-with-ai) | 包含三个服务的完整设置 |
