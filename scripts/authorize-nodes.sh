#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# SPDX-FileCopyrightText: 2025 Hyperpolymath
#
# Authorize ZeroTier nodes via API

set -euo pipefail

NETWORK_ID="${ZEROTIER_NETWORK_ID:-}"
API_TOKEN="${ZEROTIER_API_TOKEN:-}"

if [ -z "$NETWORK_ID" ] || [ -z "$API_TOKEN" ]; then
    echo "Error: Missing required environment variables"
    echo "Set: ZEROTIER_NETWORK_ID and ZEROTIER_API_TOKEN"
    exit 1
fi

echo "Fetching unauthorized nodes for network $NETWORK_ID..."

# Get all network members
MEMBERS=$(curl -s -H "Authorization: bearer $API_TOKEN" \
    "https://my.zerotier.com/api/network/$NETWORK_ID/member")

# Parse and authorize unauthorized nodes
echo "$MEMBERS" | jq -r '.[] | select(.config.authorized == false) | .nodeId' | while read -r NODE_ID; do
    echo "Authorizing node: $NODE_ID"
    
    curl -s -X POST \
        -H "Authorization: bearer $API_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"config":{"authorized":true}}' \
        "https://my.zerotier.com/api/network/$NETWORK_ID/member/$NODE_ID" \
        > /dev/null
    
    echo "✓ Node $NODE_ID authorized"
done

echo ""
echo "Authorization complete. Check status:"
echo "kubectl -n zerotier-system get pods"
