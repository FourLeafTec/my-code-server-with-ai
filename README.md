# My Code Server with AI

Docker-based development environment with three independent services:

- **my-code-server-with-cdn-fix/** - VS Code Server
- **opencode/** - OpenCode AI coding assistant
- **openclaw/** - OpenClaw AI gateway
- **code-server-with-ai/** - Complete setup with all three services

## Quick Start

```bash
cd code-server-with-ai
cp .env.example .env
# Edit .env with your configuration
docker compose up
```

Access:
- VS Code Server: http://localhost:8585
- OpenCode: http://localhost:4096
- OpenClaw: http://localhost:18789

## Project Structure

```
my-code-server-with-ai/
├── my-code-server-with-cdn-fix/  # VS Code Server Docker image
│   ├── Dockerfile
│   ├── start.sh
│   ├── fix-cdn-proxy.sh
│   └── README.md
│
├── opencode/                      # OpenCode Docker image
│   ├── Dockerfile
│   ├── start.sh
│   └── README.md
│
├── openclaw/                      # OpenClaw Docker image
│   ├── Dockerfile
│   ├── start.sh
│   └── README.md
│
└── code-server-with-ai/           # Complete setup
    ├── docker-compose.yml
    └── README.md
```

## Services

| Service | Port | Description |
|---------|------|-------------|
| VS Code Server | 8585 | Official VS Code Server |
| OpenCode | 4096 | AI coding assistant |
| OpenClaw | 18789 | AI gateway |

## CDN Proxy Support

VS Code Server supports CDN proxy for environments with restricted network access.

### Enable CDN Proxy

```bash
# In .env file
USE_CDN_PROXY=true
CDN_PROXY_HOST=your-proxy.domain.com
```

### How It Works

When CDN proxy is enabled:
- **On every container startup**: CDN proxy patches are applied automatically
- VS Code Server files are patched to use your reverse proxy
- Extensions and UI assets load through your proxy

### Nginx Configuration

```nginx
# VS Code Extensions proxy
location /proxy-unpkg/ {
    rewrite ^/proxy-unpkg/(.*)$ /$1 break;
    proxy_pass https://www.vscode-unpkg.net;
    proxy_set_header Host www.vscode-unpkg.net;
    proxy_ssl_server_name on;
}

# VS Code CDN proxy
location /proxy-cdn/ {
    rewrite ^/proxy-cdn/(.*)$ /$1 break;
    proxy_pass https://main.vscode-cdn.net;
    proxy_set_header Host main.vscode-cdn.net;
    proxy_ssl_server_name on;
}
```

For complete nginx configuration, see [my-code-server-with-cdn-fix/README.md](my-code-server-with-cdn-fix/README.md).

## Documentation

| Service | Documentation |
|---------|---------------|
| **Complete Setup** | [code-server-with-ai/README.md](code-server-with-ai/README.md) |
| **VS Code Server** | [my-code-server-with-cdn-fix/README.md](my-code-server-with-cdn-fix/README.md) |
| **OpenCode** | [opencode/README.md](opencode/README.md) |
| **OpenClaw** | [openclaw/README.md](openclaw/README.md) |

## Individual Builds

Each service can be built independently:

```bash
# VS Code Server
cd my-code-server-with-cdn-fix
docker build -t my-code-server-with-cdn-fix:main .

# OpenCode
cd opencode
docker build -t opencode:latest .

# OpenClaw
cd openclaw
docker build -t openclaw:latest .
```

## Architecture Support

- amd64 (x86_64) - ✅ Fully supported
- arm64 (aarch64) - ✅ Supported
- armv7 - ❌ Not supported

## Security

⚠️ **Important:** 
- Always use strong passwords and tokens in production
- Use environment variables for sensitive data
- Consider using a reverse proxy for production
- Enable CDN proxy for restricted network environments
