#!/usr/bin/env bash
# scripts/deploy-staging.sh — Deploy (or update) staging services.
#
# Usage: ./scripts/deploy-staging.sh
#
# What this does:
#   1. Pulls the latest images for staging services (--pull always).
#   2. Starts / recreates staging containers (vapor-staging, phpmyadmin)
#      and the shared infrastructure (caddy, mysql) if not already running.
#   3. Removes any orphaned containers from previous deployments.
#   4. Regenerates the Patreon progress dashboard image, which does not
#      survive container recreation (it would 404 until the next scheduled run).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

cd "$REPO_DIR"

if [[ ! -f .env ]]; then
  echo "Error: .env not found." >&2
  echo "       Copy .env.example to .env and fill in all values." >&2
  exit 1
fi

echo "==> [staging] Starting staging services (pulling latest images)..."
docker compose --profile staging up -d --pull always --remove-orphans

echo ""
echo "==> [staging] Regenerating progress dashboard..."
# Retries cover the few seconds Vapor needs to start (Caddy answers 502 meanwhile).
# A failure here is reported but does not fail the deploy.
if ! curl -fsS --retry 10 --retry-delay 3 --retry-all-errors --max-time 120 \
    https://staging.woolstrand.art/generateProgressDashboard; then
  echo "    WARNING: progress dashboard generation failed; check: docker compose logs vapor-staging" >&2
fi
echo ""

echo ""
echo "==> [staging] Service status:"
docker compose ps

echo ""
echo "==> [staging] Done. Staging is running."
echo "    Logs: docker compose logs -f vapor-staging phpmyadmin"
