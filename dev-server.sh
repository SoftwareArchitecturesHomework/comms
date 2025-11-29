#!/usr/bin/env bash

# Development server startup script
# This script checks for required environment variables and starts the Phoenix server

set -e

echo "🔍 Checking environment configuration..."

# Check JWT configuration
if [ -z "$JWT_PUBLIC_KEY" ]; then
  echo "⚠️  Warning: JWT_PUBLIC_KEY not set. JWT verification will not work."
fi

# Check Email configuration
if [ -z "$SMTP_SERVER" ]; then
  echo "⚠️  Warning: SMTP_SERVER not set. Email sending will not work."
fi

if [ -z "$SMTP_USERNAME" ]; then
  echo "⚠️  Warning: SMTP_USERNAME not set. Email sending will not work."
fi

if [ -z "$SMTP_PASSWORD" ]; then
  echo "⚠️  Warning: SMTP_PASSWORD not set. Email sending will not work."
fi

echo ""
echo "📧 Email Configuration:"
echo "   Server: ${SMTP_SERVER:-not set}"
echo "   Username: ${SMTP_USERNAME:-not set}"
echo "   Port: ${SMTP_PORT:-587}"

echo ""
echo "🔐 JWT Configuration:"
if [ -n "$JWT_PUBLIC_KEY" ]; then
  echo "   Public Key: ✓ configured"
else
  echo "   Public Key: ✗ not configured"
fi

echo ""
echo "🚀 Starting Phoenix server..."
echo ""

# Set PHX_SERVER if not already set
export PHX_SERVER=true

exec mix phx.server
