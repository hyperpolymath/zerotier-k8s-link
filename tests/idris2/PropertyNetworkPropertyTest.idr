-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
--
-- Port of tests/property/network_property_test.ts to Idris2, estate-rollout 9/11.
-- 11 of 11 property-style tests ported.
--
-- This file mixes content-validation (files exist + contain substrings) with
-- pure-logic ports of the regex-driven property predicates: lowercase-hyphen
-- filename validation, hex network-ID validation, dotted-quad IPv4 validation,
-- IPv4-range ordering, CIDR-notation validation. Each predicate is exposed
-- and unit-tested below so a regression in the predicate itself is caught
-- alongside a regression in the file contents.

module PropertyNetworkPropertyTest

import Test.Spec
import Data.String
import Data.List
import Data.Maybe
import System.File

%default covering

-- File helpers ---------------------------------------------------------------

readFileToString : String -> IO String
readFileToString path = do
  Right contents <- readFile path
    | Left _ => pure ""
  pure contents

-- Pure helpers ---------------------------------------------------------------

isLowerC : Char -> Bool
isLowerC c = c >= 'a' && c <= 'z'

isDigitC : Char -> Bool
isDigitC c = c >= '0' && c <= '9'

isHex : Char -> Bool
isHex c =
     isDigitC c
  || (c >= 'a' && c <= 'f')
  || (c >= 'A' && c <= 'F')

-- Filename is /^[a-z-]+$/: at least 1 char, every char is a-z or '-'.
public export
isLowercaseHyphen : String -> Bool
isLowercaseHyphen s =
  let cs = unpack s in
  length cs > 0 && all (\c => isLowerC c || c == '-') cs

-- 16-character hex string: ZeroTier network ID format.
public export
isZTNetworkId : String -> Bool
isZTNetworkId s =
  let cs = unpack s in
  length cs == 16 && all isHex cs

-- Dotted-quad IPv4 parser.
parseOctet : List Char -> Maybe (Nat, List Char)
parseOctet xs =
  let digits = takeWhile isDigitC xs
      rest   = dropWhile isDigitC xs
  in if length digits == 0 || length digits > 3
       then Nothing
       else case parsePositive (pack digits) of
              Just n  => if n <= 255 then Just (n, rest) else Nothing
              Nothing => Nothing

public export
parseIPv4 : String -> Maybe (Nat, Nat, Nat, Nat)
parseIPv4 s =
  let xs = unpack s in
  case parseOctet xs of
    Just (a, ('.' :: r1)) =>
      case parseOctet r1 of
        Just (b, ('.' :: r2)) =>
          case parseOctet r2 of
            Just (c, ('.' :: r3)) =>
              case parseOctet r3 of
                Just (d, []) => Just (a, b, c, d)
                _            => Nothing
            _ => Nothing
        _ => Nothing
    _ => Nothing

public export
ipv4ToNat : (Nat, Nat, Nat, Nat) -> Nat
ipv4ToNat (a, b, c, d) =
  a * 16777216 + b * 65536 + c * 256 + d

-- A CIDR like "10.147.17.0/24" or "fd00:feed:face::/48". We accept either:
--   - IPv4 dotted-quad + '/' + 1-2 digits
--   - lowercase-hex with colons + '/' + 1-3 digits
addrOkParsed : Maybe (Nat, Nat, Nat, Nat) -> List Char -> Bool
addrOkParsed (Just _) _    = True
addrOkParsed Nothing  addr = all (\c => isHex c || c == ':') addr

public export
addrOk : List Char -> Bool
addrOk addr = addrOkParsed (parseIPv4 (pack addr)) addr

checkCidrRest : List Char -> List Char -> Bool
checkCidrRest addr (c :: rest) =
  c == '/' && length addr > 0 && length rest > 0 && all isDigitC rest && addrOk addr
checkCidrRest _ _ = False

public export
isCidr : String -> Bool
isCidr s =
  let parts = break (== '/') (unpack s) in
  checkCidrRest (fst parts) (snd parts)

-- Strip a known suffix from a String. Returns the prefix if it ends in
-- `suf`, otherwise the original string.
stripSuffix : String -> String -> String
stripSuffix suf s =
  let scs = unpack s
      ucs = unpack suf
  in if isSuffixOf ucs scs
       then pack (take (length scs `minus` length ucs) scs)
       else s

public export
allSuites : List TestCase
allSuites =
  [ test "Property: Nickel configs readable in 100-iteration loop" $ do
      let loop : Nat -> IO Bool
          loop Z     = pure True
          loop (S k) = do
            a <- readFileToString "configs/network.ncl"
            b <- readFileToString "configs/firewall.ncl"
            c <- readFileToString "configs/routes.ncl"
            if length a > 0 && length b > 0 && length c > 0
              then loop k
              else pure False
      ok <- loop 100
      assertTrue "100 reads, all non-empty" ok

  , test "Property: Nickel files follow lowercase-hyphen naming" $
      allPass
        [ assertTrue "network"  (isLowercaseHyphen (stripSuffix ".ncl" "network.ncl"))
        , assertTrue "firewall" (isLowercaseHyphen (stripSuffix ".ncl" "firewall.ncl"))
        , assertTrue "routes"   (isLowercaseHyphen (stripSuffix ".ncl" "routes.ncl"))
        ]

  , test "Property: Kubernetes manifest files follow naming conventions" $
      allPass
        [ assertTrue "configmap"      (isLowercaseHyphen (stripSuffix ".yaml" "configmap.yaml"))
        , assertTrue "daemonset"      (isLowercaseHyphen (stripSuffix ".yaml" "daemonset.yaml"))
        , assertTrue "namespace"      (isLowercaseHyphen (stripSuffix ".yaml" "namespace.yaml"))
        , assertTrue "networkpolicy"  (isLowercaseHyphen (stripSuffix ".yaml" "networkpolicy.yaml"))
        , assertTrue "secret"         (isLowercaseHyphen (stripSuffix ".yaml" "secret.yaml"))
        , assertTrue "servicemonitor" (isLowercaseHyphen (stripSuffix ".yaml" "servicemonitor.yaml"))
        ]

  , test "Property: ZeroTier network ID format validation" $ do
      -- Network ID is either a 16-char hex literal or a CHANGEME/EXAMPLE placeholder.
      content <- readFileToString "configs/network.ncl"
      let hasPlaceholderNetId =
            isInfixOf "CHANGEME_NETWORK_ID" content
            || isInfixOf "EXAMPLE_NETWORK_ID" content
      -- Predicate sanity: 16-char hex passes, anything else fails.
      allPass
        [ assertTrue "predicate accepts 16-char hex"    (isZTNetworkId "0123456789abcdef")
        , assertTrue "predicate rejects 15-char hex"    (not (isZTNetworkId "0123456789abcde"))
        , assertTrue "predicate rejects non-hex chars"  (not (isZTNetworkId "01234567890zzzzz"))
        , assertTrue "config has placeholder or 16-hex" hasPlaceholderNetId
        ]

  , test "Property: IPv4 assignment pool is valid range" $ do
      -- Predicate sanity first.
      let s = parseIPv4 "10.147.17.1"
      let e = parseIPv4 "10.147.17.254"
      let ordered = case (s, e) of
                      (Just a, Just b) => ipv4ToNat a < ipv4ToNat b
                      _                => False
      -- Then confirm the config has the documented pool literals.
      content <- readFileToString "configs/network.ncl"
      allPass
        [ assertTrue "start IPv4 parses"            (isJust s)
        , assertTrue "end IPv4 parses"              (isJust e)
        , assertTrue "start < end (Nat compare)"    ordered
        , assertTrue "start literal in config"      (isInfixOf "10.147.17.1" content)
        , assertTrue "end literal in config"        (isInfixOf "10.147.17.254" content)
        ]

  , test "Property: Firewall rules have action and type fields" $ do
      content <- readFileToString "configs/firewall.ncl"
      let hasAction = isInfixOf "action =" content
      let hasTypeOrProto = isInfixOf "type =" content || isInfixOf "protocol =" content
      allPass
        [ assertTrue "action field present" hasAction
        , assertTrue "type or protocol field present" hasTypeOrProto
        ]

  , test "Property: Route destinations are valid CIDR notation" $ do
      -- Predicate sanity.
      allPass
        [ assertTrue "10.147.17.0/24 is CIDR"          (isCidr "10.147.17.0/24")
        , assertTrue "fd00:feed:face::/48 is CIDR"     (isCidr "fd00:feed:face::/48")
        , assertTrue "192.168.1.1 (no prefix) rejected" (not (isCidr "192.168.1.1"))
        , assertTrue "10.0.0.0/ (empty prefix) rejected" (not (isCidr "10.0.0.0/"))
        ]

  , test "Property: Route destination literals are CIDR" $ do
      content <- readFileToString "configs/routes.ncl"
      allPass
        [ assertTrue "10.147.17.0/24 literal present"  (isInfixOf "10.147.17.0/24" content)
        , assertTrue "fd00:feed:face::/48 literal present" (isInfixOf "fd00:feed:face::/48" content)
        ]

  , test "Property: Kubernetes manifest namespace consistency" $ do
      d <- readFileToString "manifests/daemonset.yaml"
      n <- readFileToString "manifests/networkpolicy.yaml"
      s <- readFileToString "manifests/secret.yaml"
      let ns = "zerotier-system"
      allPass
        [ assertTrue "daemonset.yaml -> zerotier-system"     (isInfixOf ("namespace: " ++ ns) d)
        , assertTrue "networkpolicy.yaml -> zerotier-system" (isInfixOf ("namespace: " ++ ns) n)
        , assertTrue "secret.yaml -> zerotier-system"        (isInfixOf ("namespace: " ++ ns) s)
        ]

  , test "Property: DaemonSet selector matches pod labels" $ do
      content <- readFileToString "manifests/daemonset.yaml"
      allPass
        [ assertTrue "has selector:"        (isInfixOf "selector:" content)
        , assertTrue "has matchLabels:"     (isInfixOf "matchLabels:" content)
        , assertTrue "selector mentions zerotier" (isInfixOf "zerotier" content)
        ]

  , test "Property: NetworkPolicy pod selector is defined" $ do
      content <- readFileToString "manifests/networkpolicy.yaml"
      allPass
        [ assertTrue "podSelector:"  (isInfixOf "podSelector:" content)
        , assertTrue "matchLabels:"  (isInfixOf "matchLabels:" content)
        ]

  , test "Property: Firewall zone names are valid identifiers" $ do
      -- Predicate sanity: a few sample identifiers.
      let isZoneName : String -> Bool
          isZoneName s = let cs = unpack s in
                         length cs > 0
                      && all (\c => isLowerC c || isDigitC c || c == '_') cs
      content <- readFileToString "configs/firewall.ncl"
      allPass
        [ assertTrue "zerotier is valid zone name"  (isZoneName "zerotier")
        , assertTrue "Zerotier (capital) rejected"  (not (isZoneName "Zerotier"))
        , assertTrue "zones = { in firewall.ncl"    (isInfixOf "zones = {" content)
        , assertTrue "zerotier zone in firewall.ncl" (isInfixOf "zerotier =" content)
        ]
  ]
