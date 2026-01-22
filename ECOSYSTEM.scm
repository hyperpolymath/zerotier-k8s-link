;; SPDX-License-Identifier: PMPL-1.0
;; ECOSYSTEM.scm - Project ecosystem positioning

(ecosystem
  ((version . "0.1.0")
   (name . "zerotier-k8s-link")
   (type . "infrastructure-component")
   (purpose . "Join Kubernetes nodes to ZeroTier network for encrypted overlay routing")
   (position-in-ecosystem . "Network overlay layer in FlatRacoon stack")
   (related-projects
     ((flatracoon-netstack . "parent-stack")
      (twingate-helm-deploy . "sibling-component")
      (ipfs-overlay . "potential-consumer")
      (poly-observability-mcp . "monitoring-integration")
      (rhodium-standard . "follows-standard")))
   (what-this-is . (
     "K8s DaemonSet deploying ZeroTier agents to cluster nodes"
     "Automated network joining and node authorization via API"
     "Declarative route and firewall configuration with Nickel"
     "Integration point for IPFS private networking"))
   (what-this-is-not . (
     "Not a VPN client (it's a mesh overlay)"
     "Not application-level (operates at node/network layer)"
     "Not a ZeroTier controller (uses ZeroTier Central)"
     "Not standalone (part of FlatRacoon netstack)"))))
