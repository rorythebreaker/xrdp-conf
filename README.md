# xrdp_setup.sh

Interactive TUI wizard for installing and configuring XRDP with XFCE4 on Ubuntu/Debian systems.

---

## Overview

`xrdp_setup.sh` automates the full setup of a Remote Desktop Protocol (RDP) server on Ubuntu/Debian. The script runs as an interactive terminal UI — no command-line arguments required. All configuration is collected through on-screen prompts before any changes are made to the system.

---

## Requirements

| Requirement | Details |
|---|---|
| OS | Ubuntu 20.04+ or any Debian-based distribution with `apt` |
| Privileges | Must be run as root (`sudo`) |
| Shell | Bash |
| Terminal | ANSI color support recommended (any modern terminal emulator) |

---

## Quick Start

```bash
sudo bash xrdp_setup.sh
```

---

## What the Script Does

The wizard performs 9 sequential steps:

| Step | Action |
|---|---|
| 1 | Update apt package index |
| 2 | Install `xrdp`, `xfce4`, and `xfce4-goodies` |
| 3 | Enable the xrdp service (`systemctl enable`) |
| 4 | Start the xrdp service (`systemctl start`) |
| 5 | Configure UFW firewall — allow RDP port *(optional)* |
| 6 | Patch `/etc/xrdp/startwm.sh` to fix the black screen issue |
| 7 | Set custom RDP port in `/etc/xrdp/xrdp.ini` *(if non-default port selected)* |
| 8 | Write `xfce4-session` to `~/.xsession` for the target user *(optional)* |
| 9 | Restart xrdp to apply all changes |

---

## TUI Flow

The script presents five sequential screens:

### 1 — Welcome
Displays an overview of planned actions and asks for confirmation before proceeding.

### 2 — Configuration Options
Collects three parameters from the user:

- **RDP port** — default `3389`, accepts any value in range `1–65535`
- **UFW firewall** — optionally runs `ufw allow <port>/tcp` and `ufw reload`
- **Target username** — the system user for whom `~/.xsession` will be configured; defaults to `$SUDO_USER` if available

### 3 — Review & Confirm
Shows a summary of all selected options. The user confirms before any system changes are made.

### 4 — Installation Progress
Executes all steps with labeled status indicators:

```
  ──▶ Step 6 — Patching /etc/xrdp/startwm.sh (black screen fix)
  $ cp /etc/xrdp/startwm.sh /etc/xrdp/startwm.sh.bak
  [ OK ]  Patched startwm.sh (backup saved as startwm.sh.bak)
```

### 5 — Summary
Displays the live xrdp service status, configured port, xsession user, log file path, and the RDP connection address.

---

## Black Screen Fix

The script automatically patches `/etc/xrdp/startwm.sh` by inserting the following lines before the `test -x /etc/X11/Xsession` line:

```bash
unset DBUS_SESSION_BUS_ADDRESS
unset XDG_RUNTIME_DIR
```

This prevents the black screen that commonly appears when connecting via RDP to XFCE4 sessions. A backup of the original file is saved as `startwm.sh.bak` before modification. If the file has already been patched, this step is skipped automatically.

---

## Firewall

UFW configuration is **optional and off by default**. If enabled, the script runs:

```bash
ufw allow <port>/tcp
ufw reload
```

If `ufw` is not installed on the system, this step is silently skipped with a warning.

---

## Files Modified

| File | Action |
|---|---|
| `/etc/xrdp/startwm.sh` | Patched — `unset` lines inserted; backup saved as `startwm.sh.bak` |
| `/etc/xrdp/xrdp.ini` | Port updated — only if a non-default port was selected; backup saved as `xrdp.ini.bak` |
| `~<user>/.xsession` | `xfce4-session` appended — only if a target user was specified |

---

## Log File

All command output is redirected to `/tmp/xrdp_setup.log`. The file is cleared at the start of each run. If any step fails, the log contains the full error output for diagnosis.

```bash
cat /tmp/xrdp_setup.log
```

---

## Connecting After Setup

Use any RDP-compatible client to connect:

```
<server-ip>:<port>
```

**Tested clients:** Windows Remote Desktop (`mstsc.exe`), Remmina, FreeRDP, Microsoft Remote Desktop (macOS/iOS).

On the XRDP login screen, enter the credentials of the Linux user account on the target machine.

---

## Troubleshooting

| Symptom | Solution |
|---|---|
| Black screen after login | Verify that `startwm.sh` was patched and `~/.xsession` contains `xfce4-session` |
| Cannot connect (connection refused) | Check `systemctl is-active xrdp`; review `journalctl -u xrdp` |
| Cannot connect (timeout) | Confirm the firewall allows the RDP port: `ufw status` |
| xrdp installed but XFCE4 not starting | Ensure `~/.xsession` exists and contains `xfce4-session` for the connecting user |
| Script exits immediately | Must be run with `sudo`; the script checks `$EUID` and exits if not root |
| Port change not applied | Confirm `/etc/xrdp/xrdp.ini` contains `port=<your-port>` and xrdp was restarted |

---

## Color Scheme

| Color | Role |
|---|---|
| Steel blue | Info messages `[INFO]` |
| Lime green | Success messages `[ OK ]` |
| Coral red | Failure messages `[FAIL]` |
| Yellow | Warning messages `[WARN]` |
| Amber | Prompts, highlights, port values |
| Light cyan | Section headers |
| Dark gray | Box borders |
