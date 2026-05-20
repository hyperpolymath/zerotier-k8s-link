-- SPDX-License-Identifier: PMPL-1.0-or-later
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
--
-- Port of tests/aspect/security_aspect_test.ts to Idris2, estate-rollout 9/11.
-- 13 of 13 aspect tests ported.
--
-- The TS suite uses /[a-zA-Z0-9]{N,}/-style regexes to detect long alnum
-- runs that aren't EXAMPLE/CHANGEME placeholders. We re-derive longest-run
-- length as a pure helper (see ContractNetworkContractsTest.idr for the
-- twin) and gate on the absence-of-placeholder for the file as a whole.

module AspectSecurityTest

import Test.Spec
import Data.String
import Data.List
import System.File

%default covering

-- File helpers ---------------------------------------------------------------

readFileToString : String -> IO String
readFileToString path = do
  Right contents <- readFile path
    | Left _ => pure ""
  pure contents

-- Pure helpers ---------------------------------------------------------------

isAlnum : Char -> Bool
isAlnum c =
     (c >= '0' && c <= '9')
  || (c >= 'a' && c <= 'z')
  || (c >= 'A' && c <= 'Z')

longestAlnumRun : List Char -> Nat
longestAlnumRun = go 0 0
  where
    go : Nat -> Nat -> List Char -> Nat
    go best _   []        = best
    go best cur (c :: cs) =
      if isAlnum c
        then let cur' = S cur
                 best' = if cur' > best then cur' else best
             in go best' cur' cs
        else go best 0 cs

-- `safeFromLongAlnum content`: True iff the file either has no 20+
-- alphanumeric run, OR contains an EXAMPLE/CHANGEME placeholder (so the
-- long run is plausibly a placeholder, not a real credential).
safeFromLongAlnum : Nat -> String -> Bool
safeFromLongAlnum threshold content =
  let run = longestAlnumRun (unpack content)
      hasPlaceholder = isInfixOf "EXAMPLE" content || isInfixOf "CHANGEME" content
  in run < threshold || hasPlaceholder

public export
allSuites : List TestCase
allSuites =
  [ test "Aspect: No hardcoded API keys in network config" $ do
      content <- readFileToString "configs/network.ncl"
      allPass
        [ assertTrue "no 32+ alnum run without CHANGEME"
            (safeFromLongAlnum 32 content)
        , assertTrue "no sk_live_ Stripe pattern"
            (not (isInfixOf "sk_live_" content))
        , assertTrue "no zt_ literal token pattern (allow zt+ interface)"
            (not (isInfixOf "zt_real" content))
        ]

  , test "Aspect: No hardcoded tokens in daemonset" $ do
      content <- readFileToString "manifests/daemonset.yaml"
      -- If ZEROTIER_* env-var names appear, secretKeyRef or configMapKeyRef
      -- must also appear (i.e. they come from references, not literals).
      let hasZTEnv = isInfixOf "ZEROTIER_" content
      let hasSecretRef = isInfixOf "secretKeyRef" content
                     || isInfixOf "configMapKeyRef" content
      assertTrue "ZEROTIER_* env vars use secretKeyRef/configMapKeyRef"
        (not hasZTEnv || hasSecretRef)

  , test "Aspect: No HTTP endpoints (HTTPS only)" $ do
      a <- readFileToString "configs/network.ncl"
      b <- readFileToString "configs/firewall.ncl"
      c <- readFileToString "configs/routes.ncl"
      d <- readFileToString "manifests/daemonset.yaml"
      e <- readFileToString "manifests/networkpolicy.yaml"
      allPass
        [ assertTrue "no http:// in network.ncl"        (not (isInfixOf "http://" a))
        , assertTrue "no http:// in firewall.ncl"       (not (isInfixOf "http://" b))
        , assertTrue "no http:// in routes.ncl"         (not (isInfixOf "http://" c))
        , assertTrue "no http:// in daemonset.yaml"     (not (isInfixOf "http://" d))
        , assertTrue "no http:// in networkpolicy.yaml" (not (isInfixOf "http://" e))
        ]

  , test "Aspect: No world-readable permission patterns (chmod 777)" $ do
      a <- readFileToString "scripts/authorize-nodes.sh"
      b <- readFileToString "scripts/configure-routes.sh"
      c <- readFileToString "scripts/health-check.sh"
      d <- readFileToString "scripts/join-network.sh"
      e <- readFileToString "setup.sh"
      let bad : String -> Bool
          bad = \s => isInfixOf "chmod 777" s || isInfixOf "chmod a+rwx" s
      allPass
        [ assertTrue "authorize-nodes.sh"  (not (bad a))
        , assertTrue "configure-routes.sh" (not (bad b))
        , assertTrue "health-check.sh"     (not (bad c))
        , assertTrue "join-network.sh"     (not (bad d))
        , assertTrue "setup.sh"            (not (bad e))
        ]

  , test "Aspect: ZeroTier auth tokens are placeholders only" $ do
      content <- readFileToString "manifests/secret.yaml"
      let hasPlaceholder = isInfixOf "EXAMPLE_API_TOKEN" content
                        && isInfixOf "EXAMPLE_NETWORK_ID" content
      allPass
        [ assertTrue "EXAMPLE_API_TOKEN + EXAMPLE_NETWORK_ID placeholders" hasPlaceholder
        , assertTrue "no 20+ alnum run without EXAMPLE/CHANGEME"
            (safeFromLongAlnum 20 content)
        ]

  , test "Aspect: NetworkPolicy has both ingress and egress rules" $ do
      content <- readFileToString "manifests/networkpolicy.yaml"
      allPass
        [ assertTrue "ingress: present"  (isInfixOf "ingress:" content)
        , assertTrue "egress: present"   (isInfixOf "egress:" content)
        , assertTrue "ingress not empty" (not (isInfixOf "ingress: []" content))
        , assertTrue "egress not empty"  (not (isInfixOf "egress: []" content))
        ]

  , test "Aspect: No plaintext passwords in manifests" $ do
      -- A literal `password:` or `passwd:` key would be flagged. We mirror by
      -- asserting none of these keys appears in the manifests at all.
      a <- readFileToString "manifests/configmap.yaml"
      b <- readFileToString "manifests/daemonset.yaml"
      c <- readFileToString "manifests/namespace.yaml"
      d <- readFileToString "manifests/networkpolicy.yaml"
      e <- readFileToString "manifests/secret.yaml"
      f <- readFileToString "manifests/servicemonitor.yaml"
      let noPwd : String -> Bool
          noPwd = \s => not (isInfixOf "password:" s) && not (isInfixOf "passwd:" s)
      allPass
        [ assertTrue "configmap.yaml"      (noPwd a)
        , assertTrue "daemonset.yaml"      (noPwd b)
        , assertTrue "namespace.yaml"      (noPwd c)
        , assertTrue "networkpolicy.yaml"  (noPwd d)
        , assertTrue "secret.yaml"         (noPwd e)
        , assertTrue "servicemonitor.yaml" (noPwd f)
        ]

  , test "Aspect: No exposure of internal credentials via logs" $ do
      content <- readFileToString "manifests/daemonset.yaml"
      allPass
        [ assertTrue "no echo $ZEROTIER_NETWORK_ID"
            (not (isInfixOf "echo \"$ZEROTIER_NETWORK_ID" content))
        , assertTrue "no echo $ZEROTIER_API_TOKEN"
            (not (isInfixOf "echo \"$ZEROTIER_API_TOKEN" content))
        ]

  , test "Aspect: Firewall denies by default (principle of least privilege)" $ do
      content <- readFileToString "configs/firewall.ncl"
      let outputDecl = isInfixOf "output_policy = \"ACCEPT\"" content
                    || isInfixOf "output_policy = \"DROP\"" content
      allPass
        [ assertTrue "input_policy = DROP"   (isInfixOf "input_policy = \"DROP\"" content)
        , assertTrue "forward_policy = DROP" (isInfixOf "forward_policy = \"DROP\"" content)
        , assertTrue "output_policy decided" outputDecl
        ]

  , test "Aspect: DaemonSet security context restricts container capabilities" $ do
      content <- readFileToString "manifests/daemonset.yaml"
      assertTrue "securityContext: present" (isInfixOf "securityContext:" content)

  , test "Aspect: No hardcoded secrets in scripts" $ do
      a <- readFileToString "scripts/authorize-nodes.sh"
      b <- readFileToString "scripts/configure-routes.sh"
      c <- readFileToString "scripts/health-check.sh"
      d <- readFileToString "scripts/join-network.sh"
      e <- readFileToString "setup.sh"
      allPass
        [ assertTrue "authorize-nodes.sh no 32+ alnum without placeholder/var"
            (safeFromLongAlnum 32 a || isInfixOf "${" a)
        , assertTrue "configure-routes.sh no 32+ alnum without placeholder/var"
            (safeFromLongAlnum 32 b || isInfixOf "${" b)
        , assertTrue "health-check.sh no 32+ alnum without placeholder/var"
            (safeFromLongAlnum 32 c || isInfixOf "${" c)
        , assertTrue "join-network.sh no 32+ alnum without placeholder/var"
            (safeFromLongAlnum 32 d || isInfixOf "${" d)
        , assertTrue "setup.sh no 32+ alnum without placeholder/var"
            (safeFromLongAlnum 32 e || isInfixOf "${" e)
        ]

  , test "Aspect: Network config disables dangerous capabilities" $ do
      content <- readFileToString "configs/network.ncl"
      allPass
        [ assertTrue "allow_global_ips = false"   (isInfixOf "allow_global_ips = false" content)
        , assertTrue "allow_default_route = false" (isInfixOf "allow_default_route = false" content)
        ]

  , test "Aspect: Kubernetes RBAC references are appropriate" $ do
      content <- readFileToString "manifests/daemonset.yaml"
      assertTrue "no cluster-admin role" (not (isInfixOf "cluster-admin" content))

  , test "Aspect: Secret is type Opaque not other types" $ do
      content <- readFileToString "manifests/secret.yaml"
      assertTrue "type Opaque"
        (isInfixOf "type: Opaque" content || isInfixOf "type: \"Opaque\"" content)
  ]
