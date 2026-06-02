# SPDX-License-Identifier: MPL-2.0
# zerotier-k8s-link module manifest for FlatRacoon orchestrator
#
# This Nickel configuration file defines the ZeroTier mesh networking module.
# It provides a secure, encrypted overlay network for Kubernetes clusters, enabling
# peer-to-peer communication across different physical locations or cloud providers.

{
  # The unique identifier for this module.
  name = "zerotier-k8s-link",

  # Semantic versioning for the module implementation.
  version = "0.1.0",

  # The architectural layer this module belongs to.
  # 'overlay' indicates this component operates "on top" of the physical network,
  # creating a virtualized addressing space.
  layer = 'overlay,

  # Human-readable description.
  description = "ZeroTier mesh overlay network as Kubernetes DaemonSet for encrypted peer-to-peer connectivity",

  # Source repository.
  repo = "github.com/hyperpolymath/zerotier-k8s-link",

  # Dependencies required for this module to run.
  # "kubernetes" is required as this is deployed as a DaemonSet.
  requires = ["kubernetes"],

  # Capabilities provided by this module.
  # - "encrypted-mesh": Full mesh encryption (ChaCha20-Poly1305).
  # - "nat-traversal": Automatic UDP hole punching.
  # - "private-routing": Secure routing between nodes without exposing ports.
  provides = ["encrypted-mesh", "nat-traversal", "private-routing"],

  # JSON Schema for validation.
  config_schema = "configs/schema.ncl",

  # Observability endpoints.
  health_endpoint = "/health",
  metrics_endpoint = "/metrics",

  # Deployment strategy.
  # "daemonset" ensures one instance runs on every node in the cluster,
  # guaranteeing full mesh connectivity for all workloads.
  deployment_mode = "daemonset",

  # Target namespace.
  namespace = "zerotier-system",
}
