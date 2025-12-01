# Environment Setup Guide

This guide explains how to set up the required environment variables for the Comms API.
The dockerized version of this application also needs these environment variables to function correctly.

## Required Environment Variables

### JWT Configuration

For asymmetric JWT verification, you need to provide a public key:

```bash
nr rsa-key-gen # this should be used to sign tokens
nr rsa-pub-key-gen # this is actually used by the api to verify tokens
export JWT_PUBLIC_KEY=$(cat public.key)
```

The public key should be in PEM format (which it will be if you used the above commands) and match the private key used by your authentication service.

You can generate a JWT token for testing using [https://dinochiesa.github.io/jwt/](https://dinochiesa.github.io/jwt/), ensuring you use the RS256 algorithm and sign it with the corresponding private key.

I recommend saving it to an environment variable for easy access:

```bash
export JWT_TOKEN=your-generated-jwt-token
```

### Email Configuration (Gmail Example)

To send emails via Gmail, you need to:

1. Enable 2-factor authentication on your Google account
2. Generate an App Password: [https://myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords)
3. Set the following environment variables:

```bash
export SMTP_SERVER=smtp.gmail.com
export SMTP_PORT=587
export SMTP_USERNAME=your-email@gmail.com
export SMTP_PASSWORD=your-16-char-app-password
export SMTP_SSL=false
export SMTP_CACERTFILE=/etc/ssl/certs/ca-certificates.crt
# Optional: for debugging TLS issues (INSECURE, dev-only)
export SMTP_TLS_VERIFY=false
```

### Discord Configuration

To receive Discord interactions (slash commands, buttons, etc.):

1. Create a Discord application at [Discord Developer Portal](https://discord.com/developers/applications)
2. Copy the Public Key from the **General Information** tab
3. Copy the Bot Token from the **Bot** tab
4. Set the environment variables:

```bash
export DISCORD_PUBLIC_KEY=your-hex-public-key
export DISCORD_BOT_TOKEN=Bot_your-bot-token
```

For local development without signature verification (INSECURE):

```bash
export DISCORD_SIGNATURE_DISABLE=1
```

See [DISCORD_SETUP.md](./DISCORD_SETUP.md) for detailed setup instructions.

### Optional Configuration

```bash
export PORT=4000              # HTTP port (default: 4000)
export PHX_SERVER=true        # Auto-start server
```

## Quick Start

1. Copy `.env.example` to `.env`:

```bash
cp .env.example .env
```

2. Edit `.env` with your actual values

3. Source the environment file:

```bash
source .env
```

4. Start the server:

```bash
mix phx.server
```

## Testing Email Configuration

You can test your email configuration using the Elixir interactive shell:

```bash
nr server
curl --verbose
  -H "Authorization: Bearer $JWT_TOKEN" \
	http://localhost:4000/api/email/test
```

## Production Configuration

For production deployments, also set:

```bash
export SECRET_KEY_BASE=$(mix phx.gen.secret)
export PHX_HOST=your-domain.com
```

## Docker Configuration

When using Docker, these environment variables should be passed as build arguments or runtime environment variables in your `docker-compose.yml` or Dockerfile.
