# Skip List Configuration

> How to exclude specific LXCs from the fix

---

## Quick Setup

Edit `tailscale-mass-fix.sh`:

```bash
nano tailscale-mass-fix.sh
```

Find this section:

```bash
# LXCs to skip (space-separated list)
SKIP_LXCS=""
```

Add your LXC IDs:

```bash
SKIP_LXCS="105 225 229"
```

Save and exit.

---

## When to Use

**Add to skip list when:**
- Tailscale is intentionally disabled (e.g., DNS server)
- Testing specific LXCs first
- LXC has custom Tailscale config

**Don't need to add when:**
- Service is disabled (auto-skipped)
- Tailscale not installed (auto-skipped)
- Already fixed (auto-skipped)

---

## Example Scenarios

### Scenario 1: Disabled AdGuard DNS

```bash
# LXC 105 is your main DNS - Tailscale disabled
SKIP_LXCS="105"
```

### Scenario 2: Multiple Test LXCs

```bash
# Fix everything except test environments
SKIP_LXCS="200 201 202"
```

### Scenario 3: Fix Specific LXCs Only

Edit script directly:

```bash
# Around line 60, change:
RUNNING_LXCS=$(pct list | awk 'NR>1 && $2=="running" {print $1}')

# To:
RUNNING_LXCS="101 102 103"  # Only these LXCs
```

---

## What Gets Skipped

The script automatically skips:

1. **In SKIP_LXCS** → Shows "In skip list"
2. **No Tailscale** → Shows "Tailscale not installed"
3. **Service disabled** → Shows "tailscaled is disabled"
4. **Already fixed** → Shows "Already has override"

---

## Verification

After configuring, verify:

```bash
./tailscale-verify.sh
```

Skipped LXCs show:
- Disabled services: `✗ Disabled` (gray)
- Others: Not listed or marked as skipped

---

## Quick Reference

```bash
# Skip one LXC
SKIP_LXCS="105"

# Skip multiple LXCs
SKIP_LXCS="105 225 229"

# Skip nothing (default)
SKIP_LXCS=""
```

---

**Note:** Disabled services are auto-skipped. Adding them to SKIP_LXCS just makes it explicit in the output.
