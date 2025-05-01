# oratop-monitor
A script to automatically captures Oracle DB performance metrics using oratop, stores 1-hour snapshots, compresses logs with 7za, and retains data for 24 hours. Only logs errors.

# Oracle Database Performance Monitor (`oratop-history`)

![Shell Script](https://img.shields.io/badge/Shell-Bash-%234EAA25?logo=gnu-bash)
![Oracle DB](https://img.shields.io/badge/Oracle-Database-%23F80000?logo=oracle)
![License](https://img.shields.io/badge/License-MIT-blue)

Automated Oracle DB performance monitoring using `oratop`. Captures hourly snapshots, compresses logs with `7za`, and maintains 24-hour retention with error-only logging.

```text
============================================

  /$$$$$$                       /$$                        
 /$$__  $$                     | $$                        
| $$  \ $$  /$$$$$$  /$$$$$$  /$$$$$$    /$$$$$$   /$$$$$$ 
| $$  | $$ /$$__  $$|____  $$|_  $$_/   /$$__  $$ /$$__  $$
| $$  | $$| $$  \__/ /$$$$$$$  | $$    | $$  \ $$| $$  \ $$
| $$  | $$| $$      /$$__  $$  | $$ /$$| $$  | $$| $$  | $$
|  $$$$$$/| $$     |  $$$$$$$  |  $$$$/|  $$$$$$/| $$$$$$$/
 \______/ |__/      \_______/   \___/   \______/ | $$____/ 
                                                 | $$      
                                                 | $$      
                                                 |__/      
  
      Oracle DB Performance Monitor         
============================================
```

## 📚 Summary

- [📦 Prerequisites](#-prerequisites)
- [🚀 Installation](#-installation)
- [🛠 Usage](#-usage)
- [📂 File Structure](#-file-structure)
- [⚙️ Configuration](#️-configuration)
- [🔍 Checking Output](#-checking-output)
- [🚨 Troubleshooting](#-troubleshooting)
- [⏹ Stopping the Service](#-stopping-the-service)
- [📜 License](#-license)


## 📦 Prerequisites

- **Oracle Linux** (or RHEL/CentOS 7+)
- `oratop` (included with Oracle DB installations 19c)
- `p7zip` for compression:
  ```bash
  sudo yum install p7zip -y

## 🚀 Installation

Clone/download the script:
  ```bash
  curl -o /home/oracle/monitor_oratop.sh https://example.com/path/to/script.sh
  chmod +x /home/oracle/monitor_oratop.sh
  ```

## 🛠 Usage

**Start Monitoring**
  ```bash
screen -S oratop_monitor
/home/oracle/monitor_oratop.sh
  ```
  ```
Detach session: Ctrl+A → D
Resume: screen -r oratop_monitor
  ```

Background Execution (Alternative)
  ```bash
nohup /home/oracle/monitor_oratop.sh >/dev/null 2>&1 &
  ```

## 📂 File Structure

  ```
/home/oracle/oratop-history/
├── oratop-{TIMESTAMP}.out    # Raw performance snapshots
├── logs/
│   └── oratop-{TIMESTAMP}.zip  # Compressed archives
└── oratop.log               # Error logs (only)
  ```

## ⚙️ Configuration

Edit these variables in the script:
  ```
ORATOP_DIR="/home/oracle/oratop-history"  # Storage path
RETENTION_HOURS=24                        # Hours to keep data
INTERVAL_SECONDS=5                        # Snapshot frequency (seconds)
  ```

##   🔍 Checking Output

View latest compressed data
  ```bash
ls -lt /home/oracle/oratop-history/logs/*.zip
  ```

## Check errors
  ```bash
tail -f /home/oracle/oratop-history/oratop.log
  ```

## 🚨 Troubleshooting
Issue	Solution
  ```
7za: command not found	sudo yum install p7zip
Permission denied	Ensure oracle user owns the directory: chown oracle:oinstall /home/oracle/oratop-history
No output files	Verify Oracle DB connectivity and SYSDBA privileges
  ```

## ⏹ Stopping the Service
  ```bash
pkill -f monitor_oratop.sh  # OR
kill $(pgrep -f monitor_oratop.sh)
  ```

## 📜 License
MIT License - Free for modification and redistribution.
Maintainer: [Pablo Travesso/[GitHub Profile](https://github.com/ptravesso-dba)]
Version: 1.0

> 💡 Pro Tip: For production environments, consider adding this to cron or a systemd service for auto-restart.
