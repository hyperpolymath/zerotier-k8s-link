# SPDX-License-Identifier: PMPL-1.0-or-later
# zerotier-k8s-link module manifest for FlatRacoon orchestrator

{
  name = "zerotier-k8s-link",
  version = "0.1.0",
  layer = 'overlay,
  description = "ZeroTier mesh overlay network as Kubernetes DaemonSet for encrypted peer-to-peer connectivity",
  repo = "github.com/hyperpolymath/zerotier-k8s-link",
  requires = ["kubernetes"],
  provides = ["encrypted-mesh", "nat-traversal", "private-routing"],
  config_schema = "configs/schema.ncl",
  health_endpoint = "/health",
  metrics_endpoint = "/metrics",
  deployment_mode = "daemonset",
  namespace = "zerotier-system",
}
