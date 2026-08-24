#!/usr/bin/env bash
# =============================================================================
# 05-health-check.sh
# =============================================================================
# Linux Server Health Check Script
# - Reports system uptime and load average
# - Checks disk usage percentages
# - Reports memory usage
# - Verifies SSH service status
# - Verifies UFW status
# - Verifies Fail2Ban status
# - Reports the current user count
#
# Usage:   ./05-health-check.sh
# or     sudo ./05-health-check.sh
# =============================================================================

set -euo pipefail

# ——— Colour helpers ———————————————————————————————————————————————————————
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()    { echo -e "  [${GREEN}INFO${NC}]   $1"; }
warn()   { echo -e "  [${YELLOW}WARN${NC}]   $1"; }
error()  { echo -e "  [${RED}ERROR${NC}]  $1"; }

echo -e "\n${GREEN}========== Server Health Check ==========${NC}\n"

# ——— Uptime & Load —————————————————
UPTIME=$(uptype 2>/dev/null || cat /proc/uptime | awk '{print $1}')
UPTIME_PRETTY=$(uptime -p 2>/dev/null || echo "unknown")
LOAD=$(uptime | grep -oP 'load average: [\d.]+' | awk '{print $NF}')
echo -e "🖥️  Uptime:   ${UPTIME_PRETTY}"
echo -e "   Load avg: ${LOAD}${NC}"

# ——— Disk Usage —————————————————
echo -e "💾  Disk usage:"
df -h / | grep -v "^Filesystem" | awk '{print "   "/$6 ": " $5 " used (" $3 " / " $2 ")"}'

# ——— Memory Usage —————————————————
echo -e "🧠  Memory usage:"
free -h | grep -v "^\(Swapping\|MemTotal\|MemAvailable\)" | awk 'NR==1 {printf "   Total: %s used: %s (%.2f%%)\n", $2, $3, $3/$2*100}'

# ——— SSH Service —————————————————
if systemctl is-active --quiet sshd 2>/dev/null || systemctl is-active --quiet ssh 2>/dev/null; then
    echo -e "🔑  SSH:       ${GREEN}active${NC}"
else
    echo -e "🔑  SSH:       ${RED}inactive${NC}"
fi

# ——— UFW Status —————————————————
if ufw status | grep -q "active"; then
    echo -e "🛡️  UFW:       ${GREEN}active${NC}"
    ufw status | grep "COMMAND" | head -1
else
    echo -e "🛡️  UFW:       ${YELLOW}inactive${NC}"
fi

# ——— Fail2Ban Status —————————————————
if fail2ban-client status >/dev/null 2>&1; then
    echo -e "🚫  Fail2Ban: ${GREEN}running${NC}"
    fail2ban-client status ssh 2>/dev/null | head -5
else
    echo -e "🚫  Fail2Ban: ${YELLOW}not running${NC}"
fi

# ——— User Count —————————————————
USER_COUNT=$(who | wc -l)
echo -e "👥  Logged-in users: ${USER_COUNT}"

# ——— Summary & Recommendations —————————————————
echo -e "\n${GREEN}========================================${NC}"
echo -e "Health check complete"
echo -e "${GREEN}========================================${NC}\n"

warn "If any item shows RED/YELLOW, review the associated configuration:"
warn "  • SSH keys in 01-initial-setup.sh"
warn "  • UFW rules in 02-ufw-firewall.sh"
warn "  • Fail2Ban jail in 03-fail2ban.sh"
warn "  • Cron tasks in 04-cron-tasks.sh"