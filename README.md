# Proton Updater

A lightweight Bash script to check, download, verify, and update desktop RPM packages for **Proton Pass** and **Proton Mail** directly from Proton's release feeds.

Since Proton does not currently provide dedicated YUM/DNF repositories for these desktop applications, this script automates polling their release APIs and keeping local installations current.

## Features

- **Version Checking:** Compares installed RPM versions against Proton's latest release endpoints.
- **Integrity Verification:** Validates downloads against the official SHA-512 checksums before running any package manager commands.
- **Clean Elevation:** Asks for `sudo` credentials upfront so background package installs aren't interrupted mid-loop.
- **Auto-Cleanup:** Removes downloaded `.rpm` artifacts from `/tmp` once installed or if a checksum mismatch occurs.

## Prerequisites

Ensure the following tools are installed:

- `bash`
- `curl`
- `wget`
- `jq`
- `dnf` / `rpm`
- `coreutils` (for `sha512sum`)

On Fedora/RHEL:
```bash
sudo dnf install -y curl wget jq
```

## Usage
Make the script executable and run it:
```bash
chmod +x update-proton.sh
./update-proton.sh
```
*(If run as a regular user, it will request root permissions upfront to handle the package installation.)*
## Notes & Roadmap
- Package Support: Currently targets RPM-based distributions (Fedora, RHEL, CentOS Stream) using dnf.
- Planned: Support for Debian/Ubuntu .deb packages and cross-distribution package manager detection.
