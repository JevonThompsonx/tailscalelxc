# Contributing to Proxmox Tailscale Fix

First off, thank you for considering contributing! This project was born from real-world Proxmox administration, and community input makes it better for everyone.

## How Can I Contribute?

### 🐛 Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- **Proxmox VE version** (`pveversion`)
- **LXC OS and version** (Debian/Ubuntu version)
- **Tailscale version** (`tailscale version`)
- **Output from** `./tailscale-verify.sh`
- **Relevant log excerpts** from `/var/log/tailscale-mass-fix.log`
- **Steps to reproduce** the issue
- **Expected vs actual behavior**

### 💡 Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Clear description** of the feature
- **Use case** - why would this be useful?
- **Proposed solution** (if you have one)
- **Alternatives considered**

### 🔧 Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Test your changes** on a real Proxmox environment if possible
3. **Update documentation** if you're changing functionality
4. **Follow the existing code style** (bash best practices)
5. **Write clear commit messages**

#### Testing Checklist

Before submitting a PR, test on:
- [ ] Proxmox VE (latest stable version)
- [ ] At least one Debian-based LXC
- [ ] LXCs with Tailscale enabled
- [ ] LXCs with Tailscale disabled (should be skipped)
- [ ] LXCs without Tailscale (should be skipped)
- [ ] Verify the fix persists after LXC reboot

### 📝 Code Style

- Use `bash` shebang: `#!/usr/bin/env bash`
- Use `set -euo pipefail` for error handling
- Comment complex logic
- Use descriptive variable names
- Include error messages for failure cases
- Use colorized output for user-facing messages

### 🎨 Commit Messages

- Use present tense ("Add feature" not "Added feature")
- Use imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit first line to 72 characters
- Reference issues and PRs liberally

Example:
```
Add support for Alpine Linux LXCs

- Detect Alpine package manager
- Adjust systemd paths for Alpine
- Update documentation

Fixes #123
```

## Development Setup

```bash
# Clone your fork
git clone https://github.com/yourusername/proxmox-tailscale-fix.git
cd proxmox-tailscale-fix

# Make your changes
nano tailscale-mass-fix.sh

# Test on Proxmox host
./tailscale-verify.sh
./tailscale-mass-fix.sh

# Create a branch
git checkout -b feature/my-new-feature

# Commit your changes
git add .
git commit -m "Add my new feature"

# Push to your fork
git push origin feature/my-new-feature
```

Then open a Pull Request on GitHub.

## Testing Guidelines

### Manual Testing

1. **Run on a test Proxmox environment first**
2. **Test with various LXC configurations:**
   - Fresh Tailscale installation
   - Already-fixed LXCs (should skip)
   - Disabled Tailscale services
   - Unauthenticated Tailscale instances
3. **Verify reboots:**
   - Reboot fixed LXCs
   - Confirm IP binding persists

### What to Test

- ✅ Script handles missing dependencies gracefully
- ✅ Colorized output works in different terminals
- ✅ Log file is created and written correctly
- ✅ Skip list works as expected
- ✅ Fix persists after reboot
- ✅ Script doesn't break existing Tailscale configs

## Documentation

If your PR adds features, update:

- `README.md` - Main documentation
- `CHANGELOG.md` - Add entry under `[Unreleased]`
- Inline comments in scripts
- Add examples if applicable

## Community

- Be respectful and inclusive
- Assume good intentions
- Focus on what's best for the project
- Help others learn and grow

## Questions?

Don't hesitate to ask! Open an issue with the `question` label, or start a discussion.

---

**Thank you for contributing to the Proxmox community!** 🎉
