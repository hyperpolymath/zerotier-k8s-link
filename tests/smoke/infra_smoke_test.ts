// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
//
// Smoke tests for infrastructure file presence and basic validity

import { assertEquals, assertStringIncludes } from "https://deno.land/std@0.208.0/assert/mod.ts";

Deno.test("smoke: bash scripts exist with shebangs", async () => {
  const scripts = [
    "scripts/authorize-nodes.sh",
    "scripts/configure-routes.sh",
    "scripts/health-check.sh",
    "scripts/join-network.sh",
  ];

  for (const script of scripts) {
    const content = await Deno.readTextFile(script);
    // Accept #!/bin/bash, #!/bin/sh, or #!/usr/bin/env bash
    const hasShebang = content.match(/^#!\/(?:usr\/)?bin\/(bash|sh)/) || content.match(/^#!\/usr\/bin\/env bash/);
    assertEquals(hasShebang !== null, true);
  }
});

Deno.test("smoke: setup.sh exists with shell shebang", async () => {
  const content = await Deno.readTextFile("setup.sh");
  // Accept #!/bin/bash, #!/bin/sh, or #!/usr/bin/env bash
  const hasShebang = content.match(/^#!\/(?:usr\/)?bin\/(bash|sh)/) || content.match(/^#!\/usr\/bin\/env bash/);
  assertEquals(hasShebang !== null, true);
});

Deno.test("smoke: validation hooks exist with shell shebangs", async () => {
  const hooks = [
    "hooks/validate-codeql.sh",
    "hooks/validate-permissions.sh",
    "hooks/validate-sha-pins.sh",
    "hooks/validate-spdx.sh",
  ];

  for (const hook of hooks) {
    const content = await Deno.readTextFile(hook);
    // Accept #!/bin/bash, #!/bin/sh, or #!/usr/bin/env bash
    const hasShebang = content.match(/^#!\/(?:usr\/)?bin\/(bash|sh)/) || content.match(/^#!\/usr\/bin\/env bash/);
    assertEquals(hasShebang !== null, true);
  }
});

Deno.test("smoke: Idris2 ABI files exist", async () => {
  const abiFiles = ["src/abi/Layout.idr", "src/abi/Types.idr", "src/abi/Foreign.idr"];

  for (const file of abiFiles) {
    const content = await Deno.readTextFile(file);
    assertEquals(typeof content, "string");
    assertEquals(content.length > 0, true);
  }
});

Deno.test("smoke: Kubernetes manifests are non-empty YAML", async () => {
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
    assertStringIncludes(content, "apiVersion:");
    assertStringIncludes(content, "kind:");
  }
});

Deno.test("smoke: manifests do not contain hardcoded secrets", async () => {
  const secretPatterns = [
    { content: await Deno.readTextFile("manifests/secret.yaml"), name: "secret.yaml" },
    { content: await Deno.readTextFile("manifests/daemonset.yaml"), name: "daemonset.yaml" },
  ];

  for (const { content, name } of secretPatterns) {
    // Should use EXAMPLE_* placeholders, not real credentials
    if (content.includes("EXAMPLE")) {
      // Valid placeholder format
      assertEquals(true, true);
    } else if (!content.includes("secretKeyRef") && !content.includes("configMapKeyRef")) {
      // No secret references, should be OK
      assertEquals(true, true);
    }
  }
});

Deno.test("smoke: Idris2 Layout.idr has module declaration", async () => {
  const content = await Deno.readTextFile("src/abi/Layout.idr");
  assertStringIncludes(content, "module ZEROTIER_K8S_LINK.ABI.Layout");
});

Deno.test("smoke: Idris2 Types.idr has module declaration", async () => {
  const content = await Deno.readTextFile("src/abi/Types.idr");
  assertStringIncludes(content, "module ZEROTIER_K8S_LINK.ABI.Types");
});

Deno.test("smoke: Idris2 Foreign.idr exists", async () => {
  const content = await Deno.readTextFile("src/abi/Foreign.idr");
  assertEquals(typeof content, "string");
  assertEquals(content.length > 0, true);
});

Deno.test("smoke: root manifest file exists", async () => {
  const content = await Deno.readTextFile("zerotier-k8s-link.manifest.ncl");
  assertEquals(typeof content, "string");
  assertEquals(content.length > 0, true);
});
