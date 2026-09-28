## Eval Scorecard — Story 1.2 · **PASS**

| Gate | Status | Detail |
|---|---|---|
| D1 Lint | ✅ PASS | 0 new findings |
| D2 Type check | ⚪ N/A | plain JavaScript |
| D3 SAST (semgrep) | ✅ PASS | 0 new findings |
| D4 Dependencies | ✅ PASS | jsonwebtoken/bcryptjs added 0 new vulns (total 20, unchanged) |
| D5 Licenses | ✅ PASS | 0 disallowed (56 pkgs) |
| D6 Complexity | ✅ PASS | 0 over cap |
| D7 Secrets | ✅ PASS | 0 new on changed files |
| Unit + Coverage | ✅ PASS | 42/42 tests, 95.41% (min 90%) |
| Behaviour B1 | ✅ PASS | 12/12 scenarios, containerised (Podman) |
| Behaviour B2 | ✅ PASS | 17/17 cumulative (story-1.1 + 1.2), containerised |
| Behaviour B3 | ⚪ N/A | not the last work unit |
| API & Contract | ✅ PASS | 7/7 — register+login, 201/200/422/404, httpOnly cookie, error envelope |
| Full Regression | ✅ PASS | 49/49 src suite, 0 new failures vs baseline |
| **J1 Architecture** | ✅ **PASS** | **1.0** ≥ 0.85 (ARCH-01,03,04,05,06 applicable) |
| **J2 Security (OWASP)** | ✅ **PASS** | **1.0** ≥ 0.85 (SEC-02,03,04,05,07 applicable) |

**Judge model**: claude-sonnet-5 · **rubricVersion**: 1.0.0
**Note**: CI pipeline generation skipped this cycle per user request — all gates ran locally.
