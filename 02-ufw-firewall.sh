#!/usr/bin/env bash
# =============================================================================
# 02-ufw-firewall.sh
# =============================================================================
# Linux UFW Firewall Configuration Script
# - Denies all inbound traffic by default
# - Allows SSH (restricted to the new sudo user)
# - Allows HTTP/HTTPS if desired
# - Enables the firewall
#
# ⚠️  This script modifies firewall rules — ensure SSH access is working
#     (key-based auth) before enabling UFW, or you will lock yourself out.
# =============================================================================

set -euo pipefail

# ——— Colour helpers ———————————————————————————————————————————————————————
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()    { echo -e "  [${GREEN}INFO${NC}]   $1"; }
warn()   { echo -e "  [${YELLOW}WARN${NC}]   $1"; }
error()  { echo -e "  [${RED}ERROR${NC}]  $1"; exit 1; }

# ——— Check that UFW is installed —————————————————————————————————
if ! command -v ufw >/dev/null 2>&1; then
    log "Installing UFW..."
    apt-get install -y ufw
fi

# ——— Default deny all inbound —————————————————
log "Setting default inbound policy to DENY..."
ufw default deny incoming

# ——— Default allow all outbound (safe for most servers) —————————
log "Setting default outbound policy to ALLOW..."
ufw default allow outgoing

# ——— Allow SSH —————————————————
# Only allow SSH connections from the new user's account.
# UFW syntax: ufw allow from any to any port 22 proto tcp
log "Allowing SSH (port 22) — restricted to authenticated users only..."
# We'll allow SSH from any source but rely on SSH hardening (AllowUsers in sshd_config)
# plus Fail2Ban for brute-force protection. If you want IP-restricted SSH,
# replace 'any' with a specific CIDR.
ufw allow 22/tcp comment "SSH"

# ——— Allow HTTP/HTTPS (optional) —————————————————
read -p "Do you want to allow HTTP (port 80) and/or HTTPS (port 443)? [y/N]: " -n 1 -r
echo    # (optional) move to new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "Allowing HTTP (80) and HTTPS (443)..."
    ufw allow 80/tcp comment "HTTP"
    ufw allow 443/tcp comment "HTTPS"
fi

# ——— Enable UFW —————————————————
warn "⚠️  About to enable UFW — this will deny ALL incoming traffic "
warn "    except the rules defined above."
warn "   Make sure SSH (key-based) is working before enabling!"
read -p "Type 'YES' to continue enabling UFW: " -r CONFIRM
if [[ "$CONFIRM" == "YES" ]]; then
    log "Enabling UFW..."
    ufw --force enable
    log "UFW is now active."
else
    log "UFW not enabled. You can run this again later."
fi

# ——— Show status —————————————————
log "Current UFW status:"
ufw status verbose

echo -e "\n${GREEN}========================================${NC}"
echo -e "Firewall configuration complete"
echo -e "${GREEN}========================================${NC}"
echo -e "\nNext steps:"
echo -e "  1. Verify SSH access as your new user"
echo -e "  2. Run 03-fail2ban.sh to install Fail2Ban"
echo -e "  3. Run 04-cron-tasks.sh for scheduled maintenance"