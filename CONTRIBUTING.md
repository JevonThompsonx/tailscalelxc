# Contributing

> Thanks for considering contributing! 🎉

---

## 🐛 Report a Bug

1. Check [existing issues](../../issues) first
2. Use the [bug report template](../../issues/new?template=bug_report.md)
3. Include:
   - Proxmox version (`pveversion`)
   - LXC OS (Debian/Ubuntu version)
   - Tailscale version
   - Output from `./tailscale-verify.sh`
   - Log excerpts from `/var/log/tailscale-mass-fix.log`

---

## 💡 Suggest a Feature

1. Open a [new issue](../../issues/new)
2. Describe the feature
3. Explain the use case
4. (Optional) Propose implementation

---

## 🔧 Submit Code

### Quick Start

```bash
# Fork the repo
git clone https://github.com/yourusername/proxmox-tailscale-fix.git
cd proxmox-tailscale-fix

# Create branch
git checkout -b feature/my-feature

# Make changes
nano tailscale-mass-fix.sh

# Test thoroughly
./tailscale-verify.sh
./tailscale-mass-fix.sh

# Commit
git commit -m "Add my feature"

# Push
git push origin feature/my-feature

# Open Pull Request on GitHub
```

### Testing Checklist

Test on real Proxmox before submitting:

- [ ] Works with Tailscale-enabled LXCs
- [ ] Skips disabled Tailscale services
- [ ] Skips LXCs without Tailscale
- [ ] Fix persists after LXC reboot
- [ ] No errors in log file
- [ ] Colorized output works

---

## 📝 Code Style

**Bash Best Practices:**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Use descriptive names
RUNNING_LXCS="101 102"

# Comment complex logic
# Check if Tailscale is enabled
if systemctl is-enabled tailscaled; then
    ...
fi

# Colorize user output
log "Success!" "$GREEN"
```

---

## 💬 Commit Messages

**Format:**

```
Add support for Alpine Linux LXCs

- Detect Alpine package manager
- Adjust paths for Alpine
- Update docs

Fixes #123
```

**Guidelines:**
- Present tense ("Add" not "Added")
- Imperative mood ("Fix" not "Fixes")
- First line ≤ 72 chars
- Reference issues

---

## 📚 Documentation

If adding features, update:
- `README.md` - Main docs
- `CHANGELOG.md` - Add under `[Unreleased]`
- Inline script comments
- Add examples

---

## ✅ Pull Request Checklist

Before submitting:

- [ ] Tested on Proxmox
- [ ] Code follows style guide
- [ ] Docs updated
- [ ] Commit messages clear
- [ ] No sensitive data in files

---

## 🤝 Community Guidelines

- Be respectful
- Assume good intentions
- Help others learn
- Focus on solutions

---

## ❓ Questions?

Not sure about something? Just ask! Open an issue with the `question` label.

---

**Thanks for contributing!** Your help makes this better for everyone. 🙏
