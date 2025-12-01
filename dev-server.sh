#!/usr/bin/env bash

# This script checks for required environment variables and starts the Phoenix server
set -e

# Load .env if present
if [ -f ".env" ]; then
  echo "📦 Found .env file — exporting variables"
  set -a
  source .env
  set +a
else
  echo "ℹ️  No .env file found at project root"
fi

require_env() {
  local var_name=$1
  local message=$2
  if [ -z "${!var_name}" ]; then
    echo "❌ Missing $var_name. $message"
    MISSING_ENV=1
  else
    echo "   $var_name: ✓ configured"
  fi
}


require_env JWT_PUBLIC_KEY "Set JWT RS256 PEM format public key (JWT_PUBLIC_KEY)."
require_env SMTP_SERVER "Set SMTP server hostname (SMTP_SERVER)."
require_env SMTP_USERNAME "Set SMTP username (SMTP_USERNAME)."
require_env SMTP_PASSWORD "Set SMTP password (SMTP_PASSWORD)."
require_env SMTP_SSL "Set SMTP SSL usage (SMTP_SSL: true/false)."

echo ""
echo "📧 Email Configuration:"
echo "   Server: ${SMTP_SERVER:-not set}"
echo "   Username: ${SMTP_USERNAME:-not set}"
echo "   Port: ${SMTP_PORT:-587}"

echo "" 
echo "🔗 Discord Configuration:"
require_env DISCORD_APP_ID "Set Discord application ID (DISCORD_APP_ID)."
require_env DISCORD_PUBLIC_KEY "Set Discord public key (DISCORD_PUBLIC_KEY)."
require_env DISCORD_BOT_TOKEN "Set Discord bot token (DISCORD_BOT_TOKEN)."

echo ""
echo "🧩 Runtime Configuration:"
require_env PHX_HOST "Set Phoenix host (PHX_HOST)."
require_env PORT "Set service port (PORT)."
echo "   PHX_HOST: ${PHX_HOST}"
echo "   PORT: ${PORT}"
echo "   PHX_SERVER: ${PHX_SERVER:-true}"

if [ -n "$MISSING_ENV" ]; then
  echo ""
  echo "❗ Please set the missing required environment variables before starting the server."
  exit 1
fi

echo ""
echo "🚀 Starting Phoenix server..."
echo ""

# Set PHX_SERVER if not already set
export PHX_SERVER=${PHX_SERVER:-true}

# exec mix phx.server
mix discord.install_commands

exec mix phx.server
