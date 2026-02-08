#!/usr/bin/env bash
# Mass Apply Tailscale Fix to All LXCs
# Run this on your Proxmox HOST (not inside LXCs)

set -euo pipefail

#############################################
# CONFIGURATION
#############################################

# LXCs to skip (space-separated list of CTIDs)
# Example: SKIP_LXCS="105 225 229"
SKIP_LXCS="105 225 229"

#############################################
# Don't edit below this line
#############################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Log file
LOG_FILE="/var/log/tailscale-mass-fix.log"

log() {
    echo -e "${2}${1}${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_only() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Check if LXC is in skip list
should_skip_lxc() {
    local ctid=$1
    for skip_id in $SKIP_LXCS; do
        if [ "$ctid" = "$skip_id" ]; then
            return 0  # Should skip
        fi
    done
    return 1  # Don't skip
}

# Check if running on Proxmox host
if ! command -v pct &> /dev/null; then
    log "ERROR: This script must be run on the Proxmox host, not inside an LXC!" "$RED"
    exit 1
fi

log "═══════════════════════════════════════════════════════════" "$BLUE"
log "=== Tailscale Mass Fix for Proxmox LXCs ===" "$BLUE"
log "═══════════════════════════════════════════════════════════" "$BLUE"
log "Starting at $(date)" "$CYAN"

if [ -n "$SKIP_LXCS" ]; then
    log "Skip list: $SKIP_LXCS" "$YELLOW"
fi

log "" "$NC"

# Get list of all running LXCs
RUNNING_LXCS=$(pct list | awk 'NR>1 && $2=="running" {print $1}')

if [ -z "$RUNNING_LXCS" ]; then
    log "No running LXCs found!" "$YELLOW"
    exit 0
fi

TOTAL=0
FIXED=0
SKIPPED=0
FAILED=0

# Count total
for CTID in $RUNNING_LXCS; do
    ((TOTAL++))
done

log "Found $TOTAL running LXCs" "$CYAN"
log "" "$NC"

CURRENT=0
for CTID in $RUNNING_LXCS; do
    ((CURRENT++))
    LXC_NAME=$(pct list | awk -v id="$CTID" '$1==id {print $3}')
    
    log "[$CURRENT/$TOTAL] ─────────────────────────────────────" "$NC"
    log "Checking LXC $CTID ($LXC_NAME)..." "$BLUE"
    log_only "Processing LXC $CTID ($LXC_NAME)"
    
    # Check if in skip list
    if should_skip_lxc "$CTID"; then
        log "  ↪ Skipping: In skip list (SKIP_LXCS)" "$GRAY"
        log_only "SKIP: LXC $CTID ($LXC_NAME) - In skip list"
        ((SKIPPED++))
        continue
    fi
    
    # Check if Tailscale is installed
    if ! pct exec "$CTID" -- bash -c 'command -v tailscale' &>/dev/null; then
        log "  ↪ Skipping: Tailscale not installed" "$YELLOW"
        log_only "SKIP: LXC $CTID ($LXC_NAME) - No Tailscale"
        ((SKIPPED++))
        continue
    fi
    
    # Check if tailscaled service exists
    if ! pct exec "$CTID" -- systemctl list-unit-files 2>/dev/null | grep -q "tailscaled.service"; then
        log "  ↪ Skipping: tailscaled service not found" "$YELLOW"
        log_only "SKIP: LXC $CTID ($LXC_NAME) - No tailscaled service"
        ((SKIPPED++))
        continue
    fi
    
    # Check if tailscaled is enabled
    if ! pct exec "$CTID" -- systemctl is-enabled --quiet tailscaled 2>/dev/null; then
        log "  ↪ Skipping: tailscaled is disabled" "$GRAY"
        log_only "SKIP: LXC $CTID ($LXC_NAME) - Service disabled"
        ((SKIPPED++))
        continue
    fi
    
    log "  ✓ Tailscale detected and enabled" "$GREEN"
    
    # Check if already has the override
    if pct exec "$CTID" -- test -f /etc/systemd/system/tailscaled.service.d/override.conf 2>/dev/null; then
        log "  ↪ Already has override, skipping" "$YELLOW"
        log_only "SKIP: LXC $CTID ($LXC_NAME) - Already has override"
        ((SKIPPED++))
        continue
    fi
    
    log "  → Applying fix..." "$CYAN"
    
    # Create the override directory
    if ! pct exec "$CTID" -- mkdir -p /etc/systemd/system/tailscaled.service.d/ 2>&1 | tee -a "$LOG_FILE" >/dev/null; then
        log "  ✗ Failed to create override directory" "$RED"
        log_only "ERROR: Failed to create directory in LXC $CTID ($LXC_NAME)"
        ((FAILED++))
        continue
    fi
    
    # Create the override file
    if ! pct exec "$CTID" -- bash -c 'cat > /etc/systemd/system/tailscaled.service.d/override.conf <<EOF
[Unit]
After=network-online.target
Wants=network-online.target

[Service]
# Add a small delay to ensure network is fully ready
ExecStartPre=/bin/sleep 5
EOF' 2>&1 | tee -a "$LOG_FILE" >/dev/null; then
        log "  ✗ Failed to create override file" "$RED"
        log_only "ERROR: Failed to create override file in LXC $CTID ($LXC_NAME)"
        ((FAILED++))
        continue
    fi
    
    # Reload systemd daemon
    if ! pct exec "$CTID" -- systemctl daemon-reload 2>&1 | tee -a "$LOG_FILE" >/dev/null; then
        log "  ✗ Failed to reload systemd" "$RED"
        log_only "ERROR: Failed to reload systemd in LXC $CTID ($LXC_NAME)"
        ((FAILED++))
        continue
    fi
    
    # Restart tailscaled to apply immediately
    log "  → Restarting tailscaled..." "$CYAN"
    if pct exec "$CTID" -- systemctl restart tailscaled 2>&1 | tee -a "$LOG_FILE" >/dev/null; then
        log "  ✓ Fix applied and tailscaled restarted" "$GREEN"
        
        # Give it a moment and verify IP assignment
        sleep 3
        TAILSCALE_IP=$(pct exec "$CTID" -- tailscale ip -4 2>/dev/null || echo "")
        if [ -n "$TAILSCALE_IP" ]; then
            log "  ✓ Tailscale IP: $TAILSCALE_IP" "$GREEN"
            log_only "SUCCESS: Fixed LXC $CTID ($LXC_NAME) - IP: $TAILSCALE_IP"
        else
            log "  ⚠ Tailscaled restarted but no IP assigned" "$YELLOW"
            log "  → This may be normal if not authenticated to Tailscale" "$YELLOW"
            log_only "WARNING: Fixed LXC $CTID ($LXC_NAME) but no IP assigned"
        fi
        ((FIXED++))
    else
        log "  ⚠ Fix applied but failed to restart tailscaled" "$YELLOW"
        log "  → Manual restart: pct exec $CTID -- systemctl restart tailscaled" "$YELLOW"
        log_only "PARTIAL: Fixed LXC $CTID ($LXC_NAME) but restart failed"
        ((FIXED++))
    fi
done

log "" "$NC"
log "═══════════════════════════════════════════════════════════" "$NC"
log "=== Summary ===" "$BLUE"
log "═══════════════════════════════════════════════════════════" "$NC"
log "Total LXCs checked:  $TOTAL" "$CYAN"
log "Fixed:               $FIXED LXCs" "$GREEN"
log "Skipped:             $SKIPPED LXCs" "$YELLOW"
log "Failed:              $FAILED LXCs" "$RED"
log "" "$NC"
log "Full log saved to: $LOG_FILE" "$BLUE"

if [ $FIXED -gt 0 ]; then
    log "" "$NC"
    log "✓ SUCCESS: Applied fix to $FIXED LXC(s)" "$GREEN"
    log "" "$NC"
    log "RECOMMENDATION: Test with a reboot when convenient" "$CYAN"
    log "Example: pct reboot <CTID>" "$CYAN"
    log "" "$NC"
fi

if [ $FAILED -gt 0 ]; then
    log "" "$NC"
    log "⚠ Some LXCs failed. Check the log for details:" "$YELLOW"
    log "   cat $LOG_FILE | grep ERROR" "$YELLOW"
fi

log "" "$NC"
log "Completed at $(date)" "$CYAN"
log "═══════════════════════════════════════════════════════════" "$NC"

# Exit with appropriate code
if [ $FAILED -gt 0 ]; then
    exit 1
else
    exit 0
fi
