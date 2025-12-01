#!/usr/bin/env bash

# Production startup script that validates required environment variables
set -e

echo "🚀 Starting Comms Service..."
echo ""

MISSING_ENV=0

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

echo "🔐 JWT Configuration:"
require_env JWT_PUBLIC_KEY "Set JWT RS256 PEM format public key (JWT_PUBLIC_KEY)."

echo ""
echo "📧 Email Configuration:"
require_env SMTP_SERVER "Set SMTP server hostname (SMTP_SERVER)."
require_env SMTP_USERNAME "Set SMTP username (SMTP_USERNAME)."
require_env SMTP_PASSWORD "Set SMTP password (SMTP_PASSWORD)."
require_env SMTP_SSL "Set SMTP SSL usage (SMTP_SSL: true/false)."
echo "   Server: ${SMTP_SERVER:-not set}"
echo "   Username: ${SMTP_USERNAME:-not set}"
echo "   Port: ${SMTP_PORT:-587}"
echo "   SSL: ${SMTP_SSL:-false}"

echo ""
echo "🔗 Discord Configuration:"
require_env DISCORD_APP_ID "Set Discord application ID (DISCORD_APP_ID)."
require_env DISCORD_PUBLIC_KEY "Set Discord public key (DISCORD_PUBLIC_KEY)."
require_env DISCORD_BOT_TOKEN "Set Discord bot token (DISCORD_BOT_TOKEN)."

echo ""
echo "🧩 Runtime Configuration:"
require_env PHX_HOST "Set Phoenix host (PHX_HOST)."
require_env PORT "Set service port (PORT)."
require_env SECRET_KEY_BASE "Set secret key base (SECRET_KEY_BASE). Generate with: mix phx.gen.secret"
echo "   PHX_HOST: ${PHX_HOST}"
echo "   PORT: ${PORT}"
echo "   PHX_SERVER: ${PHX_SERVER:-true}"

# Optional configurations
if [ -n "$CORE_SERVICE_HTTP" ]; then
  echo "   CORE_SERVICE_HTTP: ${CORE_SERVICE_HTTP}"
fi

if [ -n "$DNS_CLUSTER_QUERY" ]; then
  echo "   DNS_CLUSTER_QUERY: ${DNS_CLUSTER_QUERY}"
fi

if [ "$JWT_DEBUG" = "1" ]; then
  echo "   JWT_DEBUG: enabled"
fi

if [ "$DISCORD_SIGNATURE_DISABLE" = "1" ]; then
  echo "   ⚠️  DISCORD_SIGNATURE_DISABLE: enabled (NOT recommended for production)"
fi

if [ "$MISSING_ENV" = "1" ]; then
  echo ""
  echo "❗ Please set the missing required environment variables before starting the server."
  echo ""
  echo "💡 Tip: You can generate a SECRET_KEY_BASE with:"
  echo "   docker run --rm <image> /app/bin/comms eval 'IO.puts(:crypto.strong_rand_bytes(64) |> Base.encode64())'"
  exit 1
fi

echo ""
echo "✅ All required environment variables are set"
echo ""
echo "ℹ️  Discord commands should be installed after first startup:"
echo "   docker exec <container> /app/bin/comms rpc 'Comms.Discord.Registrar.install_global_commands()'"
echo ""
echo "🎉 Starting server..."
echo ""

# Set PHX_SERVER if not already set
export PHX_SERVER=${PHX_SERVER:-true}

# Start the release
exec /app/bin/comms start
