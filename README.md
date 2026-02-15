# VS-Code Server - Docker Setup & Config

Official VS Code Server in Docker with WebSocket support, full extension compatibility (including GitHub Copilot), based on Debian.

Features: VS Code Server + OpenCode AI + OpenClaw AI assistants, WebSocket support, process management with tini.

## Quick Start

```bash
# Pull and run
docker pull ghcr.io/FourLeafTec/my-code-server-with-ai:main
docker run -d -p 8585:8585 -e TOKEN=yourtoken ghcr.io/FourLeafTec/my-code-server-with-ai:main

# Or with docker-compose
docker compose up -d
```

Access: `http://localhost:8585?tkn=yourtoken`

## Installation

### Prerequisites

- Docker
- Docker Compose (optional)
- Reverse Proxy (optional, for production)

### Option 1: Using Pre-built Image

```bash
docker pull ghcr.io/FourLeafTec/my-code-server-with-ai:main
```

### Option 2: Build Locally

```bash
# Using buildx (recommended)
docker buildx build -t my-code-server-with-ai:main .

# Or using legacy builder
docker build -t my-code-server-with-ai:main .
```

## Usage

### Docker Compose (Recommended)

**Basic usage:**
```bash
docker compose up -d
```

**With custom configuration (.env file):**
```env
HOST_PORT=9090
CONTAINER_PORT=8585
TOKEN=mysecuretoken
PUID=1000
PGID=1000
```

**With volumes (for persistence):**
Uncomment in `docker-compose.yml`:
```yaml
volumes:
  - /path/to/your/data:/home/vscodeuser
```

### Docker Run

**Basic:**
```bash
docker run -d -p 8585:8585 \
  -e PORT=8585 \
  -e TOKEN=sometoken \
  my-code-server-with-ai:main
```

**With volumes and custom UID/GID:**
```bash
docker run -d -p 8585:8585 \
  -e PORT=8585 \
  -e TOKEN=sometoken \
  -e PUID=$(id -u) \
  -e PGID=$(id -g) \
  -v /path/to/your/data:/home/vscodeuser \
  my-code-server-with-ai:main
```

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | VS Code Server listening port | `8585` |
| `HOST` | Host interface to listen on | `0.0.0.0` |
| `TOKEN` | Connection token for authentication | None |
| `TOKEN_FILE` | Path to file containing token | - |
| `PUID` | User ID (for volume permissions) | `1000` |
| `PGID` | Group ID (for volume permissions) | `1000` |
| `SERVER_DATA_DIR` | Server data storage directory | - |
| `SERVER_BASE_PATH` | Base path for web UI | - |
| `SOCKET_PATH` | Socket path for server | - |
| `VERBOSE` | Enable verbose output | `false` |
| `LOG_LEVEL` | Log level (trace, debug, info, warn, error, critical, off) | - |
| `CLI_DATA_DIR` | CLI metadata directory | - |
| `OPENCODE_PORT` | OpenCode server port | `4096` |
| `OPENCODE_HOST` | OpenCode bind address | `0.0.0.0` |
| `OPENCODE_SERVER_PASSWORD` | OpenCode web password (recommended) | - |
| `OPENCODE_SERVER_USERNAME` | OpenCode web username | `opencode` |
| `OPENCLAW_PORT` | OpenClaw gateway port | `18789` |
| `OPENCLAW_HOST` | OpenClaw bind address | `0.0.0.0` |
| `CLAW_GATEWAY_TOKEN` | OpenClaw gateway token (recommended) | - |
| `LOG_RETENTION_DAYS` | Log retention period (days) | `3` |

### Docker Compose Variables

Use environment variables or `.env` file:

| Variable | Description | Default |
|----------|-------------|---------|
| `HOST_PORT` | Host port mapping | `8585` |
| `CONTAINER_PORT` | Container port | `8585` |
| `TOKEN` | Authentication token | `sometoken` |
| `PUID` | User ID | `1000` |
| `PGID` | Group ID | `1000` |
| `OPENCODE_HOST_PORT` | OpenCode host port | `4096` |
| `OPENCODE_PORT` | OpenCode container port | `4096` |
| `OPENCLAW_HOST_PORT` | OpenClaw host port | `18789` |
| `OPENCLAW_PORT` | OpenClaw container port | `18789` |

### Custom UID/GID

To avoid permission issues with mounted volumes, the container supports dynamic UID/GID:

**With docker-compose:** Set `PUID` and `PGID` environment variables
**With docker run:** Use `-e PUID=$(id -u) -e PGID=$(id -g)`

The container will automatically adjust user permissions at startup.

## AI Services (OpenCode & OpenClaw)

This container includes pre-installed AI coding assistants that run as background services.

### Available Services

| Service | Description | Default Port | CLI Command |
|---------|-------------|--------------|-------------|
| **OpenCode** | AI coding assistant with TUI | `4096` | `opencode` |
| **OpenClaw** | Personal AI assistant gateway | `18789` | `openclaw` |

### Port Configuration

Configure service ports via environment variables:

```yaml
# docker-compose.yml
environment:
  - OPENCODE_HOST=0.0.0.0        # OpenCode bind address
  - OPENCODE_PORT=4096           # OpenCode server port
  - OPENCLAW_HOST=0.0.0.0        # OpenClaw bind address
  - OPENCLAW_PORT=18789          # OpenClaw gateway port
  - LOG_RETENTION_DAYS=3         # Log retention period (optional)

ports:
  - "8585:8585"                  # VS Code Server
  - "4096:4096"                  # OpenCode
  - "18789:18789"                # OpenClaw
```

Or with `.env` file:
```env
OPENCODE_HOST=0.0.0.0
OPENCODE_PORT=4096
OPENCLAW_HOST=0.0.0.0
OPENCLAW_PORT=18789
OPENCODE_HOST_PORT=4096
OPENCLAW_HOST_PORT=18789
LOG_RETENTION_DAYS=3
```

### Authentication (Highly Recommended)

**⚠️ Security Warning:** For production or network-accessible deployments, always enable authentication.

**OpenCode Authentication (HTTP Basic Auth):**
```yaml
environment:
  - OPENCODE_SERVER_USERNAME=admin       # Optional, default: opencode
  - OPENCODE_SERVER_PASSWORD=your-secret-password
```

Access OpenCode web interface:
- URL: `http://localhost:4096`
- Username: `$OPENCODE_SERVER_USERNAME`
- Password: `$OPENCODE_SERVER_PASSWORD`

**OpenClaw Authentication (Token-based):**
```yaml
environment:
  - CLAW_GATEWAY_TOKEN=your-secure-random-token
```

Generate a secure token:
```bash
openssl rand -hex 32
```

Access OpenClaw gateway:
- Include token in API requests header or query parameter
- Check OpenClaw docs for detailed authentication methods

**Full example with authentication:**
```yaml
environment:
  - TOKEN=vscode-secret-token
  - OPENCODE_SERVER_PASSWORD=opencode-secret
  - CLAW_GATEWAY_TOKEN=openclaw-secret-token
```

### Service Management Scripts

**restart.sh** - Restart services without stopping the container:
```bash
# Restart all AI services
/app/restart.sh

# Restart specific service
/app/restart.sh opencode
/app/restart.sh openclaw
```

**update.sh** - Update services to latest version:
```bash
# Update all AI services
/app/update.sh

# Update specific service
/app/update.sh opencode
/app/update.sh openclaw
```

### Accessing Services

- **OpenCode TUI**: Run `docker exec -it my-code-server-with-ai opencode`
- **OpenClaw Dashboard**: Visit `http://localhost:18789`
- **Logs**: Check `~/.ai/opencode.log` and `~/.ai/openclaw.log`

### Log Rotation

Logs are automatically rotated daily with the following behavior:
- Current log: `~/.ai/opencode.log` or `~/.ai/openclaw.log`
- Rotated logs: `~/.ai/opencode.log.YYYYMMDD` or `~/.ai/openclaw.log.YYYYMMDD`
- **Retention**: By default, logs older than 3 days are automatically deleted
- **Customize retention**: Set `LOG_RETENTION_DAYS` environment variable (e.g., `LOG_RETENTION_DAYS=7`)

View recent logs:
```bash
# View OpenCode logs
docker exec my-code-server-with-ai tail -f ~/.ai/opencode.log

# View OpenClaw logs
docker exec my-code-server-with-ai tail -f ~/.ai/openclaw.log

# List all log files
docker exec my-code-server-with-ai ls -la ~/.ai/
```

### Auto-Restart & Updates

Services are monitored with `while true` loops that:
- Auto-restart on crash (3-second delay)
- Check for update/restart flags every 2 seconds
- Apply updates before starting (if `.update` flag exists)

## Nginx Reverse Proxy Setup

### Network Configuration

- Container name: `my-code-server-with-ai`
- Network: `vscode-server-network`

### HTTP Configuration

```nginx
server {
    listen 80;
    server_name my-code-server-with-ai.domain.com;

    location / {
        proxy_pass http://my-code-server-with-ai.vscode-server-network:8585;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support (required)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

### HTTPS/SSL Configuration

```nginx
server {
    listen 443 ssl;
    server_name my-code-server-with-ai.domain.com;

    ssl_certificate /ssl/.domain.com.cer;
    ssl_certificate_key /ssl/.domain.com.key;

    location / {
        proxy_pass http://my-code-server-with-ai.vscode-server-network:8585;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support (required)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

Access: `https://my-code-server-with-ai.domain.com?tkn=yourtoken`

## Architecture Support

- **amd64** (x86_64) - ✅ Fully supported
- **arm64** (aarch64) - ❓ Should work (not tested yet)
- **armv7** - ❌ Not supported

## Security

⚠️ **Important:** Replace default tokens with secure values. Never use published credentials in production.

## Contributing

Contributions are welcome!

