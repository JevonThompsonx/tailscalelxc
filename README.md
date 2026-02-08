# Tailscale IP Binding Fix for Proxmox LXCs

Automatically fix Tailscale IPv4 binding issues in Proxmox LXC containers. Prevents connection timeouts caused by Tailscale starting before the network is fully ready.

## 🔍 The Problem

Proxmox LXCs boot extremely fast - sometimes faster than the network subsystem is fully initialized. When Tailscale starts before the network is ready, it successfully connects to the Tailscale control plane and receives an IP assignment, but **fails to bind that IP to the network interface**.

**Symptoms:**
- `tailscale status` shows the device with an IP
- `tailscale ip -4` returns the IP address
- But `ip addr show tailscale0` shows no IPv4 address
- Services trying to connect via Tailscale get **connection timeouts**
- Issue appears after LXC reboots

**Example:**
```bash
$ tailscale ip -4
100.108.69.63

$ ip addr show tailscale0
3: tailscale0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1280
    link/none 
    inet6 fe80::87c7:b580:3fcf:e493/64 scope link
    # ❌ No inet (IPv4) address!
```

## ✅ The Solution

This repository provides scripts to automatically apply a systemd service override that ensures Tailscale waits for the network to be fully ready before starting.

**What it does:**
- Adds `network-online.target` dependency to tailscaled service
- Includes a 5-second stabilization delay
- Ensures IP binding succeeds on every boot
- Works across all Debian/Ubuntu-based LXCs

## 🚀 Quick Start

### 1. Upload Scripts to Proxmox Host

SSH into your Proxmox host and download the scripts:

```bash
# SSH to Proxmox host
ssh root@pve

# Download the repository
git clone https://github.com/yourusername/proxmox-tailscale-fix.git
cd proxmox-tailscale-fix

# Make scripts executable
chmod +x *.sh
```

Or download individual scripts:
```bash
wget https://raw.githubusercontent.com/yourusername/proxmox-tailscale-fix/main/tailscale-mass-fix.sh
wget https://raw.githubusercontent.com/yourusername/proxmox-tailscale-fix/main/tailscale-verify.sh
chmod +x *.sh
```

### 2. Check Current Status

See which LXCs have Tailscale and their current status:

```bash
./tailscale-verify.sh
```

**Example output:**
```
CTID   NAME                 TAILSCALE  IP ADDRESS         OVERRIDE STATUS
────────────────────────────────────────────────────────────────────────────────
101    jellyfin             Yes        100.70.231.28      No       ✓ OK
102    sonarr               Yes        100.108.69.63      No       ⚠ IP not bound
103    radarr               Yes        100.72.34.122      No       ✓ OK
104    adguard              Disabled   -                  No       ✗ Disabled
```

**Legend:**
- `✓ OK` - Working (for now, but needs fix to survive reboots)
- `⚠ IP not bound` - Needs fix immediately
- `✗ No IP` - Not authenticated to Tailscale
- `✗ Disabled` - Service disabled (will be skipped)

### 3. Apply the Fix

Run the mass-fix script to apply the systemd override to all Tailscale LXCs:

```bash
./tailscale-mass-fix.sh
```

**The script will:**
- ✅ Auto-detect all LXCs with Tailscale
- ✅ Skip LXCs without Tailscale (safe!)
- ✅ Skip disabled Tailscale services
- ✅ Skip already-fixed LXCs
- ✅ Apply systemd override to eligible LXCs
- ✅ Restart tailscaled to apply immediately
- ✅ Verify IP assignment

**Example output:**
```
═══════════════════════════════════════════════════════════
=== Tailscale Mass Fix for Proxmox LXCs ===
═══════════════════════════════════════════════════════════
Starting at Sun Feb  8 14:00:00 PST 2026

Found 26 running LXCs

[1/26] ─────────────────────────────────────
Checking LXC 101 (jellyfin)...
  ✓ Tailscale detected and enabled
  → Applying fix...
  ✓ Fix applied and tailscaled restarted
  ✓ Tailscale IP: 100.70.231.28

[2/26] ─────────────────────────────────────
Checking LXC 102 (sonarr)...
  ✓ Tailscale detected and enabled
  → Applying fix...
  ✓ Fix applied and tailscaled restarted
  ✓ Tailscale IP: 100.108.69.63

... (continues for all LXCs) ...

═══════════════════════════════════════════════════════════
=== Summary ===
═══════════════════════════════════════════════════════════
Total LXCs checked:  26
Fixed:               12 LXCs
Skipped:             14 LXCs
Failed:              0 LXCs

✓ SUCCESS: Applied fix to 12 LXC(s)
```

### 4. Verify the Fix

```bash
./tailscale-verify.sh
```

All Tailscale LXCs should now show:
- **Override: Yes** ✅
- **Status: ✓ OK** ✅

## 📁 Repository Contents

| File | Description |
|------|-------------|
| **tailscale-mass-fix.sh** | Main script - applies fix to all Tailscale LXCs |
| **tailscale-verify.sh** | Check status of all LXCs before/after fix |
| **fix-no-ip-lxcs.sh** | Helper script for authenticating unauthenticated LXCs |
| **tailscale-monitor.sh** | Optional monitoring script for individual LXCs |
| **README.md** | This file |
| **SKIP-LIST-CONFIG.md** | Guide for excluding specific LXCs |

## ⚙️ Configuration

### Excluding Specific LXCs

If you have LXCs with Tailscale that you want to skip (e.g., disabled services):

1. Edit `tailscale-mass-fix.sh`
2. Find the configuration section at the top:

```bash
#############################################
# CONFIGURATION
#############################################

# LXCs to skip (space-separated list of CTIDs)
# Example: SKIP_LXCS="105 225 229"
SKIP_LXCS=""
```

3. Add your CTIDs:

```bash
SKIP_LXCS="105 225 229"
```

4. Save and run the script

**Note:** Disabled Tailscale services are automatically skipped even without adding them to SKIP_LXCS.

## 🔧 What the Fix Does

The script creates this systemd override file in each Tailscale LXC:

**`/etc/systemd/system/tailscaled.service.d/override.conf`**

```ini
[Unit]
After=network-online.target
Wants=network-online.target

[Service]
# Add a small delay to ensure network is fully ready
ExecStartPre=/bin/sleep 5
```

**This ensures:**
1. Tailscale waits for `network-online.target`
2. 5-second network stabilization delay
3. IP binding succeeds on every boot
4. Survives LXC reboots and restores

## 🧪 Testing

### Test the Fix (Optional but Recommended)

Pick a non-critical LXC and reboot it to verify the fix persists:

```bash
# Reboot an LXC
pct reboot 101

# Wait for it to come back up
sleep 30

# Check if IP is bound to interface
pct exec 101 -- tailscale ip -4
pct exec 101 -- ip addr show tailscale0 | grep "inet "
```

Both commands should show the IP address.

## 🐛 Troubleshooting

### LXCs Show "✗ No IP" After Fix

These LXCs aren't authenticated to your Tailscale network. Use the helper script:

```bash
./fix-no-ip-lxcs.sh
```

Or manually authenticate:
```bash
pct enter <CTID>
tailscale up
# Follow the authentication URL
exit
```

### Script Shows "Failed" for Some LXCs

Check the log for details:
```bash
cat /var/log/tailscale-mass-fix.log | grep ERROR
```

Common causes:
- LXC doesn't have systemd
- Permission issues
- Tailscale not properly installed

### Want to Remove the Fix

To undo the fix for a specific LXC:

```bash
pct exec <CTID> -- rm -f /etc/systemd/system/tailscaled.service.d/override.conf
pct exec <CTID> -- systemctl daemon-reload
pct exec <CTID> -- systemctl restart tailscaled
```

### Fix Only Specific LXCs

Edit `tailscale-mass-fix.sh` and change this line:

```bash
RUNNING_LXCS=$(pct list | awk 'NR>1 && $2=="running" {print $1}')
```

To specify CTIDs:
```bash
RUNNING_LXCS="101 102 103"  # Only fix these LXCs
```

## 📊 Advanced Usage

### Running on Specific LXCs Only

```bash
# Edit the script
nano tailscale-mass-fix.sh

# Find and modify:
RUNNING_LXCS="101 102 103"  # Replace auto-detection with specific CTIDs
```

### Adding Monitoring (Optional)

Set up automatic monitoring to catch and fix issues if they recur:

1. Copy `tailscale-monitor.sh` to each LXC:
```bash
pct push <CTID> tailscale-monitor.sh /usr/local/bin/tailscale-monitor.sh
pct exec <CTID> -- chmod +x /usr/local/bin/tailscale-monitor.sh
```

2. Add to crontab:
```bash
pct exec <CTID> -- bash -c 'echo "*/5 * * * * /usr/local/bin/tailscale-monitor.sh" | crontab -'
```

This checks every 5 minutes and auto-restarts Tailscale if the IP is missing.

### View Logs

All actions are logged to `/var/log/tailscale-mass-fix.log` on the Proxmox host:

```bash
# View full log
cat /var/log/tailscale-mass-fix.log

# View only errors
grep ERROR /var/log/tailscale-mass-fix.log

# View only successful fixes
grep SUCCESS /var/log/tailscale-mass-fix.log

# Follow in real-time
tail -f /var/log/tailscale-mass-fix.log
```

## 🏗️ Manual Fix (Single LXC)

If you prefer to fix LXCs individually:

```bash
# Enter the LXC
pct enter <CTID>

# Create override directory
mkdir -p /etc/systemd/system/tailscaled.service.d/

# Create override file
cat > /etc/systemd/system/tailscaled.service.d/override.conf <<'EOF'
[Unit]
After=network-online.target
Wants=network-online.target

[Service]
ExecStartPre=/bin/sleep 5
EOF

# Apply the fix
systemctl daemon-reload
systemctl restart tailscaled

# Verify
tailscale ip -4
ip addr show tailscale0 | grep "inet "

# Exit LXC
exit
```

## 🔍 How It Works

### Root Cause

Proxmox LXCs boot in 2-3 seconds - often faster than the network subsystem initializes. When Tailscale starts prematurely:

1. ✅ Tailscale daemon starts
2. ✅ Connects to Tailscale control plane
3. ✅ Receives IP assignment
4. ❌ **Fails to bind IP to network interface** (network not ready)

Result: Tailscale appears to be working, but connection attempts time out.

### The Fix

The systemd override ensures proper startup ordering:

```
network.target → network-online.target → [5-second delay] → tailscaled.service
```

This guarantees the network is fully ready before Tailscale attempts IP binding.

## ✅ Success Criteria

After running the mass-fix script, you should see:

- ✅ All Tailscale LXCs show "Override: Yes"
- ✅ All authenticated LXCs show "✓ OK" status  
- ✅ Log shows "Fixed: X LXCs" where X > 0
- ✅ No errors in `/var/log/tailscale-mass-fix.log`
- ✅ IP addresses survive LXC reboots

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

MIT License - feel free to use and modify for your own infrastructure.

## 🙏 Acknowledgments

- Inspired by common Tailscale LXC issues in the Proxmox community
- Built using Proxmox `pct` commands and systemd service management
- Tested on Proxmox VE 8.x with Debian 12/13 LXCs

## 📞 Support

If you encounter issues:

1. Check the [Troubleshooting](#-troubleshooting) section
2. Review `/var/log/tailscale-mass-fix.log` on your Proxmox host
3. Run `./tailscale-verify.sh` to check current status
4. Open an issue with:
   - Proxmox VE version
   - LXC OS (Debian/Ubuntu version)
   - Tailscale version
   - Output from `tailscale-verify.sh`
   - Relevant log excerpts

## 🎯 Related Issues

This fix addresses issues commonly reported as:
- "Tailscale not working after LXC reboot"
- "Can't connect to LXC via Tailscale"
- "Tailscale shows IP but connection times out"
- "tailscale0 interface has no IPv4 address"

## ⚡ Quick Reference

| Command | Purpose |
|---------|---------|
| `./tailscale-verify.sh` | Check status of all LXCs |
| `./tailscale-mass-fix.sh` | Apply fix to all Tailscale LXCs |
| `./fix-no-ip-lxcs.sh` | Authenticate unauthenticated LXCs |
| `cat /var/log/tailscale-mass-fix.log` | View operation log |
| `pct reboot <CTID>` | Test fix with reboot |
| `pct exec <CTID> -- tailscale status` | Check Tailscale status |
| `pct exec <CTID> -- ip addr show tailscale0` | Check interface binding |

---

**Made with ❤️ for the Proxmox community**

If this helped you, please ⭐ star the repository!
