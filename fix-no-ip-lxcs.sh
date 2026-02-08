#!/usr/bin/env bash
# Fix "No IP" Tailscale LXCs
# Run on Proxmox host to fix LXCs that have Tailscale but no IP assigned

#############################################
# CONFIGURATION
#############################################

# Leave empty to auto-detect from verification, or specify manually
# Example: NO_IP_LXCS="105 225 229"
NO_IP_LXCS=""

# Set to "yes" to skip prompts and just show authentication URLs
AUTO_MODE="no"

#############################################
# Don't edit below this line
#############################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Fixing Tailscale 'No IP' LXCs ===${NC}"
echo ""

# Check if running on Proxmox host
if ! command -v pct &> /dev/null; then
    echo -e "${RED}ERROR: This script must be run on the Proxmox host!${NC}"
    exit 1
fi

# Auto-detect if not specified
if [ -z "$NO_IP_LXCS" ]; then
    echo "Auto-detecting LXCs with 'No IP' status..."
    NO_IP_LXCS=""
    
    RUNNING_LXCS=$(pct list | awk 'NR>1 && $2=="running" {print $1}')
    
    for CTID in $RUNNING_LXCS; do
        # Check if has Tailscale and is enabled
        if pct exec "$CTID" -- bash -c 'command -v tailscale' &>/dev/null && \
           pct exec "$CTID" -- systemctl is-enabled --quiet tailscaled 2>/dev/null && \
           pct exec "$CTID" -- systemctl is-active --quiet tailscaled 2>/dev/null; then
            
            # Check if has no IP
            TS_IP=$(pct exec "$CTID" -- tailscale ip -4 2>/dev/null || echo "")
            if [ -z "$TS_IP" ]; then
                NO_IP_LXCS="$NO_IP_LXCS $CTID"
            fi
        fi
    done
    
    NO_IP_LXCS=$(echo "$NO_IP_LXCS" | xargs)  # Trim whitespace
fi

if [ -z "$NO_IP_LXCS" ]; then
    echo -e "${GREEN}✓ No LXCs found with 'No IP' status!${NC}"
    exit 0
fi

echo -e "Found LXCs with 'No IP': ${YELLOW}$NO_IP_LXCS${NC}"
echo ""
echo "This will attempt to authenticate and fix these LXCs."
echo ""

if [ "$AUTO_MODE" != "yes" ]; then
    read -p "Continue? [Y/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ -n $REPLY ]]; then
        echo "Aborted."
        exit 0
    fi
    echo ""
fi

for CTID in $NO_IP_LXCS; do
    LXC_NAME=$(pct list | awk -v id="$CTID" '$1==id {print $3}')
    
    echo -e "${BLUE}─────────────────────────────────────${NC}"
    echo -e "${BLUE}LXC $CTID ($LXC_NAME)${NC}"
    echo ""
    
    # Check if LXC is running
    if ! pct status "$CTID" | grep -q "running"; then
        echo -e "  ${YELLOW}⚠ LXC is not running. Starting it...${NC}"
        pct start "$CTID"
        sleep 5
    fi
    
    # Check if Tailscale is installed
    if ! pct exec "$CTID" -- bash -c 'command -v tailscale' &>/dev/null; then
        echo -e "  ${RED}✗ Tailscale not found. Skipping.${NC}"
        continue
    fi
    
    # Check if disabled
    if ! pct exec "$CTID" -- systemctl is-enabled --quiet tailscaled 2>/dev/null; then
        echo -e "  ${YELLOW}⚠ Tailscaled is disabled. Skipping.${NC}"
        echo -e "  → To enable: pct exec $CTID -- systemctl enable tailscaled${NC}"
        continue
    fi
    
    # Check current IP
    CURRENT_IP=$(pct exec "$CTID" -- tailscale ip -4 2>/dev/null || echo "")
    
    if [ -n "$CURRENT_IP" ]; then
        echo -e "  ${GREEN}✓ Already has IP: $CURRENT_IP${NC}"
        continue
    fi
    
    echo -e "  ${CYAN}→ No IP found. Attempting to authenticate...${NC}"
    echo ""
    
    # Try to bring up Tailscale (will show auth URL)
    echo -e "${YELLOW}  Authentication URL:${NC}"
    pct exec "$CTID" -- tailscale up 2>&1 | grep -A 2 "To authenticate" || true
    echo ""
    
    if [ "$AUTO_MODE" = "yes" ]; then
        sleep 2
    else
        echo -e "  ${YELLOW}→ Please authenticate via the URL above${NC}"
        read -p "  Press Enter when done (or Ctrl+C to skip)..."
    fi
    
    # Check if it worked
    sleep 2
    CURRENT_IP=$(pct exec "$CTID" -- tailscale ip -4 2>/dev/null || echo "")
    if [ -n "$CURRENT_IP" ]; then
        echo -e "  ${GREEN}✓ Success! IP: $CURRENT_IP${NC}"
    else
        echo -e "  ${YELLOW}⚠ Authentication may still be pending${NC}"
        echo -e "  ${YELLOW}→ Check status: pct exec $CTID -- tailscale status${NC}"
    fi
    
    echo ""
done

echo -e "${BLUE}─────────────────────────────────────${NC}"
echo -e "${GREEN}Done! Run ./tailscale-verify.sh to check results.${NC}"
