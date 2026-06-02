-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
--
-- Port of tests/e2e/network_e2e_test.ts to Idris2, estate-rollout 9/11.
-- 12 of 12 end-to-end pipeline tests ported. The "e2e" suite in the TS
-- original is itself purely file-read + substring-matching across multiple
-- artefacts (no live cluster traffic), so it ports cleanly as bucket-1.

module E2ENetworkTest

import Test.Spec
import Data.String
import System.File

%default covering

readFileToString : String -> IO String
readFileToString path = do
  Right contents <- readFile path
    | Left _ => pure ""
  pure contents

public export
allSuites : List TestCase
allSuites =
  [ test "E2E: full config pipeline - read all Nickel configs" $ do
      a <- readFileToString "configs/network.ncl"
      b <- readFileToString "configs/firewall.ncl"
      c <- readFileToString "configs/routes.ncl"
      allPass
        [ assertTrue "network.ncl non-empty"  (length a > 0)
        , assertTrue "firewall.ncl non-empty" (length b > 0)
        , assertTrue "routes.ncl non-empty"   (length c > 0)
        ]

  , test "E2E: K8s daemonset references correct namespace" $ do
      daemonset <- readFileToString "manifests/daemonset.yaml"
      ns        <- readFileToString "manifests/namespace.yaml"
      allPass
        [ assertTrue "daemonset namespace: zerotier-system"
            (isInfixOf "namespace: zerotier-system" daemonset)
        , assertTrue "namespace.yaml declares zerotier-system"
            (isInfixOf "zerotier-system" ns)
        ]

  , test "E2E: NetworkPolicy references zerotier app labels" $ do
      policy    <- readFileToString "manifests/networkpolicy.yaml"
      daemonset <- readFileToString "manifests/daemonset.yaml"
      let lbl = "app.kubernetes.io/name: zerotier"
      allPass
        [ assertTrue "networkpolicy.yaml has app label" (isInfixOf lbl policy)
        , assertTrue "daemonset.yaml has app label"    (isInfixOf lbl daemonset)
        ]

  , test "E2E: routes do not conflict with firewall deny rules" $ do
      routes   <- readFileToString "configs/routes.ncl"
      firewall <- readFileToString "configs/firewall.ncl"
      allPass
        [ assertTrue "firewall input_policy = DROP"
            (isInfixOf "input_policy = \"DROP\"" firewall)
        , assertTrue "firewall references ACTION_ACCEPT for ZT traffic"
            (isInfixOf "ACTION_ACCEPT" firewall)
        , assertTrue "routes has destination/target"
            (isInfixOf "destination =" routes || isInfixOf "target =" routes)
        ]

  , test "E2E: secret manifest does not contain real credentials" $ do
      content <- readFileToString "manifests/secret.yaml"
      let hasPlaceholder = isInfixOf "EXAMPLE" content || isInfixOf "CHANGEME" content
      let noKnownReal = not (isInfixOf "sk_live_" content)
                     && not (isInfixOf "api_key=" content)
      allPass
        [ assertTrue "has EXAMPLE/CHANGEME placeholder" hasPlaceholder
        , assertTrue "no Stripe/api_key= literal"       noKnownReal
        ]

  , test "E2E: network config IPv6 pool is valid format" $ do
      content <- readFileToString "configs/network.ncl"
      allPass
        [ assertTrue "prefix = \" present"        (isInfixOf "prefix = \"" content)
        , assertTrue "fd00:feed:face::/48 literal" (isInfixOf "fd00:feed:face::/48" content)
        ]

  , test "E2E: configmap provides auto-join configuration" $ do
      content <- readFileToString "manifests/configmap.yaml"
      allPass
        [ assertTrue "kind: ConfigMap" (isInfixOf "kind: ConfigMap" content)
        , assertTrue "data:"           (isInfixOf "data:" content)
        ]

  , test "E2E: daemonset includes health check configuration" $ do
      content <- readFileToString "manifests/daemonset.yaml"
      let probe = isInfixOf "livenessProbe:" content
               || isInfixOf "readinessProbe:" content
      assertTrue "liveness or readiness probe present" probe

  , test "E2E: all manifest references use existing configmap/secret" $ do
      daemonset <- readFileToString "manifests/daemonset.yaml"
      configmap <- readFileToString "manifests/configmap.yaml"
      secret    <- readFileToString "manifests/secret.yaml"
      allPass
        [ assertTrue "daemonset -> zerotier-config"      (isInfixOf "zerotier-config" daemonset)
        , assertTrue "daemonset -> zerotier-credentials" (isInfixOf "zerotier-credentials" daemonset)
        , assertTrue "configmap defines zerotier-config" (isInfixOf "zerotier-config" configmap)
        , assertTrue "secret defines zerotier-credentials" (isInfixOf "zerotier-credentials" secret)
        ]

  , test "E2E: firewall zones reference zerotier interface pattern" $ do
      content <- readFileToString "configs/firewall.ncl"
      allPass
        [ assertTrue "zerotier in firewall.ncl" (isInfixOf "zerotier" content)
        , assertTrue "zt+ interface in firewall.ncl" (isInfixOf "zt+" content)
        ]

  , test "E2E: routes match network config IP pools" $ do
      network <- readFileToString "configs/network.ncl"
      routes  <- readFileToString "configs/routes.ncl"
      allPass
        [ assertTrue "network has IPv4 pool start" (isInfixOf "10.147.17.1" network)
        , assertTrue "routes reference 10.147.17.0/24" (isInfixOf "10.147.17.0/24" routes)
        ]

  , test "E2E: capabilities in network config align with daemonset permissions" $ do
      network   <- readFileToString "configs/network.ncl"
      daemonset <- readFileToString "manifests/daemonset.yaml"
      allPass
        [ assertTrue "allow_managed_ips = true"
            (isInfixOf "allow_managed_ips = true" network)
        , assertTrue "NET_ADMIN capability in daemonset"
            (isInfixOf "NET_ADMIN" daemonset)
        ]
  ]
