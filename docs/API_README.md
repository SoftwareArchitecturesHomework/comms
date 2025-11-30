# Comms Service

A Phoenix-based messaging service designed to run in a containerized environment (Docker/Kubernetes). This service provides email sending capabilities and WebSocket channels for Discord bot integration.

## Features

- **Email API**: Send emails via REST API with pre-made templates
- **Discord Bot Channel**: WebSocket channel for Discord bot real-time communication
- **JWT Middleware** (placeholder): JWT verification and claims extraction plugs
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

Email templates are located in `lib/comms_web/emails/`. Each template should:

1. Import `Swoosh.Email` for email building functions
2. Import `CommsWeb.Emails.BaseEmail` for common helpers
3. Provide a `build/2` function that returns a `Swoosh.Email` struct
4. Include both HTML and text versions

### Creating a New Email Template

```elixir
defmodule CommsWeb.Emails.MyTemplate do
  import Swoosh.Email
  import CommsWeb.Emails.BaseEmail

  def build(to_email, %{param1: param1} = _params) do
    new_email(to_email)
    |> subject("My Subject")
    |> html_body(html_content(param1))
    |> text_body(text_content(param1))
  end

  defp html_content(param1) do
    # Your HTML template
  end

  defp text_content(param1) do
    # Your text template
  end
end
```

Then update `EmailController.build_and_send_email/3` to handle the new template.

## JWT Authentication (TODO)

The service includes placeholder JWT plugs that need to be implemented:

1. **Add a JWT library** to `mix.exs`:

   ```elixir
   {:joken, "~> 2.6"}
   # or
   {:guardian, "~> 2.3"}
   ```

2. **Implement `CommsWeb.Plugs.VerifyJWT`**:

   - Verify the JWT signature
   - Check expiration
   - Validate claims

3. **Implement `CommsWeb.Plugs.ExtractClaims`**:

   - Extract user information from verified token
   - Assign to `conn.assigns.claims`

4. **Use in router**:

   ```elixir
   pipeline :authenticated do
     plug :accepts, ["json"]
     plug CommsWeb.Plugs.VerifyJWT
     plug CommsWeb.Plugs.ExtractClaims
   end

   scope "/api", CommsWeb do
     pipe_through [:api, :authenticated]
     post "/emails", EmailController, :send_email
   end
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

1. Set environment variables for database connection
2. Configure email adapter (SMTP, SendGrid, etc.) in `config/runtime.exs`
3. Set JWT secret keys
4. Configure Discord bot token validation

### Environment Variables

```bash
SECRET_KEY_BASE=your_secret_key_base
PHX_HOST=your_host.com
PORT=4000

# Email configuration (example for SMTP)
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USERNAME=your_username
SMTP_PASSWORD=your_password

# JWT configuration
JWT_SECRET=your_jwt_secret
```

## Production Configuration

Update `config/runtime.exs` for production settings:

- Email adapter (change from Local to SMTP, SendGrid, etc.)
- SSL configuration
- CORS settings if needed

## Next Steps

- [ ] Implement JWT verification with a real library
- [ ] Add more email templates
- [ ] Implement Discord bot token authentication
- [ ] Add rate limiting
- [ ] Add request logging and monitoring
- [ ] Implement email queuing for reliability
- [ ] Add email template versioning
- [ ] Create integration tests for email sending
- [ ] Add channel tests for Discord integration
