# SPDX-License-Identifier: PMPL-1.0-or-later
# Route configuration for ZeroTier overlay

{
  # Static routes to be configured on nodes
  static_routes = [
    {
      destination = "10.147.17.0/24",
      gateway = null,  # Route via ZeroTier interface
      metric = 100,
      description = "ZeroTier managed range",
    },
  ],
  
  # Routes to be pushed to ZeroTier network configuration
  network_routes = [
    {
      target = "10.147.17.0/24",
      via = null,
    },
    {
      target = "fd00:feed:face::/48",
      via = null,
    },
  ],
  
  # Policy-based routing rules
  routing_policy = {
    enable_forwarding = false,
    enable_masquerade = false,
    tables = [],
  },
}
