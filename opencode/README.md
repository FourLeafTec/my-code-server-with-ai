# OpenCode Docker Image

AI coding assistant with TUI (Terminal User Interface).

## Quick Start

```bash
# Build the image
docker build -t opencode:latest .

# Run the container
docker run -d -p 4096:4096 opencode:latest
```

## Environment Variables

| Variable                   | Description          | Default    |
| -------------------------- | -------------------- | ---------- |
| `OPENCODE_PORT`            | OpenCode server port | `4096`     |
| `OPENCODE_HOST`            | Bind address         | `0.0.0.0`  |
| `OPENCODE_SERVER_USERNAME` | Web UI username      | `opencode` |
| `OPENCODE_SERVER_PASSWORD` | Web UI password      | -          |
| `PUID`                     | User ID              | `1000`     |
| `PGID`                     | Group ID             | `1000`     |

## Authentication

⚠️ **Security Warning:** For production or network-accessible deployments, always set `OPENCODE_SERVER_PASSWORD`.

```bash
docker run -d -p 4096:4096 \
  -e OPENCODE_SERVER_PASSWORD=your-secure-password \
  opencode:latest
```

Access OpenCode web interface:
- URL: `http://localhost:4096`
- Username: `opencode` (or `OPENCODE_SERVER_USERNAME`)
- Password: `OPENCODE_SERVER_PASSWORD`

## Usage

### Web UI

Open `http://localhost:4096` in your browser and enter your credentials (if configured).

### Terminal Access

```bash
# Access OpenCode TUI
docker exec -it opencode opencode
```

## Building

```bash
# Build locally
docker build -t opencode:latest .

# Build for specific architecture
docker buildx build --platform linux/amd64 -t opencode:latest .
docker buildx build --platform linux/arm64 -t opencode:latest .
```

## Features

- AI-powered code analysis
- Terminal UI for command-line usage
- Web interface for browser access
- HTTP Basic Authentication
- Project-aware context

## Complete Setup

For a complete setup with VS Code Server and OpenClaw, see the [../code-server-with-ai](../code-server-with-ai) directory.
