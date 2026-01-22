# SPDX-License-Identifier: PMPL-1.0-or-later
# Firewall rules for ZeroTier overlay

{
  # iptables/nftables rules for ZeroTier traffic
  rules = {
    # Allow ZeroTier control plane
    zerotier_control = {
      protocol = "udp",
      port = 9993,
      action = "ACCEPT",
      direction = "bidirectional",
    },
    
    # Allow established connections
    established = {
      state = ["ESTABLISHED", "RELATED"],
      action = "ACCEPT",
    },
    
    # Default policies
    input_policy = "DROP",
    forward_policy = "DROP",
    output_policy = "ACCEPT",
  },
  
  # ZeroTier network-level rules
  network_rules = [
    {
      type = "ACTION_ACCEPT",
      not = false,
      or = false,
      etherType = null,
      ipProtocol = null,
      comment = "Allow all traffic within mesh",
    },
  ],
  
  # Per-node firewall zones
  zones = {
    zerotier = {
      interfaces = ["zt+"],
      allow_from = ["zerotier"],
      allow_to = ["zerotier", "wan"],
    },
  },
}
