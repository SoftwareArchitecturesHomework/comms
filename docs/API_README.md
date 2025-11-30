# Comms Service

A Phoenix-based messaging service designed to run in a containerized environment (Docker/Kubernetes). This service provides email sending capabilities and WebSocket channels for Discord bot integration.

## Features

- **Email API**: Send emails via REST API with pre-made templates
- **Discord Bot Channel**: WebSocket channel for Discord bot real-time communication
- **JWT Middleware**: Verified with RS256 Joken signer and claims extraction
- **Health Check**: Basic health check endpoint for orchestration tools

## Project Structure

```
lib/
├── comms/                          # Business logic
│   ├── application.ex              # Application supervisor
│   └── mailer.ex                   # Swoosh mailer
├── comms_web/                      # Web interface
│   ├── channels/                   # Phoenix Channels
│   │   ├── discord_channel.ex      # Discord bot WebSocket channel
│   │   └── user_socket.ex          # Socket configuration
│   ├── controllers/                # API controllers
│   │   ├── email_controller.ex     # Email sending endpoint
│   │   ├── error_json.ex           # Error responses
│   │   └── health_controller.ex    # Health check endpoint
│   ├── emails/                     # Email templates
│   │   ├── base_email.ex           # Base email helpers
│   │   └── welcome_email.ex        # Example welcome email
│   ├── plugs/                      # Custom plugs
│   │   ├── extract_claims.ex       # JWT claims extraction (TODO)
│   │   └── verify_jwt.ex           # JWT verification (TODO)
│   ├── endpoint.ex                 # Phoenix endpoint
│   ├── router.ex                   # Routes
│   └── telemetry.ex                # Telemetry setup
└── comms_web.ex                    # Web module definitions
```

## API Endpoints

### Health Check

```bash
GET /health

Response:
{
  "status": "ok",
  "service": "comms"
}
```

### Send Email

```bash
POST /api/emails
Content-Type: application/json

{
  "template": "welcome",
  "to": "user@example.com",
  "params": {
    "name": "John Doe"
  }
}

Response (success):
{
  "status": "success",
  "message": "Email sent successfully"
}

Response (error):
{
  "status": "error",
  "message": "Failed to send email"
}
```

### Notification Endpoints (CommsService RPC Mapping)

All endpoints require `Authorization: Bearer <JWT>`.

Base path: `/api/notifications/*`

```
POST /api/notifications/user-added
{"project":{"id":1,"name":"Alpha"},"manager":{"id":2,"name":"Alice","email":"alice@example.com"},"member":{"id":5,"name":"Bob","email":"bob@example.com"}}
Response: {"success":true,"meta":{"sent":1}}

POST /api/notifications/user-removed
{"project":{"id":1,"name":"Alpha"},"manager":{"id":2,"name":"Alice","email":"alice@example.com"},"member":{"id":5,"name":"Bob","email":"bob@example.com"}}
Response: {"success":true,"meta":{"sent":1}}

POST /api/notifications/project-completed
{"project":{"id":1,"name":"Alpha"},"manager":{"id":2,"name":"Alice","email":"alice@example.com"},"member":{"id":5,"name":"Bob","email":"bob@example.com"},"summary":"Delivered all milestones."}
Response: {"success":true,"meta":{"sent":1}}

POST /api/notifications/task-assigned
{"task":{"id":9,"details":{"start":1732972800,"end":1733059200,"name":"Prepare Report","description":"Compile Q4 metrics"}},"assigner":{"id":2,"name":"Alice","email":"alice@example.com"},"assignee":[{"id":5,"name":"Bob","email":"bob@example.com"},{"id":6,"name":"Carol","email":"carol@example.com"}]}
Response: {"success":true,"meta":{"sent":2}}

POST /api/notifications/task-completed
{"task":{"id":9,"details":{"name":"Prepare Report","description":"Compiled Q4 metrics"}},"assigner":{"id":2,"name":"Alice","email":"alice@example.com"},"assignee":[{"id":5,"name":"Bob","email":"bob@example.com"}]}
Response: {"success":true,"meta":{"sent":2}}

POST /api/notifications/task-permission-request
{"task":{"id":9,"details":{"name":"Prepare Report","description":"Need export permissions"}},"assigner":{"id":2,"name":"Alice","email":"alice@example.com"},"assignee":[{"id":5,"name":"Bob","email":"bob@example.com"}]}
Response: {"success":true,"meta":{"sent":1}}
```

## WebSocket Channels

### Discord Channel

Connect to the Discord channel for real-time communication:

**Endpoint**: `ws://localhost:4000/socket/websocket?token=YOUR_TOKEN`

**Channel**: `discord:lobby`

**Events**:

- `send_message` - Send a message to the channel

  ```json
  {
  	"content": "Hello from Discord bot"
  }
  ```

- `new_message` - Receive messages from the channel
  ```json
  {
  	"content": "Message content",
  	"timestamp": "2025-11-03T12:00:00Z"
  }
  ```

## Email Templates

Email templates are located in `lib/comms_web/templates/email`. Each template should:

## JWT Authentication

Implemented with `Joken` RS256 signer. Set `JWT_PUBLIC_KEY` to the PEM string. `VerifyJWT` assigns decoded claims to `conn.assigns.claims`.

Failure case returns:

```
401 {"error":"Invalid token"}
```

## Development

### Setup

```bash
# Get dependencies
mix deps.get

# Start the server
mix phx.server
```

### Testing

```bash
# Run all tests
mix test

# Run with coverage
mix test --cover
```

### Pre-commit Checks

```bash
# Run all pre-commit checks (compile, format, test)
mix precommit
```

## Docker Deployment

The service is designed to run in a containerized environment. Make sure to:

1. Configure email adapter (SMTP, SendGrid, etc.) in `config/runtime.exs`
2. Set JWT verifier public keys
3. Configure Discord bot

### Environment Variables

Refer to [`.env.example`](../.env.example) for environment variables.

## Production Configuration

Update `config/runtime.exs` for production settings:

- Email adapter (change from Local to SMTP, SendGrid, etc.)
- SSL configuration
- CORS settings if needed

## Next Steps

- [x] Implement JWT verification with a real library
- [x] Add more email templates
- [ ] Implement Discord bot token authentication
- [ ] Implement email queuing for reliability
