# Code Server with AI - Process Compose Edition

A unified container solution that combines VS Code Server, OpenCode, and OpenClaw into a single container using [Process Compose](https://github.com/F1bonacc1/process-compose) for process management.

## Why Process Compose?

This approach solves the inter-container communication issues by:

- **Single container**: All three services run in one container
- **Process management**: Process Compose handles process lifecycle, health checks, and restarts
- **Shared network**: No need for Docker networking between containers
- **Unified logs**: All process logs in one place
- **Simpler deployment**: One image, one container, one volume

### Process Compose
```
┌─────────────────────────────────────────────────────────────┐
│  Single Container                                           │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Process Compose                                     │   │
│  │  ┌─────────────┬─────────────┬─────────────────┐   │   │
│  │  │vscode-server│   opencode  │    openclaw     │   │   │
│  │  │  :8585      │   :4096     │     :18789      │   │   │
│  │  └─────────────┴─────────────┴─────────────────┘   │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

```bash
cd process-compose

cp .env.example .env
nano .env

docker compose up -d --build
```

## Access Services

| Service  | URL                    | Credentials       |
| -------- | ---------------------- | ----------------- |
| VS Code  | http://localhost:8585  | Token from .env   |
| OpenCode | http://localhost:4096  | Username/Password |
| OpenClaw | http://localhost:18789 | Token from .env   |

## Environment Variables

### VS Code Server
| Variable          | Description          | Default |
| ----------------- | -------------------- | ------- |
| VSCODE_HOST       | Bind address         | 0.0.0.0 |
| VSCODE_PORT       | Port                 | 8585    |
| VSCODE_TOKEN      | Connection token     | (none)  |
| VSCODE_EXTRA_ARGS | Additional arguments |         |
| USE_CDN_PROXY     | Enable CDN proxy     | false   |
| CDN_PROXY_HOST    | CDN proxy host       |         |

### OpenCode
| Variable                 | Description  | Default  |
| ------------------------ | ------------ | -------- |
| OPENCODE_HOST            | Bind address | 0.0.0.0  |
| OPENCODE_PORT            | Port         | 4096     |
| OPENCODE_SERVER_USERNAME | Username     | opencode |
| OPENCODE_SERVER_PASSWORD | Password     |          |

### OpenClaw
| Variable               | Description   | Default |
| ---------------------- | ------------- | ------- |
| OPENCLAW_PORT          | Port          | 18789   |
| OPENCLAW_GATEWAY_TOKEN | Gateway token |         |

### General
| Variable  | Description    | Default |
| --------- | -------------- | ------- |
| PUID      | User ID        | 1000    |
| PGID      | Group ID       | 1000    |
| DATA_DIR  | Data directory | ./data  |
| EXTRA_GID | Extra Group ID |         |

## Management Commands

```bash
docker compose up -d --build    # Build and start
docker compose down             # Stop and remove
docker compose restart          # Restart all
docker compose logs -f          # View logs
docker compose logs -f vscode-server  # View specific service logs
docker compose ps               # Show status
docker compose exec code-server-with-ai sh  # Shell into container
```

## Process Compose Inside Container

Once inside the container:

```bash
process-compose attach                               # Attach
process-compose -f /app/process-compose.yaml up      # TUI mode
process-compose -f /app/process-compose.yaml up -D   # Detached
process-compose -f /app/process-compose.yaml down    # Stop all
process-compose -f /app/process-compose.yaml ps      # Show status
```

## Health Checks

Each process has a readiness probe configured using curl to check if the service is responding:
- VS Code Server: `http://localhost:8585/` (root endpoint)
- OpenCode: `http://localhost:4096/` (root endpoint)
- OpenClaw: `http://localhost:18789/health` (dedicated health endpoint)

The probes use `curl -sf` (silent + fail on error) to check service availability without requiring authentication.

## CDN Proxy

For restricted network environments:

```env
USE_CDN_PROXY=true
CDN_PROXY_HOST=your-proxy.domain.com
```

Required Nginx configuration:
```
  location /proxy-unpkg/ {
      proxy_pass https://www.vscode-unpkg.net/;
      proxy_set_header Host www.vscode-unpkg.net;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_redirect off;
  }

  location /proxy-cdn/ {
      proxy_pass https://main.vscode-cdn.net/;
      proxy_set_header Host main.vscode-cdn.net;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_redirect off;
  }
```

## Building

```bash
docker build -t code-server-with-ai:latest .
```

Or use docker compose:

```bash
docker compose build
docker compose up -d
```

## Architecture Support

- amd64 (x86_64) - Full support
- arm64 (aarch64) - Full support
- armv7 - Not supported (VS Code limitation)

## Troubleshooting

### Process not starting

Check logs:
```bash
docker compose logs -f
```

## Files

```
Dockerfile                 # Unified container image
docker-compose.yml         # Docker Compose configuration
process-compose.yaml       # Process Compose configuration
start.sh                  # Container startup script
.env.example              # Environment template
README.md                 # This file
```

## Quick Start

1. Update environment variables in `.env`

2. Build and start new container:
   ```bash
   cd ../process-compose
   docker compose up -d --build
   ```
