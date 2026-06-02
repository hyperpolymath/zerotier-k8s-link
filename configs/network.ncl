# SPDX-License-Identifier: MPL-2.0
# Network configuration for ZeroTier overlay

{
  network_id | String
    | doc "ZeroTier network ID (16 characters)"
    | default = "CHANGEME_NETWORK_ID",
  
  network_name | String
    | doc "Human-readable network name"
    | default = "flatracoon-k8s-mesh",
  
  api_token | String
    | doc "ZeroTier Central API token"
    | default = "CHANGEME_API_TOKEN",
  
  ipv4_assignment_pool = {
    start = "10.147.17.1",
    end = "10.147.17.254",
  },
  
  ipv6_assignment_pool = {
    prefix = "fd00:feed:face::/48",
  },
  
  routes = [
    {
      target = "10.147.17.0/24",
      via = null,  # null means route via ZeroTier
    },
  ],
  
  rules = [
    {
      type = "ACTION_ACCEPT",
    },
  ],
  
  capabilities = {
    allow_default_route = false,
    allow_global_ips = false,
    allow_managed_ips = true,
    enable_broadcast = true,
  },
  
  dns = {
    domain = "zt.local",
    servers = [],
  },
}
