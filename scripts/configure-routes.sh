#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# SPDX-FileCopyrightText: 2025 Hyperpolymath
#
# Configure routing for ZeroTier overlay network

set -euo pipefail

NETWORK_ID="${1:-}"

if [ -z "$NETWORK_ID" ]; then
    echo "Usage: $0 <network-id>"
    exit 1
fi

echo "Configuring routes for ZeroTier network: $NETWORK_ID"

# Get ZeroTier interface name
ZT_IFACE=$(zerotier-cli listnetworks | grep "$NETWORK_ID" | awk '{print $8}' | head -1)

if [ -z "$ZT_IFACE" ]; then
    echo "Error: Network $NETWORK_ID not found or not joined"
    echo "Available networks:"
    zerotier-cli listnetworks
    exit 1
fi

echo "ZeroTier interface: $ZT_IFACE"

# Get assigned IP addresses
ZT_IP4=$(ip -4 addr show dev "$ZT_IFACE" | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
ZT_IP6=$(ip -6 addr show dev "$ZT_IFACE" | grep -oP '(?<=inet6\s)[0-9a-f:]+' | grep -v '^fe80' | head -1)

echo "IPv4: $ZT_IP4"
echo "IPv6: $ZT_IP6"

# Configure routes (example - customize based on your network)
# Add route for IPFS overlay if needed
# ip route add 10.147.17.0/24 dev "$ZT_IFACE"

# Enable IP forwarding if this node acts as a router
# echo 1 > /proc/sys/net/ipv4/ip_forward
# echo 1 > /proc/sys/net/ipv6/conf/all/forwarding

echo "Route configuration complete"
echo ""
echo "Current routes via ZeroTier:"
ip route show dev "$ZT_IFACE"
