# OpenClaw Docker Image

Personal AI assistant gateway.

## Quick Start

```bash
# Build the image
docker build -t openclaw:latest .

# Run the container
docker run -d -p 18789:18789 openclaw:latest
```

## Environment Variables

| Variable                   | Description                      | Default   |
| -------------------------- | -------------------------------- | --------- |
| `OPENCLAW_PORT`            | OpenClaw gateway port            | `18789`   |
| `OPENCLAW_HOST`            | Bind address                     | `0.0.0.0` |
| `OPENCLAW_GATEWAY_TOKEN`   | Gateway token for authentication | -         |
| `OPENCLAW_TRUSTED_PROXIES` | Trusted proxies (JSON array)     | -         |
| `PUID`                     | User ID                          | `1000`    |
| `PGID`                     | Group ID                         | `1000`    |

## Authentication

### Token-based Authentication (Default)

⚠️ **Security Warning:** Always set `OPENCLAW_GATEWAY_TOKEN` for production.

```bash
# Generate a secure token
TOKEN=$(openssl rand -hex 32)

# Run with token
docker run -d -p 18789:18789 \
  -e OPENCLAW_GATEWAY_TOKEN=$TOKEN \
  openclaw:latest
```

### Trusted Proxy Mode

For reverse proxy setups where authentication is handled by the proxy:

```bash
docker run -d -p 18789:18789 \
  -e OPENCLAW_TRUSTED_PROXIES='["127.0.0.1", "::1"]' \
  openclaw:latest
```

In trusted-proxy mode, `OPENCLAW_GATEWAY_TOKEN` is not required.

## Configuration

### Token Mode

```yaml
environment:
  - OPENCLAW_GATEWAY_TOKEN=your-secure-random-token
  - OPENCLAW_HOST=0.0.0.0
  - OPENCLAW_PORT=18789
```

### Trusted Proxy Mode

```yaml
environment:
  - OPENCLAW_TRUSTED_PROXIES=["127.0.0.1", "::1"]
  - OPENCLAW_HOST=0.0.0.0
  - OPENCLAW_PORT=18789
```

## Usage

### Web UI

Access the dashboard at `http://localhost:18789` (with token if configured).

### CLI

```bash
# Access OpenClaw CLI
docker exec -it openclaw openclaw
```

## Building

```bash
# Build locally
docker build -t openclaw:latest .

# Build for specific architecture
docker buildx build --platform linux/amd64 -t openclaw:latest .
docker buildx build --platform linux/arm64 -t openclaw:latest .
```

## Features

- Personal AI assistant
- Gateway interface
- Token-based authentication
- Trusted proxy support
- Web dashboard
- CLI interface

## Complete Setup

For a complete setup with VS Code Server and OpenCode, see the [../code-server-with-ai](../code-server-with-ai) directory.
