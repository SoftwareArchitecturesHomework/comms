# Environment Setup Guide

This guide explains how to set up the required environment variables for the Comms API.

## Required Environment Variables

### JWT Configuration

For asymmetric JWT verification, you need to provide a public key:

```bash
export JWT_PUBLIC_KEY="-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...
-----END PUBLIC KEY-----"
```

The public key should be in PEM format and match the private key used by your authentication service.

### Email Configuration (Gmail Example)

To send emails via Gmail, you need to:

1. Enable 2-factor authentication on your Google account
2. Generate an App Password: https://myaccount.google.com/apppasswords
3. Set the following environment variables:

```bash
export SMTP_SERVER=smtp.gmail.com
export SMTP_PORT=587
export SMTP_USERNAME=your-email@gmail.com
export SMTP_PASSWORD=your-16-char-app-password
export SMTP_SSL=false
```

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
iex -S mix
```

```elixir
# Create a test email
email = Swoosh.Email.new(
  to: "recipient@example.com",
  from: {"Comms API", System.get_env("SMTP_USERNAME")},
  subject: "Test Email",
  text_body: "This is a test email from the Comms API"
)

# Send it
Comms.Mailer.deliver(email)
```

## Production Configuration

For production deployments, also set:

```bash
export SECRET_KEY_BASE=$(mix phx.gen.secret)
export PHX_HOST=your-domain.com
```

## Docker Configuration

When using Docker, these environment variables should be passed as build arguments or runtime environment variables in your `docker-compose.yml` or Dockerfile.
