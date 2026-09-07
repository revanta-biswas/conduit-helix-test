# Eval Scorecard — Story 1: Next.js application scaffold

**Scope**: changed-files (delta vs `99177bfb96802d3adcd47b9daf4cf95808c16926`)
**Eval Framework Version**: 1.0.0 · **Rubric Version**: 1.0.0

| Gate | Status | Notes |
|---|---|---|
| D1 Lint | PASS | conduit-next added as a 3rd root (this story's own fragment); zero findings |
| D2 Type check | N/A | plain JavaScript, REQ-NF-06 — no TypeScript in scope |
| D3 SAST (semgrep) | PASS | no new findings above threshold |
| D4 Dependency vulnerabilities | PASS | 2 high (nanoid, picomatch) + 1 high (postcss, bundled in next@15.5.25) fixed via root `overrides`; net repo-wide: 22 vulnerabilities (2 low/9 moderate/9 high/2 critical) -> 6 moderate, 0 high, 0 critical |
| D5 Licences | PASS | no disallowed licences |
| D6 Complexity | PASS | no complexity findings |
| D7 Secrets | PASS | no new secrets |
| Unit Test Coverage | N/A (documented exception) | 3/3 tests pass; 0/0 statements — genuinely unreachable in-process coverage for Next.js App-Router-mandated `.js`+JSX filenames; see `reports/unit-test-evidence/story-1/evidence-manifest.md` |
| Behaviour B1 | PASS | 4/4 scenarios, 24/24 steps, all @AC-1..@AC-4 executed, containerised (Podman) |
| Behaviour B2 | N/A | no other feature file exists yet (first story of the cycle) |
| Behaviour B3 | N/A | deferred — not the last work unit (16 stories with no PR yet) |
| API & Contract | N/A | no API layer touched by this story |
| J1 Architecture | *pending Code Review* | |
| J2 Security (OWASP) | *pending Code Review* | |

**Static Eval Verdict**: PASS (5 of 7 D1-D7 checks ran; 2 N/A with earned reasons — see above)

**Coverage note**: 0/0 in-process coverage is a documented, surfaced exception, not a suppressed
failure. Full reasoning and rejected alternatives: `reports/unit-test-evidence/story-1/evidence-manifest.md`.

**Dependency remediation note**: `postcss`'s fix required a FULL clean reinstall
(`rm -rf node_modules package-lock.json && npm install`) for the root `overrides` entry to actually
take effect — a plain `npm install` on top of an existing lockfile did not apply it. Confirmed the
override does not break the running application (dev server still starts, HTTP 200, full test suite
still 15/15 green after the reinstall).
