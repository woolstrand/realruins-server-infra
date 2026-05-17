#!/usr/bin/env bash
# scripts/restore-mysql.sh — Restore a MySQL database from a backup file.
#
# Usage:
#   ./scripts/restore-mysql.sh <backup_file.sql.gz> <database_name>
#
# Example:
#   ./scripts/restore-mysql.sh backups/realruins_prod_20240101_120000.sql.gz realruins_prod
#
# WARNING: This overwrites the target database. The database must already exist.
#          The MySQL container (woolstrand-mysql-1) must be running.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

cd "$REPO_DIR"

BACKUP_FILE="${1:-}"
DB_NAME="${2:-}"

if [[ -z "$BACKUP_FILE" ]] || [[ -z "$DB_NAME" ]]; then
  echo "Usage: $0 <backup_file.sql.gz> <database_name>" >&2
  echo ""
  echo "Example:"
  echo "  $0 backups/realruins_prod_20240101_120000.sql.gz realruins_prod" >&2
  exit 1
fi

if [[ ! -f "$BACKUP_FILE" ]]; then
  echo "Error: Backup file not found: ${BACKUP_FILE}" >&2
  exit 1
fi

if [[ ! -f .env ]]; then
  echo "Error: .env not found." >&2
  exit 1
fi

set -a
# shellcheck source=/dev/null
source .env
set +a

echo "WARNING: This will overwrite the '${DB_NAME}' database."
echo "         All existing data will be lost."
echo ""
read -r -p "Type the database name to confirm: " CONFIRM

if [[ "$CONFIRM" != "$DB_NAME" ]]; then
  echo "Aborted." >&2
  exit 1
fi

echo ""
echo "==> Restoring '${DB_NAME}' from '${BACKUP_FILE}'..."
gunzip -c "$BACKUP_FILE" \
  | docker compose exec -T mysql \
      mysql \
        --user=root \
        --password="${MYSQL_ROOT_PASSWORD}" \
        "${DB_NAME}"

echo "==> Restore complete."
