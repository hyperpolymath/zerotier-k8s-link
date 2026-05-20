-- SPDX-License-Identifier: PMPL-1.0-or-later
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
--
-- Port of tests/smoke/infra_smoke_test.ts to Idris2, estate-rollout 9/11.
-- 9 of 9 smoke tests ported. All assertions are file-read + substring/prefix
-- checks, so the Idris2 port is structurally identical to the Deno original.

module SmokeInfraTest

import Test.Spec
import Data.String
import System.File

%default covering

readFileToString : String -> IO String
readFileToString path = do
  Right contents <- readFile path
    | Left _ => pure ""
  pure contents

-- Accept any of the three documented shebangs.
hasBashShebang : String -> Bool
hasBashShebang content =
     isPrefixOf "#!/bin/bash"          content
  || isPrefixOf "#!/bin/sh"            content
  || isPrefixOf "#!/usr/bin/env bash"  content
  || isPrefixOf "#!/usr/bin/env sh"    content

public export
allSuites : List TestCase
allSuites =
  [ test "Smoke: bash scripts exist with shebangs" $ do
      a <- readFileToString "scripts/authorize-nodes.sh"
      b <- readFileToString "scripts/configure-routes.sh"
      c <- readFileToString "scripts/health-check.sh"
      d <- readFileToString "scripts/join-network.sh"
      allPass
        [ assertTrue "authorize-nodes.sh"  (hasBashShebang a)
        , assertTrue "configure-routes.sh" (hasBashShebang b)
        , assertTrue "health-check.sh"     (hasBashShebang c)
        , assertTrue "join-network.sh"     (hasBashShebang d)
        ]

  , test "Smoke: setup.sh exists with shell shebang" $ do
      content <- readFileToString "setup.sh"
      assertTrue "setup.sh shebang" (hasBashShebang content)

  , test "Smoke: validation hooks exist with shell shebangs" $ do
      a <- readFileToString "hooks/validate-codeql.sh"
      b <- readFileToString "hooks/validate-permissions.sh"
      c <- readFileToString "hooks/validate-sha-pins.sh"
      d <- readFileToString "hooks/validate-spdx.sh"
      allPass
        [ assertTrue "validate-codeql.sh"      (hasBashShebang a)
        , assertTrue "validate-permissions.sh" (hasBashShebang b)
        , assertTrue "validate-sha-pins.sh"    (hasBashShebang c)
        , assertTrue "validate-spdx.sh"        (hasBashShebang d)
        ]

  , test "Smoke: Idris2 ABI files exist and are non-empty" $ do
      a <- readFileToString "src/abi/Layout.idr"
      b <- readFileToString "src/abi/Types.idr"
      c <- readFileToString "src/abi/Foreign.idr"
      allPass
        [ assertTrue "Layout.idr non-empty"  (length a > 0)
        , assertTrue "Types.idr non-empty"   (length b > 0)
        , assertTrue "Foreign.idr non-empty" (length c > 0)
        ]

  , test "Smoke: Kubernetes manifests are non-empty YAML" $ do
      a <- readFileToString "manifests/configmap.yaml"
      b <- readFileToString "manifests/daemonset.yaml"
      c <- readFileToString "manifests/namespace.yaml"
      d <- readFileToString "manifests/networkpolicy.yaml"
      e <- readFileToString "manifests/secret.yaml"
      f <- readFileToString "manifests/servicemonitor.yaml"
      let hasYamlMeta : String -> Bool
          hasYamlMeta = \s => isInfixOf "apiVersion:" s && isInfixOf "kind:" s
      allPass
        [ assertTrue "configmap.yaml"      (hasYamlMeta a)
        , assertTrue "daemonset.yaml"      (hasYamlMeta b)
        , assertTrue "namespace.yaml"      (hasYamlMeta c)
        , assertTrue "networkpolicy.yaml"  (hasYamlMeta d)
        , assertTrue "secret.yaml"         (hasYamlMeta e)
        , assertTrue "servicemonitor.yaml" (hasYamlMeta f)
        ]

  , test "Smoke: manifests do not contain hardcoded secrets" $ do
      a <- readFileToString "manifests/secret.yaml"
      b <- readFileToString "manifests/daemonset.yaml"
      -- Each file is either using EXAMPLE placeholders or *KeyRef references.
      let ok : String -> Bool
          ok = \s => isInfixOf "EXAMPLE" s
                  || isInfixOf "secretKeyRef" s
                  || isInfixOf "configMapKeyRef" s
      allPass
        [ assertTrue "secret.yaml uses placeholders or KeyRef"    (ok a)
        , assertTrue "daemonset.yaml uses placeholders or KeyRef" (ok b)
        ]

  , test "Smoke: Idris2 Layout.idr has module declaration" $ do
      content <- readFileToString "src/abi/Layout.idr"
      assertTrue "module ZEROTIER_K8S_LINK.ABI.Layout"
        (isInfixOf "module ZEROTIER_K8S_LINK.ABI.Layout" content)

  , test "Smoke: Idris2 Types.idr has module declaration" $ do
      content <- readFileToString "src/abi/Types.idr"
      assertTrue "module ZEROTIER_K8S_LINK.ABI.Types"
        (isInfixOf "module ZEROTIER_K8S_LINK.ABI.Types" content)

  , test "Smoke: Idris2 Foreign.idr is non-empty" $ do
      content <- readFileToString "src/abi/Foreign.idr"
      assertTrue "Foreign.idr non-empty" (length content > 0)

  , test "Smoke: root manifest file exists" $ do
      content <- readFileToString "zerotier-k8s-link.manifest.ncl"
      assertTrue "manifest non-empty" (length content > 0)
  ]
