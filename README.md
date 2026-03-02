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

| Service     | URL                  | Credentials              |
|-------------|----------------------|-------------------------|
| VS Code     | http://localhost:8585 | Token from .env         |
| OpenCode    | http://localhost:4096 | Username/Password     |
| OpenClaw    | http://localhost:18789 | Token from .env        |

## Environment Variables

### VS Code Server
| Variable        | Description              | Default       |
|-----------------|-------------------------|---------------|
| VSCODE_HOST     | Bind address            | 0.0.0.0       |
| VSCODE_PORT     | Port                    | 8585          |
| VSCODE_TOKEN    | Connection token       | (none)        |
| VSCODE_EXTRA_ARGS | Additional arguments  |               |
| USE_CDN_PROXY   | Enable CDN proxy       | false         |
| CDN_PROXY_HOST  | CDN proxy host          |               |

### OpenCode
| Variable              | Description     | Default   |
|-----------------------|-----------------|-----------|
| OPENCODE_HOST         | Bind address    | 0.0.0.0   |
| OPENCODE_PORT         | Port            | 4096      |
| OPENCODE_SERVER_USERNAME | Username    | opencode  |
| OPENCODE_SERVER_PASSWORD | Password     |           |

### OpenClaw
| Variable                | Description  | Default   |
|-------------------------|--------------|-----------|
| OPENCLAW_PORT           | Port         | 18789     |
| OPENCLAW_GATEWAY_TOKEN  | Gateway token|           |

### General
| Variable  | Description        | Default |
|-----------|--------------------|---------|
| PUID      | User ID            | 1000    |
| PGID      | Group ID           | 1000    |
| DATA_DIR  | Data directory     | ./data  |

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
process-compose -f /app/process-compose/process-compose.yaml up      # TUI mode
process-compose -f /app/process-compose/process-compose.yaml up -D   # Detached
process-compose -f /app/process-compose/process-compose.yaml down    # Stop all
process-compose -f /app/process-compose/process-compose.yaml ps      # Show status
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

See [../my-code-server-with-cdn-fix/README.md](../my-code-server-with-cdn-fix/README.md) for nginx configuration.

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

### Access a specific process log:
```bash
docker compose logs -f vscode-server
docker compose logs -f opencode
docker compose logs -f openclaw
```

### Restart a specific process

```bash
docker compose exec code-server-with-ai process-compose restart vscode-server
```

### Shell access

```bash
docker compose exec code-server-with-ai sh
```

## Files

```
process-compose/
├── Dockerfile                 # Unified container image
├── docker-compose.yml         # Docker Compose configuration
├── process-compose.yaml       # Process Compose configuration
├── start.sh                  # Container startup script
├── .env.example              # Environment template
└── README.md                 # This file
```

## Migration from Multi-Container

1. Copy your data directory to the new location:
   ```bash
   cp -r ../my-code-server-with-cdn-fix/data ./data
   ```

2. Update environment variables in `.env`

3. Stop old containers:
   ```bash
   cd ../code-server-with-ai
   docker compose down
   ```

4. Build and start new container:
   ```bash
   cd ../process-compose
   docker compose up -d --build
   ```
