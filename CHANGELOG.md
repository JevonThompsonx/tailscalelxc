# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-02-08

### Added
- Initial release of Tailscale IP binding fix for Proxmox LXCs
- `tailscale-mass-fix.sh` - Main script to apply fix to all Tailscale LXCs
- `tailscale-verify.sh` - Status verification script
- `fix-no-ip-lxcs.sh` - Helper script for unauthenticated LXCs
- `tailscale-monitor.sh` - Optional monitoring script for individual LXCs
- Comprehensive documentation and troubleshooting guides
- Automatic detection of Tailscale-enabled LXCs
- Skip list configuration for excluding specific LXCs
- Automatic skipping of disabled Tailscale services
- Colorized console output for better readability
- Detailed logging to `/var/log/tailscale-mass-fix.log`

### Features
- ✅ Detects and fixes IP binding issues automatically
- ✅ Works across all running LXCs with a single command
- ✅ Respects disabled Tailscale services
- ✅ Provides before/after verification
- ✅ Idempotent - safe to run multiple times
- ✅ Non-destructive - only adds systemd override
- ✅ Preserves existing Tailscale configurations

### Compatibility
- Proxmox VE 7.x and 8.x
- Debian 11, 12, and 13 LXCs
- Ubuntu 20.04, 22.04, and 24.04 LXCs
- All Tailscale versions

## [Unreleased]

### Planned
- Web dashboard for monitoring multiple Proxmox hosts
- Automatic backup of systemd overrides before modification
- Integration with Proxmox clustering
- Support for Proxmox VMs (in addition to LXCs)
- Email notifications for fix operations
- Ansible playbook version

---

## Version History

### v1.0.0 (2026-02-08)
- Initial public release
- Tested with 26+ LXCs across multiple Proxmox hosts
- Resolves IP binding issues that cause connection timeouts
- Full automation with safety checks

---

**Note:** This project was created in response to a common issue in the Proxmox community where Tailscale fails to bind IPv4 addresses to LXC interfaces due to fast boot times.
