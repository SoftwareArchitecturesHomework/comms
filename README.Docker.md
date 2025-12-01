# Docker Deployment Guide

This guide covers how to build and run the Comms service using Docker.

## Quick Start

### 1. Build the Docker image

```bash
docker build -t comms:latest .
```

### 2. Generate a SECRET_KEY_BASE

You need a secret key base for production. Generate one with:

```bash
docker run --rm comms:latest /app/bin/comms eval 'IO.puts(:crypto.strong_rand_bytes(64) |> Base.encode64())'
```

Or if you have Elixir installed locally:

```bash
mix phx.gen.secret
```

### 3. Set up environment variables

Copy the example environment file:

```bash
cp .env.example .env
```

Edit `.env` and fill in all required values.

### 4. Run with Docker Compose

```bash
docker-compose up
```

Or run manually:

```bash
docker run --rm \
  --env-file .env \
  -p 4000:4000 \
  comms:latest
```

## Environment Variables

### Required Variables

The following environment variables **must** be set at runtime:

- `SECRET_KEY_BASE` - Phoenix secret key (generate with `mix phx.gen.secret`)
- `PHX_HOST` - Your application hostname (e.g., `example.com`)
- `PORT` - Port to listen on (default: `4000`)
- `JWT_PUBLIC_KEY` - JWT RS256 PEM format public key
- `DISCORD_APP_ID` - Discord application ID
- `DISCORD_PUBLIC_KEY` - Discord public key
- `DISCORD_BOT_TOKEN` - Discord bot token
- `SMTP_SERVER` - SMTP server hostname
- `SMTP_USERNAME` - SMTP username
- `SMTP_PASSWORD` - SMTP password
- `SMTP_SSL` - Use SSL for SMTP (`true` or `false`)

### Optional Variables

- `PHX_SERVER` - Enable Phoenix server (default: `true`)
- `SMTP_PORT` - SMTP port (default: `587`)
- `SMTP_TLS_VERIFY` - Verify TLS certificates (default: `true`)
- `SMTP_CACERTFILE` - Path to CA certificates file
- `JWT_DEBUG` - Enable JWT debug mode (`1` to enable)
- `DISCORD_SIGNATURE_DISABLE` - Disable Discord signature verification (`1` to disable, NOT recommended)
- `CORE_SERVICE_HTTP` - URL for core service
- `DNS_CLUSTER_QUERY` - DNS query for cluster discovery

## Important Notes

### No Environment Variables at Build Time

This Docker setup is designed to **not include any environment variables during the build process**. All configuration is loaded at runtime from environment variables.

This means:

- ✅ You can build once and deploy to multiple environments
- ✅ Secrets are never baked into the image
- ✅ Configuration is environment-specific at runtime

### Startup Validation

The `server.sh` script validates all required environment variables on startup and will exit with an error if any are missing. This prevents the service from starting in a misconfigured state.

## Building for Production

### Multi-architecture builds

To build for multiple architectures (e.g., ARM and x86):

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t comms:latest \
  --push \
  .
```

### Using a specific Elixir/OTP version

The Dockerfile supports build arguments for versions:

```bash
docker build \
  --build-arg ELIXIR_VERSION=1.15.7 \
  --build-arg OTP_VERSION=26.1.2 \
  -t comms:latest \
  .
```

## Health Checks

The docker-compose.yml includes a health check configuration that uses the existing `/health` endpoint.

```
GET /health
```

## Troubleshooting

### Missing environment variables on startup

If you see error messages about missing environment variables, ensure:

1. All required variables are set in your `.env` file or environment
2. The `.env` file is in the same directory as `docker-compose.yml`
3. Variable names are spelled correctly

### Discord commands not installing

The release may not include Mix tasks by default. Discord commands should be installed before starting the service. You can:

1. Install commands manually using the Discord API
2. Create a separate initialization container/job
3. Include Mix tasks in the release (add to `mix.exs` release config)

### Can't generate SECRET_KEY_BASE

If the Docker command fails, you can generate it locally:

```bash
# Using openssl
openssl rand -base64 64

# Using Python
python3 -c "import secrets; print(secrets.token_urlsafe(64))"
```

## Development vs Production

For development, continue using the `dev-server.sh` script:

```bash
./dev-server.sh
```

For production, use Docker with `server.sh` (included in the image).
