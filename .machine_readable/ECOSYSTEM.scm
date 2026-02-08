;; SPDX-License-Identifier: PMPL-1.0-or-later
(ecosystem (metadata (version "0.2.0") (last-updated "2026-02-08"))
  (project (name "zerotier-k8s-link") (purpose "ZeroTier overlay network for Kubernetes nodes") (role overlay-mesh))
  (flatracoon-integration
    (parent "flatracoon/netstack")
    (layer overlay)
    (depended-on-by ("ipfs-overlay"))
    (depends-on ())))
