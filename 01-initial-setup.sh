#!/usr/bin/env bash
# =============================================================================
# 01-initial-setup.sh
# =============================================================================
# Linux Server Initial Setup Script
# - Creates a sudo user for daily use
# - Configures SSH key-based authentication
# - Hardens SSH settings
# - Runs system updates
#
# ⚠️  This script is educational — review each step before running on production.
# =============================================================================

set -euo pipefail

# ——— Colour helpers ———————————————————————————————————————————————————————
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Colour

log()    { echo -e "  [${GREEN}INFO${NC}]   $1"; }
warn()   { echo -e "  [${YELLOW}WARN${NC}]   $1"; }
error()  { echo -e "  [${RED}ERROR${NC}]  $1"; exit 1; }

# ——— Detect root ———————————————————————————————————————————————————————
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root (or with sudo)."
fi

# ——— Input: new username —————————————————————————————————————————————
read -p "Enter a username for a new sudo user (e.g. devadmin): " NEWUSER
if [[ -z "$NEWUSER" ]]; then
    error "Username cannot be empty."
fi

# ——— Create the user —————————————————————————————————————————————
if id -u "$NEWUSER" >/dev/null 2>&1; then
    warn "User '$NEWUSER' already exists. Skipping creation."
else
    log "Creating user '$NEWUSER'..."
    useradd -m -s /bin/bash "$NEWUSER"
    warn "Set a strong password for '$NEWUSER' and log in once to verify."
fi

# ——— Add user to sudo (apt default group is 'sudo' on Ubuntu) —————————
log "Adding '$NEWUSER' to sudo group..."
usermod -aG sudo "$NEWUSER"

# ——— Set up SSH directory for the new user —————————————————————
SSH_DIR="/home/$NEWUSER/.ssh"
mkdir -p "$SSH_DIR"
chown "$NEWUSER:$NEWUSER" "$SSH_DIR"
chmod 700 "$SSH_DIR"

log "SSH directory created at $SSH_DIR"
chmod 700 /home/"$NEWUSER"

# ——— Generate SSH key pair (if none exists) —————————————————
KEY_FILE="/home/$NEWUSER/.ssh/id_rsa"
if [[ -f "$KEY_FILE" ]]; then
    warn "SSH key already exists at $KEY_FILE — skipping generation."
else
    log "Generating a new SSH key pair (press Enter for defaults)..."
    su -s /bin/bash "$NEWUSER" -c "ssh-keygen -t rsa -b 4096 -C \"$NEWUSER@server\""
fi

# ——— Copy public key to authorized_keys —————————————————
PUB_KEY="/home/$NEWUSER/.ssh/id_rsa.pub"
AUTH_KEYS="/home/$NEWUSER/.ssh/authorized_keys"
if [[ -f "$PUB_KEY" ]]; then
    if [[ -f "$AUTH_KEYS" ]]; then
        # Append if not already present
        if ! grep -qF "$(cat "$PUB_KEY")" "$AUTH_KEYS"; then
            cat "$PUB_KEY" >> "$AUTH_KEYS"
            log "Public key appended to authorized_keys."
        else
            log "Public key already present in authorized_keys."
        fi
    else
        log "Creating authorized_keys with the new public key."
        cp "$PUB_KEY" "$AUTH_KEYS"
        chown "$NEWUSER:$NEWUSER" "$AUTH_KEYS"
        chmod 600 "$AUTH_KEYS"
    fi
else
    error "Public key not found at $PUB_KEY — cannot proceed with key auth."
fi

chmod 600 "$AUTH_KEYS"
chown "$NEWUSER:$NEWUSER" /home/"$NEWUSER"/.ssh

# ——— Harden SSH configuration —————————————————
log "Applying SSH hardening settings..."
SSHD_CONFIG="/etc/ssh/sshd_config"

# These settings are written as a drop-in snippet so the admin can review
# them before restarting sshd.
SSH_DROPIN="/etc/ssh/sshd_config.d/hardening.conf"
mkdir -p /etc/ssh/sshd_config.d

cat > "$SSH_DROPIN" <<'EOF'
# --- BEGIN HARDENING SNIPPET (applied by 01-initial-setup.sh) ---
# Disable root login
PermitRootLogin no

# Disable password authentication (key-only auth)
PasswordAuthentication no

# Limit allowed users
AllowUsers $NEWUSER

# Disable empty passwords
PermitEmptyPasswords no

# Set idle timeout (seconds)
IdleTimeout 300

# Log level for security auditing
LogLevel VERBOSE
# --- END HARDENING SNIPPET ---
EOF

chmod 644 "$SSH_DROPIN"
log "SSH hardening drop-in written to $SSH_DROPIN"
log "Remember to test SSH access as '$NEWUSER' before disabling password auth globally."
log "After verification: systemctl restart sshd"

# ——— System update —————————————————
log "Running apt update && apt upgrade -y..."
apt-get update
apt-get upgrade -y

# ——— Summary —————————————————
echo -e "\n${GREEN}========================================${NC}"
echo -e "Initial setup complete for user: ${NEWUSER}"
echo -e "${GREEN}========================================${NC}"
echo -e "\nNext steps:"
echo -e "  1. Test SSH login as ${NEWUSER} using your key"
echo -e "  2. Verify sudo access:   sudo ls"
echo -e "  3. Run 02-ufw-firewall.sh to configure the firewall"
echo -e "  4. Run 03-fail2ban.sh to install intrusion prevention"