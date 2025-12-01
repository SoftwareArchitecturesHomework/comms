#!/usr/bin/env bash

# Quick Docker build and run script for local testing
set -e

IMAGE_NAME="comms"
TAG="${TAG:-latest}"
FULL_IMAGE="${IMAGE_NAME}:${TAG}"

echo "🐳 Building Docker image: ${FULL_IMAGE}"
echo ""

# Build the image
docker build -t "${FULL_IMAGE}" .

echo ""
echo "✅ Build complete!"
echo ""
echo "📋 Next steps:"
echo ""
echo "1. Ensure you have a .env file with all required variables:"
echo "   cp .env.example .env"
echo "   # Edit .env with your values"
echo ""
echo "2. Generate a SECRET_KEY_BASE if you haven't already:"
echo "   docker run --rm ${FULL_IMAGE} /app/bin/comms eval 'IO.puts(:crypto.strong_rand_bytes(64) |> Base.encode64())'"
echo ""
echo "3. Run with docker-compose:"
echo "   docker-compose up"
echo ""
echo "4. Or run manually:"
echo "   docker run --rm --env-file .env -p 4000:4000 ${FULL_IMAGE}"
echo ""
