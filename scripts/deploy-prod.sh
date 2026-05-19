#!/usr/bin/env bash
# scripts/deploy-prod.sh — Deploy (or update) production services.
#
# Usage: ./scripts/deploy-prod.sh
#
# What this does:
#   1. Pulls the latest images for production services (--pull always).
#   2. Starts / recreates production containers (vapor-prod, wordpress-prod)
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

echo "==> [prod] Starting production services (pulling latest images)..."
docker compose --profile prod up -d --pull always --remove-orphans

echo ""
echo "==> [prod] Service status:"
docker compose ps

echo ""
echo "==> [prod] Done. Production is running."
echo "    Logs: docker compose logs -f vapor-prod wordpress-prod caddy"
