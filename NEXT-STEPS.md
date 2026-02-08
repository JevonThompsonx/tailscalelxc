# Next Steps

> What to do after downloading the scripts

---

## ⚡ Quick Action Plan

```bash
# 1. Check current status
./tailscale-verify.sh

# 2. Apply the fix
./tailscale-mass-fix.sh

# 3. Verify it worked
./tailscale-verify.sh

# Done!
```

---

## 📊 Current Situation

Based on your verification output, you likely have:

### ✅ Working (Need Fix for Reboot Safety)
- LXCs showing `Override: No` + `Status: ✓ OK`
- Working now, but will break on reboot
- **Action:** Run `./tailscale-mass-fix.sh`

### ⚠️ IP Not Bound (Need Fix Now)
- LXCs showing `⚠ IP not bound`
- Not working currently
- **Action:** Run `./tailscale-mass-fix.sh` immediately

### ❌ No IP (Need Authentication)
- LXCs showing `✗ No IP`
- Not authenticated to Tailscale
- **Action:** Run `./fix-no-ip-lxcs.sh`

### 🔇 Disabled (Skip These)
- LXCs showing `✗ Disabled`
- Tailscale intentionally off
- **Action:** None (auto-skipped)

---

## 🎯 Expected Results

### Before:
```
CTID   NAME        OVERRIDE   STATUS
101    jellyfin    No         ✓ OK
102    sonarr      No         ⚠ IP not bound
105    adguard     No         ✗ Disabled
```

### After Mass Fix:
```
CTID   NAME        OVERRIDE   STATUS
101    jellyfin    Yes        ✓ OK
102    sonarr      Yes        ✓ OK
105    adguard     No         ✗ Disabled (skipped)
```

### Summary Output:
```
Fixed:   12 LXCs ✓
Skipped: 14 LXCs
Failed:  0 LXCs
```

---

## 🧪 Optional: Test Reboot

Pick a non-critical LXC:

```bash
# Reboot
pct reboot 101

# Wait
sleep 30

# Verify IP persists
pct exec 101 -- tailscale ip -4
# Should show: 100.70.231.28
```

---

## ❓ Common Questions

**Q: Will this break my Tailscale config?**  
A: No. Only adds a systemd startup delay.

**Q: What if I have disabled Tailscale on some LXCs?**  
A: Auto-skipped. No action needed.

**Q: Can I run it multiple times?**  
A: Yes. Already-fixed LXCs are skipped.

**Q: What about LXCs with "No IP"?**  
A: Use `./fix-no-ip-lxcs.sh` to authenticate them.

---

## 📝 Full Commands

```bash
# Check status
./tailscale-verify.sh

# Fix all Tailscale LXCs
./tailscale-mass-fix.sh

# Authenticate unauthenticated LXCs
./fix-no-ip-lxcs.sh

# View operation log
cat /var/log/tailscale-mass-fix.log

# Test reboot
pct reboot <CTID>
```

---

## 🎉 You're Done!

Your Tailscale LXCs are now:
- ✅ Fixed and working
- ✅ Reboot-safe
- ✅ Ready for production

No further action needed unless you add new Tailscale LXCs (just re-run the fix script).

---

**Need help?** Check the main [README](README.md) or [open an issue](../../issues).
