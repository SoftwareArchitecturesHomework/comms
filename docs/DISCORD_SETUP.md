# Discord Interactions Setup

This guide explains how to set up and test Discord interactions for the Comms API.

## Overview

The Discord interactions endpoint (`/api/discord/interactions`) handles Discord application interactions, including:

- PING verification requests (type 1) - **Working** ✅
- Slash commands (type 2) - **Working** ✅
- Message components (type 3) - coming soon
- Modal submissions (type 5) - coming soon

**Important**: PING interactions are handled directly in the `VerifyDiscordSignature` plug, matching Discord's official JavaScript middleware behavior. This ensures the fastest possible response time for Discord's verification requests.

## Environment Variables

### Required for Production

```bash
# Your Discord application's public key (hex format)
# Found in Discord Developer Portal > Your App > General Information
export DISCORD_PUBLIC_KEY=your_hex_public_key_here

# Your Discord bot token for sending messages
export DISCORD_BOT_TOKEN=Bot_your_token_here
```

### Optional for Development/Testing

```bash
# Disable signature verification (INSECURE - only for local testing!)
export DISCORD_SIGNATURE_DISABLE=1
```

## Setting Up Discord Application

1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. Create a new application or select an existing one
3. Go to **General Information** tab
4. Copy the **Public Key** - this is your `DISCORD_PUBLIC_KEY`
5. Go to **Bot** tab
6. Copy the **Token** - this is your `DISCORD_BOT_TOKEN`
7. Go to **General Information** tab and find **Interactions Endpoint URL**
8. Set it to: `https://your-domain.com/api/discord/interactions`

## Testing the Endpoint

### Local Testing (Development)

For local testing, you need to expose your local server to the internet. Use a tool like ngrok:

```bash
# Start ngrok tunnel
ngrok http 4000

# You'll get a URL like: https://abc123.ngrok.io
# Use this as your Interactions Endpoint URL in Discord:
# https://abc123.ngrok.io/api/discord/interactions
```

### Manual Testing with curl

#### Test PING (with signature verification disabled)

```bash
export DISCORD_SIGNATURE_DISABLE=1
./test_discord_ping.sh
```

Or manually:

```bash
curl -X POST http://localhost:4000/api/discord/interactions \
  -H "Content-Type: application/json" \
  -d '{"type": 1}'
```

Expected response:

```json
{ "type": 1 }
```

#### Test with Discord Signature

When `DISCORD_SIGNATURE_DISABLE` is not set, the endpoint requires valid Discord signatures. Discord sends these headers:

- `X-Signature-Ed25519`: The signature
- `X-Signature-Timestamp`: The timestamp

The signature is computed over `timestamp + raw_body` using Ed25519.

## Discord Interaction Types

| Type | Name                             | Description                                             |
| ---- | -------------------------------- | ------------------------------------------------------- |
| 1    | PING                             | Discord verification request - must respond with type 1 |
| 2    | APPLICATION_COMMAND              | Slash command invocation                                |
| 3    | MESSAGE_COMPONENT                | Button, select menu interaction                         |
| 4    | APPLICATION_COMMAND_AUTOCOMPLETE | Autocomplete request                                    |
| 5    | MODAL_SUBMIT                     | Modal form submission                                   |

## Response Types

When responding to Discord interactions:

| Type | Name                                 | Description                                |
| ---- | ------------------------------------ | ------------------------------------------ |
| 1    | PONG                                 | Acknowledge a PING                         |
| 4    | CHANNEL_MESSAGE_WITH_SOURCE          | Respond with a message                     |
| 5    | DEFERRED_CHANNEL_MESSAGE_WITH_SOURCE | Acknowledge, will edit later               |
| 6    | DEFERRED_UPDATE_MESSAGE              | Acknowledge a component, will update later |
| 7    | UPDATE_MESSAGE                       | Update the message                         |

## Current Implementation Status

✅ **PING Handler** - Working

- Handled in `VerifyDiscordSignature` plug (before reaching controller)
- Responds to Discord verification requests instantly
- Returns `{"type": 1}` as required
- Matches Discord's official JavaScript middleware behavior

✅ **Slash Commands** - Working

- APPLICATION_COMMAND (type 2) interactions are supported
- Responds with CHANNEL_MESSAGE_WITH_SOURCE (type 4)
- Errors are shown as ephemeral messages (only visible to the user)

⏸️ **Message Components** - Not yet implemented
⏸️ **Modals** - Not yet implemented

## Implementation Details

### How PING Works

Unlike most interactions, PING is handled directly in the `VerifyDiscordSignature` plug, not in the controller. This matches Discord's official behavior where PING responses happen in the verification middleware:

1. Discord sends POST to `/api/discord/interactions` with `{"type": 1}`
2. Request hits `VerifyDiscordSignature` plug
3. Plug verifies Ed25519 signature (or skips if `DISCORD_SIGNATURE_DISABLE=1`)
4. Plug checks if `type == 1`
5. If PING, responds immediately with `{"type": 1}` and halts the request
6. Non-PING interactions continue to the controller

This ensures the fastest possible response time for Discord's verification.

## Troubleshooting

### Signature verification failing

If you get "Invalid discord signature" errors:

1. Ensure `DISCORD_PUBLIC_KEY` is set correctly
2. Verify the public key matches your Discord application
3. Check that the public key is in hex format
4. For testing, you can temporarily disable verification with `DISCORD_SIGNATURE_DISABLE=1`

### Discord can't verify the endpoint

1. Ensure your server is publicly accessible
2. The endpoint must respond to PING within 3 seconds
3. Check that the response is exactly `{"type":1}`
4. Verify SSL/TLS is working correctly if using HTTPS

### Port is already in use

```bash
# Find the process using port 4000
lsof -ti:4000

# Kill the process
kill $(lsof -ti:4000)

# Or restart the server
./dev-server.sh
```

## References

- [Discord Interactions Documentation](https://discord.com/developers/docs/interactions/receiving-and-responding)
- [Discord Slash Commands](https://discord.com/developers/docs/interactions/application-commands)
- [Ed25519 Signature Verification](https://discord.com/developers/docs/interactions/receiving-and-responding#security-and-authorization)
