#!/usr/bin/env bash
# scripts/backup-mysql.sh — Create timestamped MySQL database backups.
#
# Usage:
#   ./scripts/backup-mysql.sh                  # back up all configured databases
#   ./scripts/backup-mysql.sh --db <db_name>   # back up a single database
#
# Backups are stored as gzip-compressed SQL dumps in ./backups/.
# Files older than 30 days are automatically removed.
#
# The script requires the MySQL container (woolstrand-mysql-1) to be running.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="${BACKUP_DIR:-${REPO_DIR}/backups}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

cd "$REPO_DIR"

if [[ ! -f .env ]]; then
  echo "Error: .env not found." >&2
  exit 1
fi

# Load environment variables
set -a
# shellcheck source=/dev/null
source .env
set +a

mkdir -p "$BACKUP_DIR"

# ── Helper ──────────────────────────────────────────────────────────────────
dump_database() {
  local db_name="$1"
  local filename="${BACKUP_DIR}/${db_name}_${TIMESTAMP}.sql.gz"
  echo "==> Backing up: ${db_name} → ${filename}"
  docker compose exec -T mysql \
    mysqldump \
      --user=root \
      --password="${MYSQL_ROOT_PASSWORD}" \
      --single-transaction \
      --routines \
      --triggers \
      "${db_name}" \
  | gzip > "${filename}"
  echo "    Size: $(du -sh "${filename}" | cut -f1)"
}

# ── Main ────────────────────────────────────────────────────────────────────
if [[ "${1:-}" == "--db" ]] && [[ -n "${2:-}" ]]; then
  dump_database "$2"
else
  echo "==> Backing up all databases..."
  dump_database "${PROD_DB_NAME}"
  dump_database "${PROD_WP_DB_NAME}"
  dump_database "${STAGING_DB_NAME}"
fi

echo ""
echo "==> Backup complete. Files stored in: ${BACKUP_DIR}"

# Remove backups older than 30 days
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +30 -delete 2>/dev/null || true
echo "==> Cleaned up backups older than 30 days."
