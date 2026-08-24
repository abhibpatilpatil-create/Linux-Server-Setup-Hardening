# 🛡️ Linux Server Hardening Checklist

A step‑by‑step checklist to verify each hardening step was applied correctly.

| # | Step | Command / Check | Expected Result |
|---|------|-----------------|-----------------|
| 1 | **Create sudo user** | `id <username>` | User exists and is in the `sudo` group |
| 2 | **SSH key auth setup** | `ls -la /home/<username>/.ssh/authorized_keys` | `authorized_keys` exists with the public key |
| 3 | **Disable root login** | `grep '^PermitRootLogin' /etc/ssh/sshd_config` | `PermitRootLogin no` (or `yes` with key-only in drop-in) |
| 4 | **Disable password auth** | `grep '^PasswordAuthentication' /etc/ssh/sshd_config` | `PasswordAuthentication no` |
| 5 | **SSH AllowUsers** | `grep '^AllowUsers' /etc/ssh/sshd_config.d/hardening.conf` | Contains your non‑root username |
| 6 | **UFW enabled** | `ufw status` | `Status: active` |
| 7 | **UFW allows SSH** | `ufw status numbered` | SSH (22) is listed |
| 8 | **UFW allows HTTP/HTTPS** (if needed) | `ufw status` | 80/tcp and/or 443/tcp listed |
| 9 | **Fail2Ban installed** | `systemctl is-active fail2ban` | `active` |
| 10 | **SSH jail active** | `fail2ban-client status ssh` | Jail is enabled and running |
| 11 | **Fail2Ban blocks brute force** | Attempt 3+ failed SSH logins → `fail2ban-client status ssh` | IP appears in `banlist` |
| 12 | **Cron daemon running** | `service cron status` || `active` |
| 13 | **Weekly update cron** | `crontab -l` | Line starting with `0 2 * * 0 /usr/bin/apt-get ...` |
| 14 | **Daily disk check cron** | `crontab -l` | Line starting with `0 3 * * * /usr/bin/df ...` |
| 15 | **Fail2Ban review cron** | `crontab -l` | Line starting with `0 4 * * * fail2ban-client get ssh banlist` |
| 16 | **Health check passes** | `sudo ./scripts/05-health-check.sh` | All checks show green (or expected warnings) |

## 📋 How to Use

1. **Run through physically** – Execute each script on your server in order:
   ```bash
   ./scripts/01-initial-setup.sh
   ./scripts/02-ufw-firewall.sh
   ./scripts/03-fail2ban.sh
   ./scripts/04-cron-tasks.sh
   ```

2. **Verify with the checklist** – Open `docs/hardening-checklist.md` and mark
   each item as you confirm it.

3. **Document deviations** – If something doesn't match, note why in the
   checklist and adjust the scripts/configs accordingly.

4. **Backup** – Before making major changes (e.g., restarting sshd), snapshot
   your VM or take a backup of `/etc/` and `/home/`.

## ⚠️ Common Lock‑Out Prevention

- **Always test SSH as your new user** before disabling password auth globally.
- **Keep a root shell** open while applying firewall/Fail2Ban rules.
- **Know how to restore UFW** if locked out: `ufw default allow incoming` then `ufw enable`.
- **Fail2Ban ban auto‑expire** – bantime is set to 3600s (1 hr) in the SSH jail;
  IPs are unbanned automatically after that window.