# Tailscale IP Binding Fix for Proxmox LXCs

> **One-command fix for Tailscale connection timeouts in Proxmox LXC containers**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/bash-5.0+-green)](https://www.gnu.org/software/bash/)
[![Proxmox](https://img.shields.io/badge/proxmox-7.x%20%7C%208.x-orange)](https://www.proxmox.com/)

---

## The Problem

LXCs boot faster than their network is ready → Tailscale starts too early → IP never binds to interface → **connection timeouts**.

```bash
$ tailscale status
# Shows device online ✓

$ tailscale ip -4
100.108.69.63
# Shows IP assigned ✓

$ ip addr show tailscale0
# No IPv4 address bound ✗
# Services can't connect!
```

## The Solution

Apply a systemd override that makes Tailscale wait for the network. One command fixes all your LXCs.

---

## 🚀 Quick Start

### 1. Download Scripts

```bash
# SSH to Proxmox host
ssh root@pve

# Download
git clone https://github.com/yourusername/proxmox-tailscale-fix.git
cd proxmox-tailscale-fix
chmod +x *.sh
```

### 2. Check Status

```bash
./tailscale-verify.sh
```

### 3. Apply Fix

```bash
./tailscale-mass-fix.sh
```

### 4. Done!

All Tailscale LXCs are now fixed. Reboot-safe.

---

## 📊 What Gets Fixed

**Before Fix:**
```
CTID   NAME        IP              OVERRIDE   STATUS
101    jellyfin    100.70.231.28   No         ⚠ IP not bound
102    sonarr      100.108.69.63   No         ✓ OK (but not reboot-safe)
```

**After Fix:**
```
CTID   NAME        IP              OVERRIDE   STATUS
101    jellyfin    100.70.231.28   Yes        ✓ OK
102    sonarr      100.108.69.63   Yes        ✓ OK
```

---

## 📁 What's Included

| Script | Purpose |
|--------|---------|
| **tailscale-mass-fix.sh** | Fix all Tailscale LXCs at once |
| **tailscale-verify.sh** | Check which LXCs need fixing |
| **fix-no-ip-lxcs.sh** | Authenticate unauthenticated LXCs |
| **tailscale-monitor.sh** | Optional monitoring (cron) |

---

## ⚙️ How It Works

Creates `/etc/systemd/system/tailscaled.service.d/override.conf` in each LXC:

```ini
[Unit]
After=network-online.target
Wants=network-online.target

[Service]
ExecStartPre=/bin/sleep 5
```

**Result:** Tailscale waits for network → IP binds correctly → everything works.

---

## 🎯 Features

- ✅ **One command** fixes all LXCs
- ✅ **Safe** - skips LXCs without Tailscale
- ✅ **Smart** - skips disabled services automatically
- ✅ **Reboot-safe** - fix persists across reboots
- ✅ **Idempotent** - run multiple times safely
- ✅ **Logged** - full operation log in `/var/log/tailscale-mass-fix.log`

---

## 🔧 Configuration

### Skip Specific LXCs

Edit `tailscale-mass-fix.sh`:

```bash
# Add LXC IDs to skip
SKIP_LXCS="105 225 229"
```

Disabled services are automatically skipped.

---

## 🧪 Testing

Verify the fix survives reboots:

```bash
# Reboot an LXC
pct reboot 101

# Wait 30 seconds
sleep 30

# Check IP is still bound
pct exec 101 -- tailscale ip -4
pct exec 101 -- ip addr show tailscale0 | grep "inet "
```

Both should show the IP.

---

## 🐛 Troubleshooting

### "✗ No IP" After Fix

LXC isn't authenticated to Tailscale:

```bash
./fix-no-ip-lxcs.sh
# Or manually:
pct enter <CTID>
tailscale up
```

### Fix Failed

Check logs:

```bash
cat /var/log/tailscale-mass-fix.log | grep ERROR
```

### Remove Fix

```bash
pct exec <CTID> -- rm /etc/systemd/system/tailscaled.service.d/override.conf
pct exec <CTID> -- systemctl daemon-reload
pct exec <CTID> -- systemctl restart tailscaled
```

---

## 📖 Manual Fix (Single LXC)

```bash
pct enter <CTID>

mkdir -p /etc/systemd/system/tailscaled.service.d/
cat > /etc/systemd/system/tailscaled.service.d/override.conf <<'EOF'
[Unit]
After=network-online.target
Wants=network-online.target

[Service]
ExecStartPre=/bin/sleep 5
EOF

systemctl daemon-reload
systemctl restart tailscaled
tailscale ip -4  # Verify

exit
```

---

## 📝 Command Reference

| Command | Purpose |
|---------|---------|
| `./tailscale-verify.sh` | Check LXC status |
| `./tailscale-mass-fix.sh` | Apply fix to all |
| `./fix-no-ip-lxcs.sh` | Authenticate LXCs |
| `pct exec <CTID> -- tailscale status` | Check Tailscale |
| `pct reboot <CTID>` | Test reboot |

---

## ✅ Compatibility

- **Proxmox VE:** 7.x, 8.x
- **LXC OS:** Debian 11/12/13, Ubuntu 20.04/22.04/24.04
- **Tailscale:** All versions
- **Requires:** systemd, bash

---

## 🤝 Contributing

Pull requests welcome! See [CONTRIBUTING.md](CONTRIBUTING.md).

Found a bug? [Open an issue](../../issues).

---

## 📄 License

MIT License - see [LICENSE](LICENSE)

---

## 🙏 Credits

Built for the Proxmox community. Tested on 26+ LXCs in production.

**If this helped you, please ⭐ star the repo!**

---

## 💡 Why This Happens

Proxmox LXCs boot in ~2 seconds. Network takes ~5 seconds to initialize. Tailscale starts at boot → network not ready → IP assignment succeeds but binding fails → timeouts.

This fix ensures proper startup order: **Network ready → Tailscale starts → IP binds correctly**.

---

<details>
<summary>📊 Full Example Output</summary>

```bash
$ ./tailscale-mass-fix.sh

═══════════════════════════════════════════════════════════
=== Tailscale Mass Fix for Proxmox LXCs ===
═══════════════════════════════════════════════════════════
Found 26 running LXCs

[1/26] Checking LXC 101 (jellyfin)...
  ✓ Tailscale detected and enabled
  → Applying fix...
  ✓ Fix applied! IP: 100.70.231.28

[2/26] Checking LXC 102 (sonarr)...
  ✓ Tailscale detected and enabled
  → Applying fix...
  ✓ Fix applied! IP: 100.108.69.63

... (continues for all LXCs) ...

═══════════════════════════════════════════════════════════
=== Summary ===
Total LXCs checked:  26
Fixed:               12 LXCs ✓
Skipped:             14 LXCs
Failed:              0 LXCs

✓ SUCCESS: Applied fix to 12 LXC(s)
```

</details>

---

**Questions?** Open an [issue](../../issues) or check [SKIP-LIST-CONFIG.md](SKIP-LIST-CONFIG.md) for advanced configuration.
