# Initial VPS Setup

This guide covers one-time setup on a fresh Ubuntu 24.04 VPS before you run
any deployment scripts.

---

## 1. System prerequisites

```bash
# Update and install Docker
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y ca-certificates curl gnupg

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Verify
docker compose version
```

### Add your user to the docker group (optional, avoids sudo)

```bash
sudo usermod -aG docker $USER
# Log out and back in, or: newgrp docker
```

---

## 2. Clone this repository

```bash
git clone https://github.com/woolstrand/realruins-server-infra.git
cd realruins-server-infra
```

---

## 3. Create the environment file

```bash
cp .env.example .env
nano .env   # fill in every TODO value with strong random credentials
```

Generate strong passwords:

```bash
openssl rand -base64 32   # run once per password
```

---

## 4. Configure DNS

Point the following records to your VPS IP before starting services (Caddy
needs DNS to propagate for automatic HTTPS):

| Record | Type | Value |
|--------|------|-------|
| `woolstrand.art` | A | `<VPS IP>` |
| `api.woolstrand.art` | A | `<VPS IP>` |
| `staging.woolstrand.art` | A | `<VPS IP>` |
| `db.staging.woolstrand.art` | A | `<VPS IP>` |

---

## 5. Open firewall ports

```bash
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP  (Caddy)
sudo ufw allow 443/tcp   # HTTPS (Caddy)
sudo ufw allow 443/udp   # HTTP/3
sudo ufw enable
```

---

## 6. First deploy

Start shared infrastructure and both environments:

```bash
./scripts/deploy-prod.sh
./scripts/deploy-staging.sh
```

Or start everything at once:

```bash
docker compose --profile prod --profile staging up -d
```

Caddy will automatically obtain TLS certificates from Let's Encrypt once DNS
has propagated.

---

## 7. WordPress first-run

After the WordPress container starts for the first time:

1. Navigate to `https://woolstrand.art/blog/wp-admin/install.php`
2. Complete the installation wizard.
3. In **Settings → General** confirm that:
   - **WordPress Address (URL)** is `https://woolstrand.art`
   - **Site Address (URL)**      is `https://woolstrand.art/blog`
4. Go to **Settings → Permalinks** and click **Save Changes** to regenerate
   the `.htaccess` rewrite rules.

---

## 8. Restrict phpMyAdmin (recommended)

By default `db.woolstrand.art` is open to the internet. Restrict it to your
IP in `caddy/Caddyfile`:

```caddy
db.woolstrand.art {
    @blocked not remote_ip 203.0.113.1/32   # replace with your IP
    respond @blocked "Access denied" 403

    reverse_proxy phpmyadmin:80
}
```

Then reload Caddy:

```bash
docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile
```

---

## 9. Set up automated backups (optional)

Add a cron job to back up databases nightly:

```bash
crontab -e
# Add:
0 3 * * * /path/to/realruins-server-infra/scripts/backup-mysql.sh >> /var/log/mysql-backup.log 2>&1
```
