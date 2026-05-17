#!/usr/bin/env bash
# mysql/init/01-init.sh
#
# Creates production and staging databases and users on first container start.
# Runs automatically when the MySQL data directory is empty (fresh volume).
#
# Environment variables are injected via docker-compose.yml.
# DO NOT run this script manually against a live database.

set -euo pipefail

mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<-EOSQL
    -- ── Production: Vapor API ──────────────────────────────────────────────
    CREATE DATABASE IF NOT EXISTS \`${MYSQL_PROD_DB}\`
        CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

    CREATE USER IF NOT EXISTS '${MYSQL_PROD_USER}'@'%'
        IDENTIFIED BY '${MYSQL_PROD_PASSWORD}';

    GRANT ALL PRIVILEGES ON \`${MYSQL_PROD_DB}\`.* TO '${MYSQL_PROD_USER}'@'%';

    -- ── Production: WordPress ─────────────────────────────────────────────
    CREATE DATABASE IF NOT EXISTS \`${MYSQL_PROD_WP_DB}\`
        CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

    CREATE USER IF NOT EXISTS '${MYSQL_PROD_WP_USER}'@'%'
        IDENTIFIED BY '${MYSQL_PROD_WP_PASSWORD}';

    GRANT ALL PRIVILEGES ON \`${MYSQL_PROD_WP_DB}\`.* TO '${MYSQL_PROD_WP_USER}'@'%';

    -- ── Staging: Vapor API ────────────────────────────────────────────────
    CREATE DATABASE IF NOT EXISTS \`${MYSQL_STAGING_DB}\`
        CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

    CREATE USER IF NOT EXISTS '${MYSQL_STAGING_USER}'@'%'
        IDENTIFIED BY '${MYSQL_STAGING_PASSWORD}';

    GRANT ALL PRIVILEGES ON \`${MYSQL_STAGING_DB}\`.* TO '${MYSQL_STAGING_USER}'@'%';

    FLUSH PRIVILEGES;
EOSQL

echo "[init] Databases and users created successfully."
