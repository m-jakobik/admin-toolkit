# Admin Toolkit

Collection of personal Linux administration scripts and utilities.

Keep it simple, as those scripts are meant for everyday Linux administration, system maintenance, monitoring and automation.

Scripts are written in Bash and designed for Debian-based systems.



## Contents

- [Scripts](#scripts)
- [Conky utilities](#conky-utilities)
- [Automation](#automation)
- [Documentation](#documentation)
- [Requirements](#requirements)

---

## Usage

Most scripts require root privileges


## Scripts

- os_updater.sh - system update helper
- MiCleaner.sh - system cleanup (APT cache, old kernels, Flatpak and Vesktop cache)
- gdrive_nc_keepassDB_sync.sh - sync local copy of KeePass pwdDB to Gdrive + Nextcloud, and create local backup 
- health.sh - system health check (SSD, temperature, memory, journal errors) with logging support. Works with cron/anacron


# Scripts

## System maintenance

### `os_updater.sh`

Debian-based system update helper.

Features:
- package list update
- standard upgrade
- optional full-upgrade support
- cleanup of unused packages

Usage:

```bash
sudo ./os_updater.sh
```

---

### `MiCleaner.sh`

System cleanup utility.

Removes:
- APT cache
- old kernels
- Flatpak cache
- Vesktop cache

Useful for keeping desktop systems clean.

Usage:

```bash
sudo ./MiCleaner.sh
```

---

## Monitoring and diagnostics

### `health.sh`

System health check script.

Checks:
- SSD SMART status
- disk health
- CPU temperature
- memory usage
- journal errors

Features:
- human-readable output
- logging support
- designed to work with cron/anacron

Example:

```bash
./health.sh
```

---

## Backup and synchronization

### `gdrive_nc_keepassDB_sync.sh`

Backup and synchronization helper for KeePass database.

Features:
- creates local backup
- synchronizes database copy with Google Drive
- synchronizes with Nextcloud

Uses:

- `rclone`

---

# Conky utilities

Small scripts designed to provide live system information in Conky.

## `pogoda.sh`

Weather information widget.

Provides:
- current temperature
- feels-like temperature
- humidity
- wind speed and direction
- precipitation
- weather description

Data source:

- Open-Meteo API

Features:
- API error handling
- weather code translation
- temperature-based colors for Conky

---

## `ssd_status.sh`

SSD health status widget.

Uses:

- smartctl

Displays:
- SMART health status
- SSD wear level
- available spare percentage

Automatically detects the system disk.

## `check_ip.sh`

Network information widget for Conky.

Features:
- retrieves current public IP address
- handles network/API failures gracefully
- provides quick network visibility from desktop

Data source:
- external IP lookup service via curl

Useful for quick verification of current external IP directly from desktop, and it's session time

Requires:
- curl

Example:

```bash
./check_ip.sh
```
---

# Automation

Scripts are designed to work with:

- anacron
- cron
- Conky refresh intervals

Typical examples:

- regular health checks
- automatic backups
- desktop monitoring widgets

---

# Documentation

Additional documentation is stored separately.

Private environment-specific documentation is excluded from Git, including:

- server details
- recovery procedures
- infrastructure information

---

# Requirements

Common dependencies:

```text
bash
curl
jq
bc
smartmontools
rclone
```

Optional:

```text
conky
```

For Debian/Ubuntu based systems:

```bash
sudo apt install curl jq bc smartmontools rclone conky
```

---

# Notes

These scripts are primarily developed for personal Linux administration and desktop/server maintenance.

They are intentionally kept simple, readable and easy to modify ;)
