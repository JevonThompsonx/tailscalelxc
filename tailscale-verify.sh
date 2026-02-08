#!/usr/bin/env bash
# Verify Tailscale Status Across All LXCs
# Run this on your Proxmox HOST

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GRAY='\033[0;90m'
NC='\033[0m'

echo -e "${BLUE}=== Tailscale Status Check Across All LXCs ===${NC}"
echo ""

# Check if running on Proxmox host
if ! command -v pct &> /dev/null; then
    echo -e "${RED}ERROR: This script must be run on the Proxmox host!${NC}"
    exit 1
fi

# Get list of all running LXCs
RUNNING_LXCS=$(pct list | awk 'NR>1 && $2=="running" {print $1}')

if [ -z "$RUNNING_LXCS" ]; then
    echo -e "${YELLOW}No running LXCs found!${NC}"
    exit 0
fi

printf "%-6s %-20s %-10s %-18s %-8s %s\n" "CTID" "NAME" "TAILSCALE" "IP ADDRESS" "OVERRIDE" "STATUS"
echo "────────────────────────────────────────────────────────────────────────────────"

for CTID in $RUNNING_LXCS; do
    LXC_NAME=$(pct list | awk -v id="$CTID" '$1==id {print $3}')
    
    # Check if Tailscale is installed
    if ! pct exec "$CTID" -- bash -c 'command -v tailscale' &>/dev/null; then
        printf "%-6s %-20s %-10s %-18s %-8s %s\n" \
            "$CTID" "$LXC_NAME" "No" "-" "-" "-"
        continue
    fi
    
    # Check if tailscaled service exists
    if ! pct exec "$CTID" -- systemctl list-unit-files 2>/dev/null | grep -q "tailscaled.service"; then
        printf "%-6s %-20s %-10s %-18s %-8s %s\n" \
            "$CTID" "$LXC_NAME" "Installed" "-" "-" "${GRAY}No service${NC}"
        continue
    fi
    
    # Check if tailscaled is enabled
    if ! pct exec "$CTID" -- systemctl is-enabled --quiet tailscaled 2>/dev/null; then
        # Check for override even if disabled
        if pct exec "$CTID" -- test -f /etc/systemd/system/tailscaled.service.d/override.conf 2>/dev/null; then
            HAS_OVERRIDE="${GRAY}Yes${NC}"
        else
            HAS_OVERRIDE="${GRAY}No${NC}"
        fi
        
        printf "%-6s %-20s %-10s %-18s " "$CTID" "$LXC_NAME" "Disabled" "-"
        echo -e "$HAS_OVERRIDE   ${GRAY}✗ Disabled${NC}"
        continue
    fi
    
    # Check if tailscaled is running
    if pct exec "$CTID" -- systemctl is-active --quiet tailscaled 2>/dev/null; then
        TS_RUNNING="Yes"
        
        # Get Tailscale IP
        TS_IP=$(pct exec "$CTID" -- tailscale ip -4 2>/dev/null || echo "No IP")
        
        # Check if IP is bound to interface
        if [ "$TS_IP" != "No IP" ]; then
            if pct exec "$CTID" -- ip addr show tailscale0 2>/dev/null | grep -q "inet $TS_IP"; then
                STATUS="${GREEN}✓ OK${NC}"
            else
                STATUS="${YELLOW}⚠ IP not bound${NC}"
            fi
        else
            STATUS="${RED}✗ No IP${NC}"
        fi
    else
        TS_RUNNING="No"
        TS_IP="-"
        STATUS="${RED}✗ Not running${NC}"
    fi
    
    # Check if override exists
    if pct exec "$CTID" -- test -f /etc/systemd/system/tailscaled.service.d/override.conf 2>/dev/null; then
        HAS_OVERRIDE="${GREEN}Yes${NC}"
    else
        HAS_OVERRIDE="${YELLOW}No${NC}"
    fi
    
    printf "%-6s %-20s %-10s %-18s " "$CTID" "$LXC_NAME" "$TS_RUNNING" "$TS_IP"
    echo -e "$HAS_OVERRIDE   $STATUS"
done

echo ""
echo -e "${BLUE}Legend:${NC}"
echo -e "  ${GREEN}✓ OK${NC}          - Tailscale running with IP bound to interface"
echo -e "  ${YELLOW}⚠ IP not bound${NC}  - Tailscale has IP but it's not on interface (needs fix)"
echo -e "  ${RED}✗ No IP${NC}        - Tailscale running but no IP assigned"
echo -e "  ${RED}✗ Not running${NC}  - Tailscaled service not active"
echo -e "  ${GRAY}✗ Disabled${NC}     - Tailscaled service is disabled (skipped)"
echo ""
echo -e "${BLUE}Override:${NC} Systemd fix applied to ensure IP binds on boot"
