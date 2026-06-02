#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# SPDX-FileCopyrightText: 2025 Hyperpolymath
#
# Health check for ZeroTier mesh connectivity

set -euo pipefail

NETWORK_ID="${1:-}"

if [ -z "$NETWORK_ID" ]; then
    echo "Usage: $0 <network-id> [target-ip]"
    exit 1
fi

TARGET_IP="${2:-}"

echo "=== ZeroTier Health Check ==="
echo ""

# Check ZeroTier service status
echo "1. Service Status:"
if zerotier-cli info &> /dev/null; then
    zerotier-cli info
    echo "✓ Service is running"
else
    echo "✗ Service is not running"
    exit 1
fi

echo ""
echo "2. Network Status:"
if zerotier-cli listnetworks | grep -q "$NETWORK_ID"; then
    zerotier-cli listnetworks | grep "$NETWORK_ID"
    
    # Check if OK status
    if zerotier-cli listnetworks | grep "$NETWORK_ID" | grep -q "OK"; then
        echo "✓ Network is connected"
    else
        echo "⚠ Network is not fully connected"
        exit 1
    fi
else
    echo "✗ Network $NETWORK_ID not joined"
    exit 1
fi

echo ""
echo "3. Peers:"
zerotier-cli listpeers | head -5

if [ -n "$TARGET_IP" ]; then
    echo ""
    echo "4. Connectivity Test to $TARGET_IP:"
    if ping -c 3 -W 2 "$TARGET_IP" &> /dev/null; then
        echo "✓ Can reach $TARGET_IP"
    else
        echo "✗ Cannot reach $TARGET_IP"
        exit 1
    fi
fi

echo ""
echo "=== Health Check Complete ==="
