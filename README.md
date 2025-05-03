# oratop-monitor Rafael

# Oracle Database Performance Monitor (`oratop-history`)

![Shell Script](https://img.shields.io/badge/Shell-Bash-%234EAA25?logo=gnu-bash)
![Oracle DB](https://img.shields.io/badge/Oracle-Database-%23F80000?logo=oracle)
![License](https://img.shields.io/badge/License-MIT-blue)

A robust Bash script for automated Oracle Database performance monitoring using `oratop`.
It features interactive configuration, log retention, automatic compression, and safe process management.

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

- [📝 Features](#-features)
- [📦 Prerequisites](#-prerequisites)
- [🚀 Installation](#-installation)
- [🛠 Usage](#-usage)
- [📂 File Structure](#-file-structure)
- [🚨 Troubleshooting](#-troubleshooting)
- [📜 License](#-license)

## 📝 Features
- `Interactive setup`: Guides you through all configuration steps.
- `Retention management`: Automatically compresses and cleans up old logs.
- `Safe stop`: Easily stop all running oratop processes with a single command.
- `User-friendly`: Clear prompts, validation, and helpful summaries.
- `Customizable`: Choose intervals, durations, and retention policies.

## 📦 Prerequisites

- **Oracle Linux** (or RHEL/CentOS 7+)
- `oratop` (included with Oracle DB installations 19c)
- `p7zip` for compression:
  ```bash
  sudo yum install p7zip -y
- `Bash 4.x` or later
- `Oracle user environment` (/home/oracle/.bash_profile)

## 🚀 Installation

Clone/download the script:
  ```bash
    git clone https://github.com/yourusername/monitor_oratop.git
    cd monitor_oratop
  ```
Make the script executable:
  ```bash
    chmod +x monitor_oratop.sh
  ```
> Ensure oratop and 7za are installed and in the expected locations.


## 🛠 Usage

**Start Monitoring**
  ```bash
screen -S oratop_monitor
cd /home/oracle/
./monitor_oratop.sh
  ```
  ```
Detach session: Ctrl+A → D
Resume: screen -r oratop_monitor
  ```
- The script will prompt you for:
- Retention before compressing `.out` files (e.g., `90 minutes`, `2 hours`)
- Retention for compressed logs (e.g., `2 days`, `12 hours`)
- Seconds between each data collection (e.g., `5`)
- Duration for each output file (e.g., `60 minutes`, `2 hours`)

- After configuration, a summary will be displayed and monitoring will begin.

**Stop Monitoring**

To safely stop all running oratop processes started by this script:
  ```bash
./monitor_oratop.sh stop 
  ```

**How It Works**
- Data Collection: Runs oratop at your chosen interval and duration, saving output to .out files.
- Compression: After the configured retention period, .out files are compressed to .zip and moved to the logs/ directory.
- Cleanup: Compressed logs are deleted after their retention period.
- Logs: All script activity is logged to oratop.log.

Directories:
- Raw output: /home/oracle/oratop-history/
- Compressed logs: /home/oracle/oratop-history/logs/
- Script log: /home/oracle/oratop-history/oratop.log

## 📂 File Structure

  ```
/home/oracle/oratop-history/
├── oratop-{TIMESTAMP}.out    # Raw performance snapshots
├── logs/
│   └── oratop-{TIMESTAMP}.zip  # Compressed archives
└── oratop.log               # Error logs (only)
  ```

**Example**
  ```bash
======================================

     ___           _                          
    /___\_ __ __ _| |_ ___  _ __              
   //  // '__/ _` | __/ _ \| '_ \            
  / \_//| | | (_| | || (_) | |_) |           
  \___/ |_|  \__,_|\__\___/| .__/            
                            |_|              

    Oracle DB Performance Monitor      
    Developed by Pablo Travesso      
======================================

🔧 Configuring oratop monitor...
Retention before compressing .out (e.g. 90 minutes / 2 hours): 90 minutes
Retention for compressed logs (e.g. 2 days, 12 hours, 90 minutes): 2 days
Seconds between each data collection? (e.g. 5): 5
For how long should each output file run? (e.g. 60 minutes / 2 hours): 60 minutes
✅ Configuration saved.

========= Configuration Summary =========
• Data will be collected every 5 seconds.
• Each output file will run for 60 minutes (total 3600 seconds, 720 iterations).
• .out files will be compressed after 90 minutes.
• Compressed .zip files will be kept for 2 days.
• Output .out files are stored in: /home/oracle/oratop-history
• Compressed .zip files are stored in: /home/oracle/oratop-history/logs
• Log file for this script: /home/oracle/oratop-history/oratop.log
=========================================
  ```

## 🚨 Troubleshooting
- oratop fails to run: Ensure the interval is at least 3 seconds and oratop is installed at the expected path.
- Compression fails: Make sure `7za` is installed and in your `PATH`.
- Permission errors: Run as the Oracle user or ensure correct permissions on output directories.

## 📜 License
MIT License - Free for modification and redistribution.

Maintainer: [Pablo Travesso/[GitHub Profile](https://github.com/ptravesso-dba)/[LinkedIn Profile](https://www.linkedin.com/in/pablo-travesso-141082232/)]

Version: 1.0

> 💡 Pro Tip: For production environments, consider adding this to cron or a systemd service for auto-restart.

> To make it easier to use the tool, try to add an alias at the end of your Oracle user's .bash_profile:
  ```bash
alias monitor_oratop='bash /home/oracle/monitor_oratop.sh'
  ```
