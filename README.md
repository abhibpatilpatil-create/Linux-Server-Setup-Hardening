# 🛡️ Linux Server Setup & Hardening Project

A beginner-to-intermediate Linux + DevOps + Cybersecurity project where you'll learn to configure a Ubuntu server and then harden it against common threats.

---

## 📖 Project Overview

This project walks you through the complete lifecycle of server administration:

1. **Initial Setup** – User accounts, SSH configuration, system updates
2. **Firewall** – UFW rules to control inbound/outbound traffic
3. **Intrusion Prevention** – Fail2Ban to block brute‑force attacks
4. **Scheduled Maintenance** – Cron jobs for updates and health checks
5. **Automation** – Bash scripts to repeat the process on new servers

---

## 🛠️ Technologies Covered

| Technology | Purpose |
| ---------- | --------|
| **Bash** | Automation and server scripts |
| **Linux commands** | Server administration |
| **SSH** | Remote server access |
| **UFW** | Firewall configuration |
| **Fail2Ban** | Protection against repeated authentication attempts |
| **Cron** | Scheduled tasks |
| **YAML** | Optional, if you later add Ansible |
| **Git/GitHub** | Project version control |
| **Markdown** | Documentation |

---

## 📦 Prerequisites

- A Ubuntu 20.04+/22.04+ server (local VM or cloud instance)
- `sudo` privileges on the target server
- Git installed locally
- Text editor (VS Code, Nano, etc.)

---

## 🚀 Quick Start

```bash
# 1. Clone the repo (or copy the files to your server)
git clone https://github.com/your-username/linux-server-hardening.git
cd linux-server-hardening

# 2. Review the scripts (read-only first!)
chmod +x scripts/*.sh

# 3. Run the initial setup script (will prompt for username)
./scripts/01-initial-setup.sh

# 4. Configure the firewall
./scripts/02-ufw-firewall.sh

# 5. Install and configure Fail2Ban
./scripts/03-fail2ban.sh

# 6. Set up cron jobs for ongoing maintenance
./scripts/04-cron-tasks.sh

# 7. Run the health check
./scripts/05-health-check.sh
```

---

## 📁 Project Structure

```
linux-server-hardening/
├── .gitignore              # Git-ignored files
├── README.md               # This file
├── scripts/
│   ├── 01-initial-setup.sh     # User creation + SSH hardening
│   ├── 02-ufw-firewall.sh      # UFW firewall rules
│   ├── 03-fail2ban.sh          # Fail2Ban installation & jails
│   ├── 04-cron-tasks.sh        # Cron jobs for maintenance
│   └── 05-health-check.sh      # System health diagnostics
├── configs/
│   ├── ssh/sshd_config.d/      # Drop-in SSH hardening settings
│   ├── fail2ban/jail.local     # Fail2Ban configuration
│   └── ufw/                    # UFW application profiles
└── docs/
    └── hardening-checklist.md  # Step‑by‑step checklist
```

---

## 📜 License

This project is licensed under the MIT License – see the accompanying LICENSE file or visit https://opensource.org/licenses/MIT.