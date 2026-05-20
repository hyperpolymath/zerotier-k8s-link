-- SPDX-License-Identifier: PMPL-1.0-or-later
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

module Main

import Test.Spec
import UnitConfigStructureTest
import ContractNetworkContractsTest
import AspectSecurityTest
import PropertyNetworkPropertyTest
import SmokeInfraTest
import E2ENetworkTest
import System

%default covering

main : IO ()
main = do
  (p1, f1) <- runTestSuite "UnitConfigStructureTest" UnitConfigStructureTest.allSuites
  (p2, f2) <- runTestSuite "ContractNetworkContractsTest" ContractNetworkContractsTest.allSuites
  (p3, f3) <- runTestSuite "AspectSecurityTest" AspectSecurityTest.allSuites
  (p4, f4) <- runTestSuite "PropertyNetworkPropertyTest" PropertyNetworkPropertyTest.allSuites
  (p5, f5) <- runTestSuite "SmokeInfraTest" SmokeInfraTest.allSuites
  (p6, f6) <- runTestSuite "E2ENetworkTest" E2ENetworkTest.allSuites
  let totalPassed = p1 + p2 + p3 + p4 + p5 + p6
  let totalFailed = f1 + f2 + f3 + f4 + f5 + f6
  putStrLn ""
  putStrLn $ "=== Total: " ++ show totalPassed ++ " passed, " ++ show totalFailed ++ " failed ==="
  if totalFailed > 0
    then exitWith (ExitFailure 1)
    else pure ()
