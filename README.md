# Comms

A Phoenix-based microservice API for handling communications including email sending, Discord bot integration, and inter-service communication.

## Features

- **Email Service**: Send emails via SMTP (configured for Gmail or other providers)
- **JWT Verification**: Asymmetric JWT token verification for secure inter-service communication
- **Discord Integration**: (Coming soon) Discord bot communication
- **No Database**: Stateless API design for maximum scalability

## Getting Started

### Prerequisites

- Elixir 1.15+ and Erlang/OTP 26+
- Mix build tool

### Installation

1. Clone the repository
2. Install dependencies:

```bash
mix deps.get
```

### Environment Configuration

This application requires environment variables for JWT and email configuration. See [ENV_SETUP.md](ENV_SETUP.md) for detailed setup instructions.

**Quick setup:**

1. Copy the example environment file:

```bash
cp .env.example .env
```

2. Edit `.env` with your actual values:

- `JWT_PUBLIC_KEY`: Your RSA public key (PEM format) for RS256 verification
- `SMTP_*`: Your email server credentials (Gmail example provided)

3. Source the environment:

```bash
source .env
```

4. Start the server:

```bash
./dev-server.sh
# or
mix phx.server
```

### Using Gmail for Email

To use Gmail as your SMTP provider:

1. Enable 2FA on your Google account
2. Generate an App Password at https://myaccount.google.com/apppasswords
3. Set the environment variables as shown in `.env.example`

## Development

Run tests:

```bash
mix test
```

Run with format checking and compilation warnings:

```bash
mix precommit
```

## Project Structure

This is a Phoenix API-only application (no database, no LiveView):

- `lib/comms/` - Core business logic
  - `auth/jwt.ex` - JWT verification module
  - `mailer.ex` - Email configuration
- `lib/comms_web/` - Web interface
  - `controllers/` - API endpoints
  - `router.ex` - Route definitions

## Other docs

- [Environment Setup](docs/ENV_SETUP.md)
- [API Documentation](docs/API_README.md)
- [Docker Deployment Guide](README.Docker.md) - Production deployment with Docker
