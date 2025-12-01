#!/usr/bin/env bash

# Docker Quick Reference Commands for Comms Service

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="comms"
TAG="${TAG:-latest}"

show_help() {
  cat << EOF
🐳 Docker Quick Commands for Comms Service

Usage: $0 [command]

Commands:
  build           Build the Docker image
  run             Run the container with .env file
  shell           Start a shell in the container
  secret          Generate a SECRET_KEY_BASE
  logs            Show logs from running container
  stop            Stop running container
  clean           Remove container and image
  test            Build and run a test container
  compose-up      Start with docker-compose
  compose-down    Stop docker-compose services
  help            Show this help message

Environment:
  TAG             Set image tag (default: latest)

Examples:
  $0 build
  TAG=v1.0.0 $0 build
  $0 run
  $0 secret

EOF
}

build_image() {
  echo "🔨 Building Docker image: ${IMAGE_NAME}:${TAG}"
  docker build -t "${IMAGE_NAME}:${TAG}" "${SCRIPT_DIR}"
  echo "✅ Build complete!"
}

run_container() {
  if [ ! -f "${SCRIPT_DIR}/.env" ]; then
    echo "❌ .env file not found. Please create it first:"
    echo "   cp .env.example .env"
    echo "   # Edit .env with your values"
    exit 1
  fi
  
  echo "🚀 Running container: ${IMAGE_NAME}:${TAG}"
  docker run --rm \
    --name comms-dev \
    --env-file "${SCRIPT_DIR}/.env" \
    -p 4000:4000 \
    "${IMAGE_NAME}:${TAG}"
}

shell_container() {
  echo "🐚 Starting shell in container..."
  docker run --rm -it \
    --env-file "${SCRIPT_DIR}/.env" \
    --entrypoint /bin/bash \
    "${IMAGE_NAME}:${TAG}"
}

generate_secret() {
  echo "🔐 Generating SECRET_KEY_BASE..."
  echo ""
  docker run --rm "${IMAGE_NAME}:${TAG}" \
    /app/bin/comms eval 'IO.puts(:crypto.strong_rand_bytes(64) |> Base.encode64())'
  echo ""
  echo "💡 Copy this value to your .env file as SECRET_KEY_BASE"
}

show_logs() {
  docker logs -f comms-dev 2>&1 || docker logs -f comms_comms_1 2>&1
}

stop_container() {
  echo "🛑 Stopping container..."
  docker stop comms-dev 2>/dev/null || echo "Container not running"
}

clean_all() {
  echo "🧹 Cleaning up..."
  docker stop comms-dev 2>/dev/null || true
  docker rm comms-dev 2>/dev/null || true
  docker rmi "${IMAGE_NAME}:${TAG}" 2>/dev/null || true
  echo "✅ Cleanup complete!"
}

test_container() {
  echo "🧪 Building and testing container..."
  build_image
  echo ""
  echo "Testing if container starts without errors..."
  timeout 10 docker run --rm \
    --env-file "${SCRIPT_DIR}/.env" \
    "${IMAGE_NAME}:${TAG}" || true
  echo ""
  echo "✅ Test complete (container should have reported missing env vars if any)"
}

compose_up() {
  echo "🚀 Starting with docker-compose..."
  docker-compose -f "${SCRIPT_DIR}/docker-compose.yml" up
}

compose_down() {
  echo "🛑 Stopping docker-compose services..."
  docker-compose -f "${SCRIPT_DIR}/docker-compose.yml" down
}

# Main command dispatch
case "${1:-help}" in
  build)
    build_image
    ;;
  run)
    run_container
    ;;
  shell)
    shell_container
    ;;
  secret)
    generate_secret
    ;;
  logs)
    show_logs
    ;;
  stop)
    stop_container
    ;;
  clean)
    clean_all
    ;;
  test)
    test_container
    ;;
  compose-up)
    compose_up
    ;;
  compose-down)
    compose_down
    ;;
  help|--help|-h)
    show_help
    ;;
  *)
    echo "❌ Unknown command: $1"
    echo ""
    show_help
    exit 1
    ;;
esac
