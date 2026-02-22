# Code Server with AI - Complete Setup

This directory contains the complete Docker Compose setup for running VS Code Server with OpenCode and OpenClaw AI assistants.

## Quick Start

```bash
# Copy environment file and edit with your configuration
cp .env.example .env
nano .env  # or use your preferred editor

# Build and start all services
./start.sh

# Or use docker-compose directly
docker compose up -d --build
```

## Services

After starting, access the services:

| Service | URL | Credentials |
|---------|-----|-------------|
| **VS Code Server** | http://localhost:8585 | Token: from `.env` |
| **OpenCode** | http://localhost:4096 | Username/Password: from `.env` |
| **OpenClaw** | http://localhost:18789 | Token: from `.env` |

## Configuration

Copy `.env.example` to `.env` and configure:

```env
# Container name
CONTAINER_NAME=my-code-server-with-ai

# VS Code Server
HOST_PORT=8585
TOKEN=your-secure-token
USE_CDN_PROXY=false
CDN_PROXY_HOST=

# OpenCode
OPENCODE_HOST_PORT=4096
OPENCODE_SERVER_PASSWORD=your-opencode-password

# OpenClaw
OPENCLAW_HOST_PORT=18789
OPENCLAW_GATEWAY_TOKEN=your-openclaw-token

# User permissions
PUID=1000
PGID=998
```

## CDN Proxy

For environments with restricted network access, enable CDN proxy:

```env
USE_CDN_PROXY=true
CDN_PROXY_HOST=your-proxy.domain.com
```

When enabled, CDN proxy patches are applied **on every container startup** automatically.

For nginx configuration, see [../my-code-server-with-cdn-fix/README.md](../my-code-server-with-cdn-fix/README.md).

## Management Commands

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# Restart specific service
docker compose restart vscode-server
docker compose restart opencode
docker compose restart openclaw

# View logs
docker compose logs -f vscode-server
docker compose logs -f opencode
docker compose logs -f openclaw

# View status
docker compose ps

# Rebuild specific service
docker compose build vscode-server
docker compose up -d vscode-server
```

## Architecture

This setup uses three independent Docker containers:

```
┌─────────────────────────────────────────────────────┐
│           Docker Network (vscode-server-network)    │
├─────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐           │
│  │ vscode-server │  │  opencode    │           │
│  │   Port 8585  │  │   Port 4096  │           │
│  └──────────────┘  └──────────────┘           │
│  ┌──────────────┐                             │
│  │  openclaw    │                             │
│  │  Port 18789  │                             │
│  └──────────────┘                             │
└─────────────────────────────────────────────────────┘
```

Each service:
- Has its own Docker image
- Starts independently
- Uses Docker's restart policy for auto-restart
- Shares the same Docker network

## Data Persistence

To persist data, uncomment and configure in `.env`:

```env
DATA_DIR=/path/to/your/data
```

This will mount the data directory to all containers, preserving:
- VS Code extensions and settings
- OpenCode project history
- OpenClaw configurations

## Individual Service Documentation

| Service | Documentation |
|---------|---------------|
| **VS Code Server** | [../my-code-server-with-cdn-fix/README.md](../my-code-server-with-cdn-fix/README.md) |
| **OpenCode** | [../opencode/README.md](../opencode/README.md) |
| **OpenClaw** | [../openclaw/README.md](../openclaw/README.md) |
