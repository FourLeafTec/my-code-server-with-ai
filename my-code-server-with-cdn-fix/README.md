# VS Code Server - Docker Image

Official VS Code Server in Docker with WebSocket support, full extension compatibility (including GitHub Copilot), based on Debian.

This is a standalone VS Code Server image. For the complete setup with AI assistants (OpenCode and OpenClaw), see the [../code-server-with-ai](../code-server-with-ai) directory.

## Quick Start

### Build and Run

```bash
# Build the image
docker build -t my-code-server-with-cdn-fix:main .

# Run the container
docker run -d -p 8585:8585 -e TOKEN=yourtoken my-code-server-with-cdn-fix:main
```

Access: `http://localhost:8585?tkn=yourtoken`

### With Docker Compose

For the complete setup with AI assistants, use the [../code-server-with-ai](../code-server-with-ai) directory.

## Features

- Official VS Code Server
- WebSocket support
- Full extension compatibility (including GitHub Copilot)
- CDN proxy support for restricted networks
- Dynamic UID/GID support
- Multi-architecture support (amd64, arm64)

## Environment Variables

| Variable | Description | Default |
|----------|-------------|----------|
| `PORT` | VS Code Server listening port | `8585` |
| `HOST` | Host interface | `0.0.0.0` |
| `TOKEN` | Connection token for authentication | None |
| `TOKEN_FILE` | Path to file containing token | - |
| `PUID` | User ID (for volume permissions) | `1000` |
| `PGID` | Group ID (for volume permissions) | `998` |
| `SERVER_DATA_DIR` | Server data storage directory | - |
| `SERVER_BASE_PATH` | Base path for web UI | - |
| `SOCKET_PATH` | Socket path for server | - |
| `VERBOSE` | Enable verbose output | `false` |
| `LOG_LEVEL` | Log level | - |
| `CLI_DATA_DIR` | CLI metadata directory | - |
| `USE_CDN_PROXY` | Enable CDN proxy mode | `false` |
| `CDN_PROXY_HOST` | CDN proxy host (required when USE_CDN_PROXY=true) | - |

## CDN Proxy

VS Code Server requires CDN resources (extensions, UI assets). For restricted network environments, configure CDN proxy.

### Enable CDN Proxy

```bash
docker run -d -p 8585:8585 \
  -e TOKEN=yourtoken \
  -e USE_CDN_PROXY=true \
  -e CDN_PROXY_HOST=your-proxy.domain.com \
  my-code-server-with-cdn-fix:main
```

### How It Works

When CDN proxy is enabled:
1. **On every container startup**: `fix-cdn-proxy.sh` is called automatically
2. VS Code Server files are patched to use your reverse proxy
3. Extensions and UI assets load through your proxy

This ensures CDN configuration is always up-to-date, even after VS Code Server auto-updates.

### Nginx Configuration

Add these locations to your nginx config on the same host as `CDN_PROXY_HOST`:

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

    # VS Code Extensions proxy
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

    # VS Code CDN proxy
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

After updating nginx: `sudo nginx -t && sudo nginx -s reload`

## Custom UID/GID

To avoid permission issues with mounted volumes:

```bash
docker run -d -p 8585:8585 \
  -e TOKEN=yourtoken \
  -e PUID=$(id -u) \
  -e PGID=$(id -g) \
  -v /path/to/data:/home/coder \
  my-code-server-with-cdn-fix:main
```

## Architecture Support

- **amd64** (x86_64) - ✅ Fully supported
- **arm64** (aarch64) - ✅ Supported
- **armv7** - ❌ Not supported

## Security

⚠️ **Important:** 
- Always use strong tokens in production
- Never commit tokens to version control
- Use HTTPS in production (configure nginx with SSL)

## Related Projects

| Project | Description |
|---------|-------------|
| [../opencode](../opencode) | OpenCode AI coding assistant |
| [../openclaw](../openclaw) | OpenClaw AI gateway |
| [../code-server-with-ai](../code-server-with-ai) | Complete setup with all three services |
