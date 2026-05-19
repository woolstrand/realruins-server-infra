# realruins-server-infra

Single-VPS infrastructure for woolstrand.art — Docker Compose, Caddy, Vapor 4,
WordPress, MySQL.

---

## Architecture

```
Internet
   │
   ▼
Caddy (80 / 443 / 443 UDP)
   ├── woolstrand.art             → vapor-prod  :8080
   ├── woolstrand.art/blog*       → wordpress-prod :80
   ├── api.woolstrand.art         → vapor-prod  :8080
   ├── staging.woolstrand.art     → vapor-staging :8080
   └── db.staging.woolstrand.art  → phpmyadmin  :80

Internal network (not exposed):
   vapor-prod, vapor-staging, wordpress-prod, phpmyadmin
       └── mysql:3306
```

Both production and staging run on the same VPS, controlled via Docker Compose
profiles.

---

## Repository layout

```
.
├── docker-compose.yml        # all services (profile-based)
├── caddy/
│   └── Caddyfile             # routing + automatic HTTPS
├── mysql/
│   └── init/
│       └── 01-init.sh        # creates databases + users on first start
├── scripts/
│   ├── deploy-prod.sh
│   ├── deploy-staging.sh
│   ├── backup-mysql.sh
│   └── restore-mysql.sh
├── docs/
│   ├── setup.md              # one-time VPS setup guide
│   └── deployment.md         # day-to-day operations
├── .env.example              # all required variables (copy → .env)
├── .env.prod.example         # production-only variable reference
└── .env.staging.example      # staging-only variable reference
```

---

## Quick start

```bash
# 1. Clone
git clone https://github.com/woolstrand/realruins-server-infra.git
cd realruins-server-infra

# 2. Configure
cp .env.example .env
nano .env          # fill in every TODO value

# 3. Deploy
./scripts/deploy-prod.sh      # start production
./scripts/deploy-staging.sh   # start staging
```

See [docs/setup.md](docs/setup.md) for full VPS prerequisites and first-run
WordPress setup.

---

## Services

| Service | Profile | Description |
|---------|---------|-------------|
| `caddy` | *(always)* | Reverse proxy + automatic HTTPS |
| `mysql` | *(always)* | Database (internal only, no public port) |
| `vapor-prod` | `prod` | Production Vapor 4 API |
| `wordpress-prod` | `prod` | Production WordPress blog |
| `vapor-staging` | `staging` | Staging Vapor 4 API |
| `phpmyadmin` | `staging` | DB admin UI at `db.woolstrand.art` |

## Volumes

| Volume | Contents |
|--------|----------|
| `mysql_data` | All MySQL databases |
| `wordpress_prod_uploads` | WordPress media uploads |
| `caddy_data` | TLS certificates |
| `caddy_config` | Caddy runtime config |

---

## Common commands

```bash
# Deploy / update
./scripts/deploy-prod.sh
./scripts/deploy-staging.sh

# Logs
docker compose logs -f vapor-prod
docker compose logs -f caddy

# Backup all databases
./scripts/backup-mysql.sh

# Restore a database
./scripts/restore-mysql.sh backups/realruins_prod_20240101_120000.sql.gz realruins_prod

# Reload Caddy after editing Caddyfile
docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile
```

---

## Domain migration

To switch to a different main domain in the future, follow the steps in
[docs/deployment.md § Domain migration](docs/deployment.md#domain-migration).

---

## Design principles

- No Kubernetes, Terraform, Ansible, or Swarm
- Reproducible: everything is in this repo
- Single `.env` file — easy to manage on one VPS
- Persistent volumes for data that must survive container restarts
- Ready for GitHub Actions CI/CD (scripts are idempotent and CI-friendly)
