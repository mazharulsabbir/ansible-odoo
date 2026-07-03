'''''''''# Ansible Odoo Deployment

Automated provisioning of a production-ready Odoo ERP server with PostgreSQL, Nginx reverse proxy, Python virtual environment, systemd service, Let's Encrypt SSL, automated backups, and security hardening.

## Features

- **Full-stack deployment**: Odoo, PostgreSQL, Nginx, SSL
- **Security hardening**: UFW firewall, fail2ban, secure configurations
- **Automated backups**: Daily database and filestore backups
- **Version flexibility**: Supports Odoo 15.0, 16.0, 17.0, 18.0, 19.0
- **Custom addons**: Easy deployment of custom modules
- **SSL/HTTPS**: Let's Encrypt certificate automation
- **Idempotent**: Safe to run multiple times

## Supported Versions

| Odoo Version | Python | Ubuntu | Status |
|--------------|--------|--------|--------|
| 15.0 | 3.8 | 20.04+ | Supported |
| 16.0 | 3.10 | 22.04 | Supported |
| 17.0 | 3.10 | 22.04 | Supported |
| 18.0 | 3.12 | 22.04+ | Supported |
| 19.0 | 3.12 | 22.04+ | Supported |

## Project Structure

```
ansible-odoo/
├── ansible.cfg                 # Ansible configuration
├── site.yml                    # Main deployment playbook
├── upgrade.yml                 # Odoo upgrade playbook
├── deploy_addons.yml           # Custom addons deployment
├── run_playbook.sh             # Helper script
├── inventory/
│   ├── hosts.ini               # SSH key-based inventory
│   └── hosts_password.ini      # Password-based inventory
├── group_vars/
│   ├── odoo_servers.yml        # Configuration variables
│   └── vault.yml               # Encrypted secrets (passwords)
└── roles/
    ├── common/                 # System setup, UFW, fail2ban
    ├── postgresql/             # Database installation & tuning
    ├── odoo/                   # Odoo installation & configuration
    └── nginx/                  # Reverse proxy & SSL
```

## Quick Start

### Prerequisites

**On your local machine:**

```bash
# Install Ansible
pip install ansible

# Install required collections
ansible-galaxy collection install community.general community.postgresql
```

**On your target server:**
- Ubuntu 20.04+ or 22.04 (recommended)
- Root or sudo access
- SSH access configured

### Step 1: Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/ansible-odoo.git
cd ansible-odoo
```

### Step 2: Configure Your Server Inventory

Edit `inventory/hosts.ini` for SSH key authentication (recommended):

```ini
[odoo_servers]
odoo-prod ansible_host=YOUR_SERVER_IP ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_rsa
```

Or use `inventory/hosts_password.ini` for password authentication.

### Step 3: Configure Sensitive Data

**Important:** You must configure passwords before deployment.

#### Option A: Simple Setup (for testing)

Edit `group_vars/odoo_servers.yml` directly:

```yaml
pg_password: "YOUR_STRONG_DATABASE_PASSWORD"
odoo_admin_passwd: "YOUR_STRONG_MASTER_PASSWORD"
```

#### Option B: Secure Setup with Ansible Vault (recommended for production)

1. Edit `group_vars/all/vault.yml` with your passwords:

```yaml
vault_pg_password: "YOUR_STRONG_DATABASE_PASSWORD"
vault_odoo_admin_passwd: "YOUR_STRONG_MASTER_PASSWORD"
```

2. Encrypt the vault file:

```bash
ansible-vault encrypt group_vars/all/vault.yml
```

3. Update `group_vars/odoo_servers.yml` to reference vault variables:

```yaml
pg_password: "{{ vault_pg_password }}"
odoo_admin_passwd: "{{ vault_odoo_admin_passwd }}"
```

**Generate strong passwords:**

```bash
# Using OpenSSL
openssl rand -base64 32

# Using pwgen
pwgen -s 32 1
```

### Step 4: Configure Odoo Settings

Edit `group_vars/odoo_servers.yml`:

```yaml
# Odoo Version
odoo_version: "17.0"              # 15.0, 16.0, 17.0, 18.0, or 19.0
python_version: "3.10"            # Match to Odoo version (see table above)

# Domain (required for SSL)
domain_name: "odoo.yourdomain.com"
letsencrypt_email: "admin@yourdomain.com"
enable_ssl: false                 # Set true after DNS is configured

# Database
pg_db: odoo_prod                  # Database name

# Performance tuning
odoo_workers: 4                   # Recommended: (CPU cores * 2) + 1
```

### Step 5: Deploy

```bash
# Dry run first (recommended)
ansible-playbook site.yml --check

# Full deployment
ansible-playbook site.yml

# With vault password prompt (if using encrypted vault)
ansible-playbook site.yml --ask-vault-pass

# With verbose output
ansible-playbook site.yml -v
```

## Configuration Reference

### Required Configuration Changes

Before deploying, you **MUST** change these values:

| File | Variable | Description |
|------|----------|-------------|
| `inventory/hosts.ini` | `ansible_host` | Your server IP address |
| `group_vars/odoo_servers.yml` | `pg_password` | PostgreSQL database password |
| `group_vars/odoo_servers.yml` | `odoo_admin_passwd` | Odoo master password |
| `group_vars/odoo_servers.yml` | `domain_name` | Your domain name |
| `group_vars/odoo_servers.yml` | `letsencrypt_email` | Email for SSL certificates |

### Optional Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `odoo_version` | `19.0` | Odoo version to install |
| `python_version` | `3.12` | Python version |
| `pg_db` | `odoo_prod` | Database name |
| `odoo_port` | `8069` | Odoo HTTP port |
| `odoo_workers` | `4` | Number of worker processes |
| `enable_ssl` | `false` | Enable Let's Encrypt SSL |

## Common Commands

### Deployment

```bash
# Full installation
ansible-playbook site.yml

# Deploy specific components only
ansible-playbook site.yml --tags "postgresql"
ansible-playbook site.yml --tags "odoo"
ansible-playbook site.yml --tags "nginx"

# Target a specific host
ansible-playbook site.yml -l odoo-prod

# Check connectivity
ansible odoo_servers -m ping
```

### Upgrades

```bash
# Upgrade Odoo to latest commit on current branch
ansible-playbook upgrade.yml

# Switch Odoo version (edit group_vars first)
ansible-playbook upgrade.yml
```

### Custom Addons

```bash
# Deploy addons from local directory
ansible-playbook deploy_addons.yml -e "local_addons_path=./my-addons/"

# Deploy addons from git repository
ansible-playbook deploy_addons.yml \
  -e "addon_repo=git@github.com:yourorg/your-addons.git" \
  -e "addon_branch=main"

# Deploy and update module in database
ansible-playbook deploy_addons.yml \
  -e "addon_repo=git@github.com:yourorg/your-addons.git" \
  -e "update_db=true" \
  -e "module_name=your_module"
```

## Enable SSL/HTTPS

1. Point your domain's DNS `A` record to your server IP
2. Wait for DNS propagation (can take up to 48 hours)
3. Update configuration:

```yaml
# group_vars/odoo_servers.yml
enable_ssl: true
domain_name: "odoo.yourdomain.com"
letsencrypt_email: "admin@yourdomain.com"
```

4. Run the nginx role:

```bash
ansible-playbook site.yml --tags "nginx"
```

## Server File Locations

| Path | Purpose |
|------|---------|
| `/opt/odoo/odoo-server/` | Odoo source code |
| `/opt/odoo/venv/` | Python virtual environment |
| `/opt/odoo/custom-addons/` | Custom modules |
| `/opt/odoo/data/` | Filestore and sessions |
| `/etc/odoo/odoo.conf` | Odoo configuration |
| `/var/log/odoo/odoo.log` | Application logs |
| `/var/backups/odoo/` | Database and filestore backups |

## Service Management

SSH into your server and run:

```bash
# Check status
sudo systemctl status odoo

# Restart Odoo
sudo systemctl restart odoo

# Stop Odoo
sudo systemctl stop odoo

# View live logs
sudo journalctl -u odoo -f

# View recent logs
sudo journalctl -u odoo --no-pager -n 100
```

## Security Considerations

### Passwords

- **Never commit real passwords** to version control
- Use Ansible Vault for production deployments
- Generate strong passwords (minimum 32 characters)

### Firewall

The deployment configures UFW with these rules:
- SSH (22): Allowed
- HTTP (80): Allowed
- HTTPS (443): Allowed
- Odoo ports (8069, 8072): Only from localhost (Nginx proxy)

### Database Security

- `list_db = False` in odoo.conf hides the database manager
- PostgreSQL uses MD5 password authentication
- Database password is required for all connections

### SSH Security

- fail2ban protects against brute force attacks
- Consider using SSH keys instead of passwords
- Consider changing the default SSH port

## Troubleshooting

### Check Odoo Logs

```bash
# Via Ansible
ansible odoo_servers -m command -a "journalctl -u odoo --no-pager -n 50"

# Or SSH directly
ssh root@YOUR_SERVER_IP "journalctl -u odoo -n 100"
```

### Check Nginx Configuration

```bash
ansible odoo_servers -m command -a "nginx -t"
```

### Check PostgreSQL Connection

```bash
ansible odoo_servers -m command -a "sudo -u odoo psql -d odoo_prod -c '\conninfo'"
```

### Common Issues

**Odoo won't start:**
- Check logs: `journalctl -u odoo -n 100`
- Verify Python dependencies: `/opt/odoo/venv/bin/pip list`
- Check configuration: `cat /etc/odoo/odoo.conf`

**Database connection failed:**
- Verify PostgreSQL is running: `systemctl status postgresql`
- Check pg_hba.conf authentication settings
- Verify password in odoo.conf matches vault

**SSL certificate issues:**
- Ensure DNS is pointing to server
- Check certbot logs: `cat /var/log/letsencrypt/letsencrypt.log`
- Verify domain: `dig +short yourdomain.com`

## Using Ansible Vault

### Encrypting Secrets

```bash
# Encrypt the vault file
ansible-vault encrypt group_vars/all/vault.yml

# Edit encrypted file
ansible-vault edit group_vars/all/vault.yml

# View encrypted file
ansible-vault view group_vars/all/vault.yml

# Re-encrypt with new password
ansible-vault rekey group_vars/all/vault.yml
```

### Running Playbooks with Vault

```bash
# Prompt for vault password
ansible-playbook site.yml --ask-vault-pass

# Use password file (for CI/CD)
echo "your-vault-password" > .vault_pass
chmod 600 .vault_pass
ansible-playbook site.yml --vault-password-file .vault_pass
```

**Note:** Never commit `.vault_pass` to version control.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `--check` mode
5. Submit a pull request

## License

MIT License - See [LICENSE](LICENSE) for details.

## Acknowledgments

- [Odoo](https://www.odoo.com/) - The ERP system
- [Ansible](https://www.ansible.com/) - Automation platform
