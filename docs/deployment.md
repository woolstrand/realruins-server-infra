# Deployment Guide

Day-to-day workflow for deploying and managing the woolstrand.art infrastructure.

---

## Prerequisites

- VPS set up per [docs/setup.md](setup.md)
- `.env` file present and filled in
- Docker Compose ≥ 2.20 installed
- SSH access to the VPS

---

## Automatic service restart

All Vapor (and other) containers are configured with `restart: unless-stopped`.
Docker will automatically restart them if they crash or exit unexpectedly —
providing the same protection that `supervisor` gave previously. No additional
process manager is required.

To verify the restart policy for a running container:

```bash
docker inspect --format '{{.HostConfig.RestartPolicy.Name}}' woolstrand-vapor-prod-1
```

To manually restart a service:

```bash
docker compose restart vapor-prod    # or vapor-staging
```

---

## Deploy production

```bash
./scripts/deploy-prod.sh
```

This pulls the latest `PROD_VAPOR_IMAGE` and restarts `vapor-prod` and
`wordpress-prod` (plus `caddy` and `mysql` if they are not running).

### Deploy a specific image tag

Update `PROD_VAPOR_IMAGE` in `.env` before running the script:

```bash
# e.g. pin to a specific release
PROD_VAPOR_IMAGE=ghcr.io/woolstrand/realruins-api:v1.2.3
```

---

## Deploy staging

```bash
./scripts/deploy-staging.sh
```

---

## Deploy everything at once

```bash
docker compose --profile prod --profile staging up -d --remove-orphans
```

---

## View logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f vapor-prod
docker compose logs -f caddy
docker compose logs -f mysql
```

---

## Reload Caddy (no downtime)

After editing `caddy/Caddyfile`:

```bash
docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile
```

---

## Domain migration

To change the main production domain (currently `woolstrand.art`):

1. Update DNS: point the new domain (A/AAAA records) to the VPS IP.
2. In `caddy/Caddyfile`, replace `woolstrand.art` (but NOT `api.woolstrand.art`
   or `staging.woolstrand.art`) with the new domain.
3. In `docker-compose.yml`, update `WORDPRESS_CONFIG_EXTRA`:
   ```yaml
   define('WP_HOME',   'https://<new-domain>/blog');
   define('WP_SITEURL','https://<new-domain>');
   ```
4. Reload Caddy:
   ```bash
   docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile
   ```
5. Restart WordPress so the new wp-config takes effect:
   ```bash
   docker compose restart wordpress-prod
   ```
6. In WordPress admin (Settings → Permalinks) click **Save Changes**.

> `api.woolstrand.art` and `staging.woolstrand.art` are independent of the main
> domain and require no changes — they always point to their respective Vapor apps.

---

## Database backups

### Manual backup (all databases)

```bash
./scripts/backup-mysql.sh
```

Dumps are saved to `./backups/` as `<db_name>_<timestamp>.sql.gz`.

### Manual backup (single database)

```bash
./scripts/backup-mysql.sh --db realruins_prod
```

### Restore a database

```bash
./scripts/restore-mysql.sh backups/realruins_prod_20240101_120000.sql.gz realruins_prod
```

You will be asked to type the database name to confirm before any data is overwritten.

---

## MySQL access (no public port)

MySQL is on the internal Docker network only. To run queries interactively:

```bash
# As root
docker compose exec mysql mysql -u root -p

# As application user
docker compose exec mysql mysql -u realruins_prod -p realruins_prod
```

---

## Updating Docker images

Images are pinned in `.env`. To update:

```bash
# Edit .env to point to the new tag, then:
./scripts/deploy-prod.sh    # or deploy-staging.sh
```

To update infrastructure images (Caddy, MySQL, WordPress, phpMyAdmin):

```bash
docker compose pull
docker compose --profile prod --profile staging up -d
```

---

## Stopping services

```bash
# Stop all
docker compose --profile prod --profile staging down

# Stop production only
docker compose stop vapor-prod wordpress-prod

# Stop staging only
docker compose stop vapor-staging phpmyadmin
```

> Stopping containers does **not** remove volumes — persistent data (MySQL,
> uploads, Caddy certs) is preserved.

---

## Viewing certificate status

```bash
docker compose exec caddy caddy list-modules
docker compose exec caddy cat /data/caddy/pki/acme/...
```

Or check renewal logs:

```bash
docker compose logs caddy | grep -i cert
```

---

## Future GitHub Actions integration

The deployment scripts are designed to be called from a CI/CD workflow:

```yaml
# .github/workflows/deploy-prod.yml (future)
- name: Deploy production
  run: ssh user@vps "cd ~/realruins-server-infra && ./scripts/deploy-prod.sh"
```

No changes to the scripts are needed.
