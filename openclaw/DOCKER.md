# Docker Container Configuration

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `OPENCLAW_PORT` | OpenClaw Gateway port | `18789` |
| `OPENCLAW_GATEWAY_TOKEN` | Auth token for gateway access | Auto-generated if not set |
| `FORCE_REGENERATE_CONFIG` | Force regenerate `config.json` on startup (set to `true` to enable) | `false` |

## Usage Examples

### Basic Usage
```bash
docker run -d \
  --name openclaw \
  -p 18789:18789 \
  openclaw:latest
```

### With Custom Port
```bash
docker run -d \
  --name openclaw \
  -p 8080:8080 \
  -e OPENCLAW_PORT=8080 \
  openclaw:latest
```

### Force Regenerate Configuration
```bash
docker run -d \
  --name openclaw \
  -p 18789:18789 \
  -e FORCE_REGENERATE_CONFIG=true \
  openclaw:latest
```

### With Custom Token
```bash
docker run -d \
  --name openclaw \
  -p 18789:18789 \
  -e OPENCLAW_GATEWAY_TOKEN=your-custom-token \
  openclaw:latest
```

## Configuration Logic

1. **First Start**: If `config.json` doesn't exist, a new one is created with default settings
2. **Subsequent Starts**: If `config.json` exists, it's updated via `openclaw config set` commands
3. **Force Regenerate**: If `FORCE_REGENERATE_CONFIG=true`, the config file is completely regenerated (overwrites existing config)

## Config File Location

The configuration is stored at: `/home/coder/.openclaw/config.json` inside the container

## Building the Image

```bash
docker build -t openclaw:latest openclaw/
```
