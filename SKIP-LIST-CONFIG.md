# How to Configure Skip List

## Quick Setup

If you have LXCs with Tailscale that you want to **exclude** from the mass-fix script (like disabled AdGuard), edit the script:

```bash
nano tailscale-mass-fix.sh
```

Find this section at the top:

```bash
#############################################
# CONFIGURATION
#############################################

# LXCs to skip (space-separated list of CTIDs)
# Example: SKIP_LXCS="105 225 229"
SKIP_LXCS=""
```

Change it to include your CTIDs:

```bash
SKIP_LXCS="105 225 229"
```

Save and exit (Ctrl+X, Y, Enter).

---

## Your Specific Case

Based on your output, you have 3 LXCs with disabled or unwanted Tailscale:

| CTID | Name | Status | What You Did |
|------|------|--------|--------------|
| 105 | adguardMainNetDns | Disabled | `systemctl disable tailscaled` |
| 225 | uptimekuma | No IP | (Not disabled yet) |
| 229 | adguard | No IP | (Not disabled yet) |

### Recommended Configuration

Since you disabled Tailscale on adguardMainNetDns and want to skip it:

```bash
SKIP_LXCS="105"
```

Or if you want to skip all three:

```bash
SKIP_LXCS="105 225 229"
```

---

## How It Works

The script will:
1. Check each running LXC
2. If CTID is in SKIP_LXCS → Skip it (shows as "In skip list")
3. If Tailscale is not installed → Skip it
4. If tailscaled is disabled → Skip it (automatic)
5. If already has override → Skip it
6. Otherwise → Apply the fix

---

## Updated Scripts

I've updated the scripts to:

### ✅ tailscale-verify.sh
- Shows disabled Tailscale services in gray
- Clearly marks them as "✗ Disabled"
- Won't show "No IP" for disabled services anymore

### ✅ tailscale-mass-fix.sh
- Has SKIP_LXCS configuration at the top
- Automatically skips disabled services
- Shows which LXCs are being skipped and why

### ✅ fix-no-ip-lxcs.sh
- Auto-detects LXCs with "No IP"
- Skips disabled services automatically
- Less intrusive prompts

---

## Example Output After Configuration

With `SKIP_LXCS="105 225 229"` configured:

```
=== Tailscale Mass Fix for Proxmox LXCs ===
Starting at Sun Feb  8 13:30:00 PST 2026
Skip list: 105 225 229

Found 26 running LXCs

[1/26] ─────────────────────────────────────
Checking LXC 105 (adguardMainNetDns)...
  ↪ Skipping: In skip list (SKIP_LXCS)

[2/26] ─────────────────────────────────────
Checking LXC 109 (jellyfin)...
  ✓ Tailscale detected and enabled
  → Applying fix...
  ✓ Fix applied and tailscaled restarted
  ✓ Tailscale IP: 100.70.231.28

... (continues for other LXCs) ...
```

And `tailscale-verify.sh` will show:

```
CTID   NAME                 TAILSCALE  IP ADDRESS         OVERRIDE STATUS
────────────────────────────────────────────────────────────────────────────────
105    adguardMainNetDns    Disabled   -                  No       ✗ Disabled
109    jellyfin             Yes        100.70.231.28      Yes      ✓ OK
```

---

## Default Behavior

**If you don't configure SKIP_LXCS:**
- Script automatically skips disabled services
- LXC 105 will be skipped because you disabled tailscaled
- LXCs 225 and 229 will be processed if tailscaled is enabled

**The updated script already skips disabled services**, so you technically don't need to add them to SKIP_LXCS. But adding them makes it explicit and shows in the output "In skip list".

---

## Quick Commands

```bash
# On pveBig

# Upload the updated scripts (already done via earlier uploads)

# Configure skip list (optional - disabled services are auto-skipped)
nano tailscale-mass-fix.sh
# Edit SKIP_LXCS line, save

# Run verification
./tailscale-verify.sh

# Run mass fix
./tailscale-mass-fix.sh

# Verify results
./tailscale-verify.sh
```

---

## Recommendation

Based on what you've shown:

1. **Keep LXC 105 disabled** - You don't want Tailscale on your main DNS
2. **Either disable or authenticate 225 & 229**:
   - To disable: `pct exec 225 -- systemctl disable tailscaled && systemctl stop tailscaled`
   - To authenticate: Use the fix-no-ip-lxcs.sh script

3. **Run the mass-fix** - It will automatically skip disabled ones and fix the rest
