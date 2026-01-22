#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later
# SPDX-FileCopyrightText: 2025 Hyperpolymath
#
# Join a ZeroTier network from the command line

set -euo pipefail

NETWORK_ID="${1:-}"

if [ -z "$NETWORK_ID" ]; then
    echo "Usage: $0 <network-id>"
    echo "Example: $0 a0cbf4b62a123456"
    exit 1
fi

echo "Joining ZeroTier network: $NETWORK_ID"

# Check if zerotier-cli is available
if ! command -v zerotier-cli &> /dev/null; then
    echo "Error: zerotier-cli not found. Is ZeroTier installed?"
    exit 1
fi

# Check if ZeroTier service is running
if ! zerotier-cli info &> /dev/null; then
    echo "Error: ZeroTier service is not running"
    echo "Start it with: sudo systemctl start zerotier-one"
    exit 1
fi

# Join the network
zerotier-cli join "$NETWORK_ID"

echo "Join request sent. Waiting for authorization..."
echo ""
echo "Next steps:"
echo "1. Authorize this node in ZeroTier Central: https://my.zerotier.com/network/$NETWORK_ID"
echo "2. Or use the API: ./authorize-nodes.sh"
echo "3. Check status: zerotier-cli listnetworks"
