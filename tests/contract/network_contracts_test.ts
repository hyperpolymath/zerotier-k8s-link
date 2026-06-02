// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
//
// Contract tests for network configuration invariants

import { assertEquals, assertStringIncludes } from "https://deno.land/std@0.208.0/assert/mod.ts";

Deno.test("contract: INVARIANT — Firewall must have default deny rule for input", async () => {
  const content = await Deno.readTextFile("configs/firewall.ncl");
  assertStringIncludes(content, `input_policy = "DROP"`);
});

Deno.test("contract: INVARIANT — Firewall must have default deny rule for forward", async () => {
  const content = await Deno.readTextFile("configs/firewall.ncl");
  assertStringIncludes(content, `forward_policy = "DROP"`);
});

Deno.test("contract: INVARIANT — ZeroTier network config uses private IP ranges only", async () => {
  const content = await Deno.readTextFile("configs/network.ncl");

  // Extract IP ranges and verify they're private (10.x.x.x, 172.16-31.x.x, 192.168.x.x)
  const ipMatches = content.match(/(\d+\.\d+\.\d+\.\d+)/g) || [];

  for (const ip of ipMatches) {
    const octets = ip.split(".").map(Number);
    // Check if IP is in private ranges
    const isPrivate10 = octets[0] === 10;
    const isPrivate172 = octets[0] === 172 && octets[1] >= 16 && octets[1] <= 31;
    const isPrivate192 = octets[0] === 192 && octets[1] === 168;

    assertEquals(isPrivate10 || isPrivate172 || isPrivate192, true);
  }
});

Deno.test("contract: INVARIANT — Kubernetes Secret must not have real credentials", async () => {
  const content = await Deno.readTextFile("manifests/secret.yaml");

  // Should have placeholder values only
  const hasExampleValues = content.includes("EXAMPLE") || content.includes("CHANGEME");
  assertEquals(hasExampleValues, true);

  // Should not contain realistic API tokens or private keys
  // Real ZT tokens are typically alphanumeric strings of specific length
  const hasRealToken = /[a-zA-Z0-9]{20,}/.test(content) && !content.includes("EXAMPLE");
  assertEquals(hasRealToken, false);
});

Deno.test("contract: INVARIANT — NetworkPolicy must restrict ingress rules", async () => {
  const content = await Deno.readTextFile("manifests/networkpolicy.yaml");

  // Must have explicit ingress rules
  assertStringIncludes(content, "ingress:");
  assertEquals(content.includes("ingress: []") ? false : true, true);
});

Deno.test("contract: INVARIANT — NetworkPolicy must restrict egress rules", async () => {
  const content = await Deno.readTextFile("manifests/networkpolicy.yaml");

  // Must have explicit egress rules
  assertStringIncludes(content, "egress:");
  assertEquals(content.includes("egress: []") ? false : true, true);
});

Deno.test("contract: INVARIANT — DaemonSet namespace must match namespace.yaml", async () => {
  const daemonsetContent = await Deno.readTextFile("manifests/daemonset.yaml");
  const namespaceContent = await Deno.readTextFile("manifests/namespace.yaml");

  // Extract and compare namespaces
  const dsNsMatch = daemonsetContent.match(/namespace:\s*([a-z0-9-]+)/);
  const declaredNsMatch = namespaceContent.match(/metadata:\s*\n\s*name:\s*([a-z0-9-]+)/);

  if (dsNsMatch && declaredNsMatch) {
    assertEquals(dsNsMatch[1], declaredNsMatch[1]);
  }
});

Deno.test("contract: INVARIANT — All ABI files must have module declarations", async () => {
  const abiFiles = ["src/abi/Layout.idr", "src/abi/Types.idr", "src/abi/Foreign.idr"];

  for (const file of abiFiles) {
    const content = await Deno.readTextFile(file);
    assertEquals(content.includes("module"), true);
  }
});

Deno.test("contract: INVARIANT — Network config must define both IPv4 and IPv6", async () => {
  const content = await Deno.readTextFile("configs/network.ncl");

  // Must have IPv4 pool
  assertStringIncludes(content, "ipv4_assignment_pool");
  // Must have IPv6 pool
  assertStringIncludes(content, "ipv6_assignment_pool");
});

Deno.test("contract: INVARIANT — Routes must reference valid destinations", async () => {
  const content = await Deno.readTextFile("configs/routes.ncl");

  // Should have at least one route with CIDR notation
  const hasCidr = /(?:destination|target)\s*=\s*"[^"]+\/\d+"/.test(content);
  assertEquals(hasCidr, true);
});

Deno.test("contract: INVARIANT — Firewall must have zerotier zone definition", async () => {
  const content = await Deno.readTextFile("configs/firewall.ncl");

  // Must define zerotier zone
  assertStringIncludes(content, "zerotier");
});

Deno.test("contract: INVARIANT — DaemonSet must request privileged capabilities", async () => {
  const content = await Deno.readTextFile("manifests/daemonset.yaml");

  // Network overlay requires NET_ADMIN capability
  assertStringIncludes(content, "NET_ADMIN");
});

Deno.test("contract: INVARIANT — DaemonSet must use hostNetwork=true", async () => {
  const content = await Deno.readTextFile("manifests/daemonset.yaml");

  // Network overlay requires direct host network access
  assertStringIncludes(content, "hostNetwork: true");
});

Deno.test("contract: INVARIANT — ConfigMap must be named zerotier-config", async () => {
  const content = await Deno.readTextFile("manifests/configmap.yaml");

  // Name validation
  assertStringIncludes(content, "zerotier-config");
});

Deno.test("contract: INVARIANT — Secret must be named zerotier-credentials", async () => {
  const content = await Deno.readTextFile("manifests/secret.yaml");

  // Name validation
  assertStringIncludes(content, "zerotier-credentials");
});

Deno.test("contract: INVARIANT — Network config must not allow default route via ZT", async () => {
  const content = await Deno.readTextFile("configs/network.ncl");

  // Should disable default route capability (security measure)
  assertStringIncludes(content, "allow_default_route = false");
});

Deno.test("contract: INVARIANT — Firewall control plane rule must use port 9993", async () => {
  const content = await Deno.readTextFile("configs/firewall.ncl");

  // ZeroTier control plane is always port 9993
  assertStringIncludes(content, "9993");
});

Deno.test("contract: INVARIANT — All config files must have SPDX headers", async () => {
  const files = ["configs/network.ncl", "configs/firewall.ncl", "configs/routes.ncl"];

  for (const file of files) {
    const content = await Deno.readTextFile(file);
    assertStringIncludes(content, "SPDX-License-Identifier");
  }
});

Deno.test("contract: INVARIANT — Layout.idr must import Types module", async () => {
  const content = await Deno.readTextFile("src/abi/Layout.idr");
  assertStringIncludes(content, "import ZEROTIER_K8S_LINK.ABI.Types");
});
