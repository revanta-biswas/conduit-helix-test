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
| J1 Architecture | N/A | all 6 architecture-rubric.json criteria scoped to `lib/**`/`middleware.ts`/`app/api/**`, none of which exist in this diff; N/A never blocks — `reports/eval-evidence/story-1/judge/architecture-score.json` |
| J2 Security (OWASP) | PASS (1.00 / min 0.85) | 6/8 criteria N/A (no auth/API/data/logging surface); 2 scoreable (SEC-06 config, SEC-07 supply chain) both 1.0 — `reports/eval-evidence/story-1/judge/security-score.json` |

**Static Eval Verdict**: PASS (5 of 7 D1-D7 checks ran; 2 N/A with earned reasons — see above)

**Overall Eval Verdict**: **PASS** — all gates PASS or N/A; J1 is N/A (never blocks), J2 = 1.00 clears the 0.85 minimum. Computed in Code Review Phase 3.5 (`reports/reviews/story-1-code-review-v1.md`).

**Coverage note**: 0/0 in-process coverage is a documented, surfaced exception, not a suppressed
failure. Full reasoning and rejected alternatives: `reports/unit-test-evidence/story-1/evidence-manifest.md`.

**Dependency remediation note**: `postcss`'s fix required a FULL clean reinstall
(`rm -rf node_modules package-lock.json && npm install`) for the root `overrides` entry to actually
take effect — a plain `npm install` on top of an existing lockfile did not apply it. Confirmed the
override does not break the running application (dev server still starts, HTTP 200, full test suite
still 15/15 green after the reinstall).

**CI Attestation Gate finding (post-PR-raise)**: `npm ci` (used by CI's `Install dependencies` step,
never `npm install`) failed on the committed lockfile with an `EUSAGE` peer-conflict:
`@swc/helpers@0.5.15` (pinned by `next@15.5.25` as a real dependency) did not satisfy the `>=0.5.17`
**optional** peer declared by `@swc/core@1.16.2` (pre-existing test tooling, via
`@vitejs/plugin-react-swc`). Reproduced locally (`rm -rf node_modules && npm ci` failed identically),
confirming this was a genuine manifest defect this story introduced (the pre-Story-1 lockfile had no
`@swc/helpers` installed at all, so there was nothing for the peer range to conflict with). Fixed by
adding `@swc/helpers: 0.5.17` to root `overrides`. Re-verified after a full clean reinstall: `npm ci`
now succeeds, `next dev`/`next build --turbopack` both still work correctly, and the full test suite
is still 15/15 green.
