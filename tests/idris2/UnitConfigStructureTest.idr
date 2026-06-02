-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
--
-- Port of tests/unit/config_structure_test.ts to Idris2, estate-rollout port 9/11.
-- 13 of 13 Deno.test cases ported. All assertions are file-read + substring
-- matching, so the Idris2 port is structurally identical to the Deno original.

module UnitConfigStructureTest

import Test.Spec
import Data.String
import System.File

%default covering

readFileToString : String -> IO String
readFileToString path = do
  Right contents <- readFile path
    | Left _ => pure ""
  pure contents

fileExists : String -> IO Bool
fileExists path = do
  Right _ <- readFile path
    | Left _ => pure False
  pure True

nonEmptyFile : String -> IO Bool
nonEmptyFile path = do
  s <- readFileToString path
  pure (length s > 0)

public export
allSuites : List TestCase
allSuites =
  [ test "Unit: Nickel config files exist" $ do
      a <- nonEmptyFile "configs/network.ncl"
      b <- nonEmptyFile "configs/firewall.ncl"
      c <- nonEmptyFile "configs/routes.ncl"
      assertTrue "all 3 Nickel config files non-empty" (a && b && c)

  , test "Unit: Kubernetes manifest files exist" $ do
      a <- nonEmptyFile "manifests/configmap.yaml"
      b <- nonEmptyFile "manifests/daemonset.yaml"
      c <- nonEmptyFile "manifests/namespace.yaml"
      d <- nonEmptyFile "manifests/networkpolicy.yaml"
      e <- nonEmptyFile "manifests/secret.yaml"
      f <- nonEmptyFile "manifests/servicemonitor.yaml"
      assertTrue "all 6 K8s manifest files non-empty"
        (a && b && c && d && e && f)

  , test "Unit: Nickel configs have SPDX headers" $ do
      let spdx = "SPDX-License-Identifier: MPL-2.0"
      a <- readFileToString "configs/network.ncl"
      b <- readFileToString "configs/firewall.ncl"
      c <- readFileToString "configs/routes.ncl"
      allPass
        [ assertTrue "network.ncl SPDX"  (isInfixOf spdx a)
        , assertTrue "firewall.ncl SPDX" (isInfixOf spdx b)
        , assertTrue "routes.ncl SPDX"   (isInfixOf spdx c)
        ]

  , test "Unit: network.ncl contains ZeroTier config" $ do
      content <- readFileToString "configs/network.ncl"
      allPass
        [ assertTrue "network_id"           (isInfixOf "network_id" content)
        , assertTrue "api_token"            (isInfixOf "api_token" content)
        , assertTrue "ipv4_assignment_pool" (isInfixOf "ipv4_assignment_pool" content)
        , assertTrue "ipv6_assignment_pool" (isInfixOf "ipv6_assignment_pool" content)
        , assertTrue "routes"               (isInfixOf "routes" content)
        ]

  , test "Unit: firewall.ncl contains firewall rules" $ do
      content <- readFileToString "configs/firewall.ncl"
      allPass
        [ assertTrue "rules"             (isInfixOf "rules" content)
        , assertTrue "zerotier_control"  (isInfixOf "zerotier_control" content)
        , assertTrue "established"       (isInfixOf "established" content)
        , assertTrue "input_policy"      (isInfixOf "input_policy" content)
        , assertTrue "forward_policy"    (isInfixOf "forward_policy" content)
        , assertTrue "output_policy"     (isInfixOf "output_policy" content)
        ]

  , test "Unit: firewall.ncl has deny-by-default policy" $ do
      content <- readFileToString "configs/firewall.ncl"
      allPass
        [ assertTrue "input_policy = DROP"   (isInfixOf "input_policy = \"DROP\"" content)
        , assertTrue "forward_policy = DROP" (isInfixOf "forward_policy = \"DROP\"" content)
        ]

  , test "Unit: routes.ncl contains route definitions" $ do
      content <- readFileToString "configs/routes.ncl"
      allPass
        [ assertTrue "static_routes"      (isInfixOf "static_routes" content)
        , assertTrue "network_routes"     (isInfixOf "network_routes" content)
        , assertTrue "10.147.17.0/24"     (isInfixOf "10.147.17.0/24" content)
        , assertTrue "fd00:feed:face::/48" (isInfixOf "fd00:feed:face::/48" content)
        ]

  , test "Unit: daemonset.yaml references zerotier-system namespace" $ do
      content <- readFileToString "manifests/daemonset.yaml"
      allPass
        [ assertTrue "namespace: zerotier-system" (isInfixOf "namespace: zerotier-system" content)
        , assertTrue "kind: DaemonSet"            (isInfixOf "kind: DaemonSet" content)
        , assertTrue "app.kubernetes.io/name: zerotier"
            (isInfixOf "app.kubernetes.io/name: zerotier" content)
        ]

  , test "Unit: networkpolicy.yaml has ingress and egress rules" $ do
      content <- readFileToString "manifests/networkpolicy.yaml"
      allPass
        [ assertTrue "kind: NetworkPolicy" (isInfixOf "kind: NetworkPolicy" content)
        , assertTrue "ingress:"            (isInfixOf "ingress:" content)
        , assertTrue "egress:"             (isInfixOf "egress:" content)
        , assertTrue "policyTypes:"        (isInfixOf "policyTypes:" content)
        , assertTrue "- Ingress"           (isInfixOf "- Ingress" content)
        , assertTrue "- Egress"            (isInfixOf "- Egress" content)
        ]

  , test "Unit: secret.yaml has placeholder values only" $ do
      content <- readFileToString "manifests/secret.yaml"
      allPass
        [ assertTrue "kind: Secret"                       (isInfixOf "kind: Secret" content)
        , assertTrue "network-id: \"EXAMPLE_NETWORK_ID\"" (isInfixOf "network-id: \"EXAMPLE_NETWORK_ID\"" content)
        , assertTrue "api-token: \"EXAMPLE_API_TOKEN\""   (isInfixOf "api-token: \"EXAMPLE_API_TOKEN\"" content)
        ]

  , test "Unit: namespace.yaml declares zerotier-system" $ do
      content <- readFileToString "manifests/namespace.yaml"
      allPass
        [ assertTrue "kind: Namespace" (isInfixOf "kind: Namespace" content)
        , assertTrue "zerotier-system" (isInfixOf "zerotier-system" content)
        ]

  , test "Unit: configmap.yaml is a ConfigMap" $ do
      content <- readFileToString "manifests/configmap.yaml"
      assertTrue "kind: ConfigMap" (isInfixOf "kind: ConfigMap" content)

  , test "Unit: servicemonitor.yaml exists and is non-empty" $ do
      ok <- nonEmptyFile "manifests/servicemonitor.yaml"
      assertTrue "servicemonitor.yaml non-empty" ok
  ]
