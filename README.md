# Linux System Health Dashboard

A Bash-based system monitoring tool that reads live kernel data, checks service availability, logs alerts, and runs automatically on a schedule via cron and systemd.

Built from scratch as a hands-on Linux learning project

---

## What it does

- Reports CPU load, RAM usage, and disk usage with color-coded thresholds
- Displays active network interfaces and live traffic bytes from `/proc/net/dev`
- Lists open listening ports via `ss`
- Probes service availability using Bash's built-in `/dev/tcp`
- Checks internet connectivity via `curl`
- Writes timestamped alerts to a log file when thresholds are exceeded
- Rotates the log automatically so it never grows unbounded
- Prints a summary of warnings at the end of every run
- Runs automatically on a schedule via cron or systemd timer

---

## Sample output

```
=================================
   System Health Dashboard
   Testing1 - 2026-05-01 13:05:01
=================================
CPU Load (1m): 0.22 | Cores: 4
RAM: 12% used
Disk usage:
  /: 6%
==========================
   Network
==========================
  Interface: enp0s3  IP: 10.0.x.x/24
  Traffic (bytes since last boot):
  enp0s3     RX: 54102xxx     TX: 478xxx
  Listening ports:
  Port: 0.0.0.0:22
  Port: 0.0.0.0:80
  Service checks:
  [UP]   Google DNS (8.8.8.8:53)
  [UP]   Local SSH (localhost:22)
  [UP]   HTTP (localhost:80)
  Internet connectivity:
  [UP]   Internet reachable
============================
  Summary
============================
  All systems normal
  Log file: /home/user/dashboard.log
```

---

## Requirements

- Linux (tested on Ubuntu 25)
- Bash 4+
- `curl`, `ss`, `ip`, `awk`, `grep` — all standard on Ubuntu
- `systemd` (optional, for timer-based scheduling)

---

## Installation

Clone the repository:

```bash
git clone https://github.com/yourusername/dashboard.git
cd dashboard
```

Make the script executable:

```bash
chmod +x dashboard.sh
```

Run it manually:

```bash
./dashboard.sh
```

---

## Scheduling

### Option 1 — cron

Open your crontab:

```bash
crontab -e
```

Add this line to run every Monday at 9am:

```bash
0 9 * * 1 /bin/bash /home/yourusername/dashboard.sh >> /home/yourusername/dashboard.log 2>&1
```

### Option 2 — systemd timer

Copy the service and timer files:

```bash
sudo cp dashboard.service /etc/systemd/system/
sudo cp dashboard.timer /etc/systemd/system/
```

Edit both files and replace `yourusername` with your actual username, then enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable dashboard.timer
sudo systemctl start dashboard.timer
```

Confirm it is scheduled:

```bash
systemctl list-timers --all
```

---

## Viewing logs

```bash
# Read the full log
cat ~/dashboard.log

# Follow live updates
tail -f ~/dashboard.log

# Show only warnings
grep "\[WARN\]" ~/dashboard.log

# Count total warnings
grep -c "\[WARN\]" ~/dashboard.log

# systemd journal (if using systemd timer)
journalctl -u dashboard.service -n 20
```

---

## Configuration

At the top of `dashboard.sh` you can adjust:

```bash
LOG_FILE="$HOME/dashboard.log"   # where logs are written
MAX_LOG_LINES=500                 # maximum lines before rotation
```

To add or change monitored services, edit the parallel arrays in `check_services`:

```bash
local names=("Google DNS" "Local SSH" "HTTP")
local hosts=("8.8.8.8"    "localhost"  "localhost")
local ports=("53"          "22"         "80")
```

---

## Project structure

```
dashboard/
├── dashboard.sh          # main script
├── dashboard.service     # systemd service unit
├── dashboard.timer       # systemd timer unit
├── screenshots/
│   └── output.png        # sample terminal output
└── README.md
```

---

## What I learned building this

This project was built phase by phase as a structured Linux learning exercise:

**Phase 1** — reading virtual kernel files from `/proc`, parsing text with `grep` and `awk`, Bash functions, conditionals, ANSI colors, and integer arithmetic with `$(())`.

**Phase 2** — network tools (`ip`, `ss`, `curl`), Bash arrays, parallel array indexing, `/dev/tcp` for raw TCP probing, `timeout` for safe command execution, exit code testing, and stderr redirection.

**Phase 3** — append redirects `>>`, file test operators, log rotation with `tail` and `mv`, `grep -c` for counting, the `||` fallback operator, positional parameters, and regex escaping.

**Phase 4** — cron syntax and scheduling, cron environment variables, systemd service and timer units, `journalctl` for log viewing, and the difference between cron and systemd timer approaches.

---
