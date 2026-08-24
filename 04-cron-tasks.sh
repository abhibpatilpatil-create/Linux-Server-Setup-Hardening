#!/usr/bin/env bash
# =============================================================================
# 04-cron-tasks.sh
# =============================================================================
# Linux Cron Job Installation Script
# - Installs cron if not present
# - Sets up weekly system updates
# - Sets up daily log checks
# - Sets up disk usage monitoring
# - Sets up Fail2Ban ban expiry review
#
# ⚠️  This script modifies crontab — ensures existing cron jobs are not
#     overwritten accidentally.
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

# ——— Ensure cron is installed —————————————————
if ! command -v crontab >/dev/null 2>&1; then
    log "Installing cron..."
    apt-get install -y cron
    service cron start
else
    log "Cron is already installed."
fi

# ——— Back up existing crontab —————————————————
log "Backing up current crontab..."
crontab > "$HOME/crontab.backup.$(date +%Y%m%d%H%M%S)" 2>/dev/null || true

# ——— Read current crontab to avoid overwriting —————————————————
EXISTING=$(crontab -l 2>/dev/null || echo "")

# ——— Define new cron jobs —————————————————
# 1. Weekly system update every Sunday at 2am
WEEKLY_UPDATE="0 2 * * 0 /usr/bin/apt-get update && /usr/bin/apt-get upgrade -y >> /var/log/apt-update.log 2>&1"

# 2. Daily disk usage check at 3am, email root if > 80%
DAILY_DISK="0 3 * * * /usr/bin/df -h / | grep -v Filesystem | awk '{print $5}' | tr -d '%' | read USAGE; if [ "$USAGE" -gt 80 ]; then mail -s 'Disk Usage High' root; fi"

# 3. Daily Fail2Ban ban review at 4am (list IPs banned for > 24h)
FAIL2BAN_REVIEW="0 4 * * * fail2ban-client get ssh banlist >> /var/log/fail2ban-review.log 2>&1"

# 4. Weekly security log check at 5am Saturday
WEEKLY_SEC="0 5 * * 6 /bin/bash /opt/security-check.sh >> /var/log/security-check.log 2>&1"

# ——— Append new jobs (avoid duplicates) —————————————————
log "Installing cron jobs..."

# Weekly update
if echo "$EXISTING" | grep -qF "$WEEKLY_UPDATE"; then
    log "Weekly update cron job already exists — skipping."
else
    (crontab -l 2>/dev/null; echo "$WEEKLY_UPDATE") | crontab -
    log "Added weekly system update cron job (Sun 02:00)."
fi

# Daily disk check
if echo "$EXISTING" | grep -qF "$DAILY_DISK"; then
    log "Daily disk check cron job already exists — skipping."
else
    (crontab -l 2>/dev/null; echo "$DAILY_DISK") | crontab -
    log "Added daily disk usage check cron job (Daily 03:00)."
fi

# Fail2Ban review
if echo "$EXISTING" | grep -qF "$FAIL2BAN_REVIEW"; then
    log "Fail2Ban review cron job already exists — skipping."
else
    (crontab -l 2>/dev/null; echo "$FAIL2BAN_REVIEW") | crontab -
    log "Added Fail2Ban ban review cron job (Daily 04:00)."
fi

# Weekly security check — this references /opt/security-check.sh which you can create
# For now, just add a placeholder comment
if echo "$EXISTING" | grep -qF "$WEEKLY_SEC"; then
    log "Weekly security check cron job already exists — skipping."
else
    (crontab -l 2>/dev/null; echo "$WEEKLY_SEC") | crontab -
    log "Added weekly security check cron job (Sat 05:00)."
    warn "  Ensure /opt/security-check.sh exists or adjust the cron entry."
fi

log "Crontab successfully updated."
crontab -l

echo -e "\n${GREEN}========================================${NC}"
echo -e "Cron jobs installed"
echo -e "${GREEN}========================================${NC}"
echo -e "\nNext steps:"
echo -e "  1. Verify crontab:   crontab -l"
echo -e "  2. Adjust timing if needed (run 'crontab -e')"
echo -e "  3. Run 05-health-check.sh for on-demand diagnostics"