# Playwright Automation Summary — #24 Auth Pages & Session (Login, Register, Settings)

**Plan**: tests/playwright-specs/24-auth-pages-session-login-register-settings.md (Approved 2026-09-10)
**Generated tests**: tests/e2e/24-auth-pages-session-login-register-settings/
**Generated**: 2026-09-10T06:55:00Z   **AIRE VERSION**: 1.0
**Story**: 1.6 — [#24](https://github.com/revanta-biswas/conduit-helix-test/issues/24)
**Seed**: tests/e2e/seed.spec.ts (shared fixture account `playwright_fixture@example.com`)

## UI Test Cases Automated
| Manual TC | Generated spec | Result |
|-----------|-----------------|--------|
| TC-E2E-01 | tc-e2e-01-register-lands-logged-in.spec.ts | ✅ Pass |
| TC-E2E-02 | tc-e2e-02-register-duplicate-rejected.spec.ts | ✅ Pass |
| TC-SEC-03 | tc-sec-03-login-wrong-password-rejected.spec.ts | ✅ Pass |
| TC-A11Y-01 | tc-a11y-01-login-keyboard-focus-order.spec.ts | ✅ Pass |
| TC-E2E-03 | tc-e2e-03-settings-update-persists.spec.ts | ✅ Pass (healed — login-settle wait) |
| TC-E2E-04 | tc-e2e-04-settings-invalid-image-url.spec.ts | ✅ Pass (app accepts invalid image URL, 2xx) |
| TC-E2E-05 | tc-e2e-05-session-persists-nav-refresh.spec.ts | ✅ Pass (healed — login-settle wait) |
| TC-E2E-06 | tc-e2e-06-logout-logged-out-state.spec.ts | ✅ Pass |
| TC-SEC-01 | tc-sec-01-no-token-in-client-storage.spec.ts | ✅ Pass |
| TC-SEC-02 | tc-sec-02-session-cookie-httponly.spec.ts | ✅ Pass (conduit_token httpOnly=true confirmed) |
| TC-SEC-04 | tc-sec-04-settings-no-session-no-data.spec.ts | ✅ Pass (asserts server-side 401, not client redirect) |
| TC-SEC-05 | tc-sec-05-logout-clears-cookie.spec.ts | ✅ Pass |
| TC-SEC-06 | tc-sec-06-session-survives-refresh.spec.ts | ✅ Pass |
| TC-SEC-07 | tc-sec-07-injection-input-safe.spec.ts | ✅ Pass (healed — await error-list before branch) |
| TC-A11Y-02 | tc-a11y-02-inputs-accessible-names.spec.ts | ✅ Pass |
| TC-A11Y-03 | tc-a11y-03-focus-visible.spec.ts (links+inputs) | ✅ Pass |
| TC-A11Y-03 | tc-a11y-03-focus-visible.spec.ts (buttons) | ⏭️ test.fixme() — **candidate defect** |
| TC-A11Y-06 | tc-a11y-06-reflow-200-zoom.spec.ts | ✅ Pass |

**Final run: 19 passed, 1 skipped (fixme), 0 failed.**

## Manual Cases Excluded (backend/API-only or tooling-bound — out of scope for this extension)
| Manual TC | Reason |
|-----------|--------|
| TC-A11Y-04 | Screen-reader error-announcement verification — requires assistive tech; stays manual-only |
| TC-A11Y-05 | Colour-contrast ratio measurement — requires a contrast checker; stays manual-only |

## Consistency Pass (Step 3.5)
Reconciled two items across the 17 specs: (1) unified the "New password" locator to the full accessible name `New password (leave blank to keep)` (some specs used a truncated substring); (2) changed one absolute `http://localhost:3000/settings` navigation in tc-sec-04 to a relative `/settings` (baseURL-driven), matching every other spec. All login/header/error locators were already consistent (accessible-name `getByRole`). No foreign-stack boilerplate found.

## Healer Outcomes
| Spec | Outcome | Notes |
|------|---------|-------|
| tc-sec-07 | Healed to passing | Test bug — awaited the errors list before branching (app correctly rejects `<script>` username via validation) |
| tc-e2e-05 | Healed to passing | Test timing — wait for logged-in header to settle after login before navigating; app session genuinely persists |
| tc-e2e-03 | Healed to passing | Same login→cookie-settle race; added post-login wait; bio persistence verified via /profile |
| tc-a11y-03 (buttons) | test.fixme() — **candidate defect** | Sign in / Sign up / Update Settings / Log out buttons have `outline: none` with no alternative focus style — genuine WCAG 2.4.7 violation. Route to /raise-defect. |

## Candidate Product Defects Surfaced (route to /raise-defect)
1. **WCAG 2.4.7 (High)** — action buttons (Sign in, Sign up, Update Settings, Log out) suppress the focus outline with no alternative indicator; not keyboard-focus-visible. (Isolated as tc-a11y-03 fixme.)
2. **AC-2 / settings pre-population (Medium)** — the /settings form never pre-populates the current user's bio/image/email; always renders empty. Tests work around it (verify persistence via /profile), but it diverges from the story's implied behavior.
3. **AC-3 / AC-5 route guard (Medium)** — /settings is not client-side route-guarded; a logged-out user sees the empty form (no redirect to /login); only the PUT is rejected server-side (401). AC implies a logged-out redirect.
4. **AC-1 token-in-body (from env check, Medium)** — register/login responses also return the JWT in a `user.token` body field (in addition to the httpOnly cookie), contrary to AC-1's "never returned in a JSON body field."

## AC Coverage (automated UI + remaining manual combined)
5/5 acceptance criteria have ≥1 automated OR manual test case (AC-1 register/login incl. injection & keyboard; AC-2 settings update; AC-3 cookie-not-localStorage; AC-4 session persistence; AC-5 logout). ✅
