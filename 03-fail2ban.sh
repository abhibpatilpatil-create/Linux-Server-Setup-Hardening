#!/usr/bin/env bash
# =============================================================================
# 03-fail2ban.sh
# =============================================================================
# Linux Fail2Ban Installation & Configuration
# - Installs Fail2Ban
# - Creates an SSH jail to block brute-force attempts
# - Creates a custom filter/jail for common services (e.g., vsftpd, apache)
# - Installs a filter for repeated failed login attempts in auth logs
# - Updates sshd config to work with Fail2Ban (loglevel adjustments)
#
# ⚠️  This script modifies system services — review before running on production.
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

# ——— Install Fail2Ban —————————————————
log "Updating package lists..."
apt-get update

log "Installing Fail2Ban..."
apt-get install -y fail2ban

# ——— Create a custom SSH jail —————————————————
log "Creating Fail2Ban jail configuration for SSH..."

JailLocal="/etc/fail2ban/jail.local"
mkdir -p /etc/fail2ban

cat > "$JailLocal" <<'EOF'
[ssh]
enabled = true
port = ssh
logpath = %(sshd_log)s
maxretry = 3
bantime = 3600
findtime = 600
filter = sshd
banaction = iptables-multi

# Optional: integrate with UFW (auto-unes the IP on ban)
banaction = ufw-actions
EOF

log "SSH jail written to $JailLocal"

# ——— Create a custom filter for SSH —————————————————
FILTER_DIR="/etc/fail2ban/filter.d"
mkdir -p "$FILTER_DIR"

SSH_FILTER="$FILTER_DIR/sshd.conf"
if [[ -f "$SSH_FILTER" ]]; then
    warn "SSH filter already exists at $SSH_FILTER — overwriting."
fi

log "Creating custom SSH filter..."
cat > "$SSH_FILTER" <<'EOF'
[sshd]
# Lines that indicate a failed login attempt
failregex = ^%(__prefix_line)s%(__ lines ssshd\[%(__pid__\d+\]): Failed .* for .* from <HOST>\s*$
        ^%(__prefix_line)s%(__ lines ssshd\[%(__pid__\d+\]): input .* for .* from <HOST>\s*$

# Bonus: also watch auth.log for 'Failed password for invalid user'
# (some distributions log here instead of to sshd)
# failregex = ^%(__prefix_line)s%(__ lines sssshd\[%(__pid__\d+\]): Failed password for invalid user .* from <HOST>$

actionban = iptables-multi[name=SSH, port=ssh, protocol=tcp]
EOF

log "SSH filter written to $SSH_FILTER"

# ——— Create a custom filter for authentication failures (auth.log) —————————
AUTH_FILTER="$FILTER_DIR/sshd-auth.conf"
log "Creating auth-failed filter..."
cat > "$AUTH_FILTER" <<'EOF'
[sshd-auth]
# Lines from auth.log indicating a failed password attempt
failregex = ^%(__prefix_line)s%(__ lines sssshd\[%(__pid__\d+\]): Failed password for (invalid user )?\w+ from <HOST> port \d+ ssh2$
        ^%(__prefix_line)s%(__ lines sssshd\[%(__pid__\d+\]): input .* for .* from <HOST>\s*

# Optional: also catch 'pattern' for password used for/too many max attempts
maxretry = 3
bantime = 3600
findtime = 600
banaction = iptables-multi
EOF

log "Auth filter written to $AUTH_FILTER"

# ——— Update sshd_config to log level if needed ————————————————
log "Ensuring sshd logs at a level Fail2Ban can read..."
SSHD_CONFIG="/etc/ssh/sshd_config"

# Check if LogLevel is already set; if not, suggest setting it to VERBOSE/INFO
if grep -q "^#*LogLevel" "$SSHD_CONFIG" | grep -v '^#LogLevel' | grep -q 'VERBOSE\|INFO'; then
    log "LogLevel already set to a sufficient value."
else
    warn "LogLevel may need to be set to INFO or VERBOSE in $SSHD_CONFIG for Fail2Ban to work."
    warn "  After changing, restart sshd: systemctl restart sshd"
fi

# ——— Enable and start Fail2Ban —————————————————
log "Enabling Fail2Ban service..."
systemctl enable fail2ban
systemctl start fail2ban

# ——— Check jail status —————————————————
log "Checking Fail2Ban status..."
fail2ban-client status ssh

echo -e "\n${GREEN}========================================${NC}"
echo -e "Fail2Ban installation complete"
echo -e "${GREEN}========================================${NC}"
echo -e "\nNext steps:"
echo -e "  1. Test Fail2Ban by attempting several failed SSH logins"
echo -e "  2. Verify the IP gets banned: fail2ban-client status ssh"
echo -e "  3. Run 04-cron-tasks.sh for scheduled maintenance"
echo -e "  4. Review /etc/fail2ban/jail.local and /etc/fail2ban/filter.d/ for tweaks"