// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
//
// Benchmark tests for configuration read performance

Deno.bench("bench: read all nickel configs sequentially", async () => {
  await Deno.readTextFile("configs/network.ncl");
  await Deno.readTextFile("configs/firewall.ncl");
  await Deno.readTextFile("configs/routes.ncl");
});

Deno.bench("bench: read all k8s manifests sequentially", async () => {
  const files = [
    "manifests/configmap.yaml",
    "manifests/daemonset.yaml",
    "manifests/namespace.yaml",
    "manifests/networkpolicy.yaml",
    "manifests/secret.yaml",
    "manifests/servicemonitor.yaml",
  ];

  for (const file of files) {
    await Deno.readTextFile(file);
  }
});

Deno.bench("bench: read network config only", async () => {
  await Deno.readTextFile("configs/network.ncl");
});

Deno.bench("bench: read firewall config only", async () => {
  await Deno.readTextFile("configs/firewall.ncl");
});

Deno.bench("bench: read routes config only", async () => {
  await Deno.readTextFile("configs/routes.ncl");
});

Deno.bench("bench: read daemonset manifest only", async () => {
  await Deno.readTextFile("manifests/daemonset.yaml");
});

Deno.bench("bench: read networkpolicy manifest only", async () => {
  await Deno.readTextFile("manifests/networkpolicy.yaml");
});

Deno.bench("bench: read secret manifest only", async () => {
  await Deno.readTextFile("manifests/secret.yaml");
});

Deno.bench("bench: read all ABI files", async () => {
  await Deno.readTextFile("src/abi/Layout.idr");
  await Deno.readTextFile("src/abi/Types.idr");
  await Deno.readTextFile("src/abi/Foreign.idr");
});

Deno.bench("bench: parse nickel config string content", async () => {
  const content = await Deno.readTextFile("configs/network.ncl");
  // Basic parsing simulation: count lines
  content.split("\n").length;
});

Deno.bench("bench: parse kubernetes manifest string content", async () => {
  const content = await Deno.readTextFile("manifests/daemonset.yaml");
  // Basic parsing simulation: count lines
  content.split("\n").length;
});
