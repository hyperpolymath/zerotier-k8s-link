#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# SPDX-FileCopyrightText: 2025 Hyperpolymath
#
# Join a ZeroTier network from the command line

# SAFETY: Enable strict mode
# -e: Exit immediately if a command exits with a non-zero status.
# -u: Treat unset variables as an error.
# -o pipefail: Return value of a pipeline is the status of the last command to exit with a non-zero status.
set -euo pipefail

# The Network ID to join (passed as first argument)
NETWORK_ID="${1:-}"

if [ -z "$NETWORK_ID" ]; then
    echo "Usage: $0 <network-id>"
    echo "Example: $0 a0cbf4b62a123456"
    exit 1
fi

echo "Joining ZeroTier network: $NETWORK_ID"

# Dependency Check: zerotier-cli
# Ensure the CLI tool is available in the PATH.
if ! command -v zerotier-cli &> /dev/null; then
    echo "Error: zerotier-cli not found. Is ZeroTier installed?"
    exit 1
fi

# Service Health Check
# Ensure the ZeroTier One service (daemon) is running and responsive.
if ! zerotier-cli info &> /dev/null; then
    echo "Error: ZeroTier service is not running"
    echo "Start it with: sudo systemctl start zerotier-one"
    exit 1
fi

# Action: Join Network
# This sends a join request to the network controller.
zerotier-cli join "$NETWORK_ID"

echo "Join request sent. Waiting for authorization..."
echo ""
echo "Next steps:"
echo "1. Authorize this node in ZeroTier Central: https://my.zerotier.com/network/$NETWORK_ID"
echo "2. Or use the API: ./authorize-nodes.sh"
echo "3. Check status: zerotier-cli listnetworks"
