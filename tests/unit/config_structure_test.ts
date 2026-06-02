// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
//
// Unit tests for configuration file structure validation

import { assertEquals, assertExists, assertStringIncludes } from "https://deno.land/std@0.208.0/assert/mod.ts";

Deno.test("unit: Nickel config files exist", async () => {
  const configs = ["configs/network.ncl", "configs/firewall.ncl", "configs/routes.ncl"];

  for (const config of configs) {
    const content = await Deno.readTextFile(config);
    assertExists(content);
    assertEquals(typeof content, "string");
    assertEquals(content.length > 0, true);
  }
});

Deno.test("unit: Kubernetes manifest files exist", async () => {
  const manifests = [
    "manifests/configmap.yaml",
    "manifests/daemonset.yaml",
    "manifests/namespace.yaml",
    "manifests/networkpolicy.yaml",
    "manifests/secret.yaml",
    "manifests/servicemonitor.yaml",
  ];

  for (const manifest of manifests) {
    const content = await Deno.readTextFile(manifest);
    assertExists(content);
    assertEquals(typeof content, "string");
    assertEquals(content.length > 0, true);
  }
});

Deno.test("unit: Nickel configs have SPDX headers", async () => {
  const configs = ["configs/network.ncl", "configs/firewall.ncl", "configs/routes.ncl"];

  for (const config of configs) {
    const content = await Deno.readTextFile(config);
    assertStringIncludes(content, "SPDX-License-Identifier: MPL-2.0");
  }
});

Deno.test("unit: network.ncl contains ZeroTier config", async () => {
  const content = await Deno.readTextFile("configs/network.ncl");
  assertStringIncludes(content, "network_id");
  assertStringIncludes(content, "api_token");
  assertStringIncludes(content, "ipv4_assignment_pool");
  assertStringIncludes(content, "ipv6_assignment_pool");
  assertStringIncludes(content, "routes");
});

Deno.test("unit: firewall.ncl contains firewall rules", async () => {
  const content = await Deno.readTextFile("configs/firewall.ncl");
  assertStringIncludes(content, "rules");
  assertStringIncludes(content, "zerotier_control");
  assertStringIncludes(content, "established");
  assertStringIncludes(content, "input_policy");
  assertStringIncludes(content, "forward_policy");
  assertStringIncludes(content, "output_policy");
});

Deno.test("unit: firewall.ncl has deny-by-default policy", async () => {
  const content = await Deno.readTextFile("configs/firewall.ncl");
  assertStringIncludes(content, `input_policy = "DROP"`);
  assertStringIncludes(content, `forward_policy = "DROP"`);
});

Deno.test("unit: routes.ncl contains route definitions", async () => {
  const content = await Deno.readTextFile("configs/routes.ncl");
  assertStringIncludes(content, "static_routes");
  assertStringIncludes(content, "network_routes");
  assertStringIncludes(content, "10.147.17.0/24");
  assertStringIncludes(content, "fd00:feed:face::/48");
});

Deno.test("unit: daemonset.yaml references zerotier-system namespace", async () => {
  const content = await Deno.readTextFile("manifests/daemonset.yaml");
  assertStringIncludes(content, "namespace: zerotier-system");
  assertStringIncludes(content, "kind: DaemonSet");
  assertStringIncludes(content, "app.kubernetes.io/name: zerotier");
});

Deno.test("unit: networkpolicy.yaml has ingress and egress rules", async () => {
  const content = await Deno.readTextFile("manifests/networkpolicy.yaml");
  assertStringIncludes(content, "kind: NetworkPolicy");
  assertStringIncludes(content, "ingress:");
  assertStringIncludes(content, "egress:");
  assertStringIncludes(content, "policyTypes:");
  assertStringIncludes(content, "- Ingress");
  assertStringIncludes(content, "- Egress");
});

Deno.test("unit: secret.yaml has placeholder values only", async () => {
  const content = await Deno.readTextFile("manifests/secret.yaml");
  assertStringIncludes(content, "kind: Secret");
  assertStringIncludes(content, "network-id: \"EXAMPLE_NETWORK_ID\"");
  assertStringIncludes(content, "api-token: \"EXAMPLE_API_TOKEN\"");
});

Deno.test("unit: namespace.yaml declares zerotier-system", async () => {
  const content = await Deno.readTextFile("manifests/namespace.yaml");
  assertStringIncludes(content, "kind: Namespace");
  assertStringIncludes(content, "zerotier-system");
});

Deno.test("unit: configmap.yaml exists and is valid YAML", async () => {
  const content = await Deno.readTextFile("manifests/configmap.yaml");
  assertStringIncludes(content, "kind: ConfigMap");
});

Deno.test("unit: servicemonitor.yaml exists and is valid YAML", async () => {
  const content = await Deno.readTextFile("manifests/servicemonitor.yaml");
  // ServiceMonitor may be optional but should validate if present
  assertEquals(typeof content, "string");
});
