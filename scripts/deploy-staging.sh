#!/usr/bin/env bash
# scripts/deploy-staging.sh — Deploy (or update) staging services.
#
# Usage: ./scripts/deploy-staging.sh
#
# What this does:
#   1. Pulls the latest images for staging services.
#   2. Starts / recreates staging containers (vapor-staging, phpmyadmin)
#      and the shared infrastructure (caddy, mysql) if not already running.
#   3. Removes any orphaned containers from previous deployments.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

cd "$REPO_DIR"

if [[ ! -f .env ]]; then
  echo "Error: .env not found." >&2
  echo "       Copy .env.example to .env and fill in all values." >&2
  exit 1
fi

echo "==> [staging] Pulling latest images..."
docker compose --profile staging pull

echo "==> [staging] Starting staging services..."
docker compose --profile staging up -d --remove-orphans

echo ""
echo "==> [staging] Service status:"
docker compose ps

echo ""
echo "==> [staging] Done. Staging is running."
echo "    Logs: docker compose logs -f vapor-staging phpmyadmin"
