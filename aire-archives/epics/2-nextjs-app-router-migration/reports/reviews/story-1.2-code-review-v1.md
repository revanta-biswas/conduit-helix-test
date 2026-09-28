# Code Review — Story 1.2: Auth API (Register, Login & httpOnly Cookie Session) (v1)

**Tracker**: [#20](https://github.com/revanta-biswas/conduit-helix-test/issues/20) | **Epic**: Milestone #2 | **Branch**: story/1.2-auth-api
**Reviewer**: automated (dev-implement Section A) — read-only
**Covers**: REQ-F-10, REQ-F-15, REQ-F-16, REQ-F-18, REQ-NF-01, REQ-NF-03

## Verdict: ✅ CLEAN — all ACs Met, 0 🔴 Blocker, 0 🟠 High

## Acceptance Criteria Assessment

| AC | Requirement | Status | Evidence |
|---|---|---|---|
| AC-1 | Register/login Route Handlers, httpOnly cookie set on success | ✅ Met | src/app/api/users/{route,login/route}.js; API tests assert 201/200 + httpOnly; B1 @AC-1 |
| AC-2 | Middleware + auth.js verify cookie, resolve user, soft-auth pass-through | ✅ Met | src/middleware.js, src/lib/auth.js; auth.test.js soft-auth + requireSessionUser; B1 @AC-2 |
| AC-3 | Error hierarchy + helpers ported | ✅ Met | src/lib/errors.js (+ statusFor/toErrorResponse), src/lib/helpers.js (slugify); errors.test.js |
| AC-4 | authenticate()-only startup, no unsafe sync | ✅ Met | reuses src/lib/db/index.js; B1 @AC-4 static guard |
| AC-5 | Full auth flow end-to-end, Conduit error format | ✅ Met | users.test.js + API contract tests (register→cookie→login; wrong-pw 422; unknown 404) |

## Gate Evidence (cited)
- Unit + coverage: 42/42, 95.41% (`reports/unit-test-evidence/story-1.2/`).
- API & Contract: 7/7, both endpoints, all 6 checklist categories (`reports/api-contract-test-evidence/story-1.2/`).
- Behaviour B1 12/12, B2 17/17 cumulative, containerised (`reports/behavior-test-evidence/story-1.2/`). B3 N/A.
- Full regression: 49/49, 0 new failures.
- Static D1–D7: all PASS on changed files (D2 N/A).

## Judge Gates (🔴 BLOCKING)
- **J1 Architecture: 1.0** ≥ 0.85 → PASS. ARCH-01 (handlers→service, never model), ARCH-03 (httpOnly not localStorage), ARCH-04 (contract parity), ARCH-05 (no unsafe sync), ARCH-06 (no axios) all 1.0. `judge/architecture-score.json`.
- **J2 Security: 1.0** ≥ 0.85 → PASS. SEC-02 (auth: httpOnly+bcrypt+tightened validation), SEC-03 (injection: ORM), SEC-04 (crypto: env secret), SEC-05 (misconfig), SEC-07 (error handling) all 1.0. `judge/security-score.json`.
- Judge model claude-sonnet-5, rubricVersion 1.0.0.

## Security Baseline Review (Phase 2.5)
See `reports/code-security-reviews/security-review-2026-09-09.md` (updated for 1.2). No 🔴/🟠 on the changed surface. httpOnly cookie closes the XSS exposure (REQ-NF-01); tightened validation reduces account-abuse surface.

## Notes (advisory)
- **Tightened validation** deliberately changes behaviour from the legacy backend (email format, 8-char password, username format+uniqueness) — per the approved Functional Design decision. Existing legacy users are unaffected (this is a new, additive API surface).
- `slugify` is shipped in `helpers.js` but unused until Story 1.4 — intentional (this story owns the shared module). The N+1 enrichment helpers are deliberately NOT ported here (Story 1.4 redesigns them as eager loads).
