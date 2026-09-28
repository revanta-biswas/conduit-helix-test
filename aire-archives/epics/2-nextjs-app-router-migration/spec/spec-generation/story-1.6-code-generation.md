# Code Generation Plan — Story 1.6: Auth Pages & Session (Login, Register, Settings)

**Tracker**: [#24](https://github.com/revanta-biswas/conduit-helix-test/issues/24) | **Epic**: Milestone #2 | **Branch**: story/1.6-auth-pages
**Covers**: REQ-F-24, REQ-F-25, REQ-F-28

**Grounding**: story ACs (#1.6), architecture.md (ARCH-03 no localStorage), functional-design.md
(no AuthContext — server-verified cookie session; client validation is UX-only, server is source of
truth), application-design.md (Login/Register/Settings Client Components, cookie session), plus
frontend/src/routes/{Login,SignUp,Settings}.jsx + context/AuthContext.jsx (structure reference).

**Scope decision (user-confirmed)**: MINIMAL functional pages — working forms that call the APIs
correctly; Story 1.9 ports the real ~20 UI components + existing CSS. No component-library port here.

## Plan Steps
- [x] **S1 — Server session helper** (REQ-F-28, ARCH-03) — src/lib/session.js:
  `getServerSession()` reads the httpOnly cookie via next/headers `cookies()` and resolves the user
  (server-side, no localStorage). `logout()` server action clears the cookie. This REPLACES AuthContext.
- [x] **S2 — Client API helper** — src/lib/client-api.js: thin `fetch` wrappers (`apiPost`, `apiPut`)
  that POST/PUT JSON to the Route Handlers with `credentials: 'include'` (so the httpOnly cookie rides
  along) and normalise the Conduit error envelope into a string[] for form display. NO axios (ARCH-06).
- [x] **S3 — Auth pages (Client Components, minimal)**:
  - src/app/login/page.js — email+password form -> POST /api/users/login -> redirect home on success.
  - src/app/register/page.js — username+email+password form -> POST /api/users -> redirect home.
  - src/app/settings/page.js — bio/image/email/password form -> PUT /api/user; logout button (server action).
  Each shows the server's validation errors (from the envelope). Minimal markup, no CSS port.
- [x] **S4 — Unit tests (>=90%)** — session helper (cookie present/absent -> user/null), client-api
  (success shape, error-envelope normalisation), form-submit handlers (the pure logic extracted from
  the pages: buildLoginPayload / buildRegisterPayload / buildSettingsPayload + error mapping).
- [x] **S5 — Gherkin step defs (B1)** — bound to the session helper + client-api + payload builders
  (the observable non-UI logic). UI rendering itself is ve/Playwright territory (Story 1.9+).

## REQ/AC Trace
| Step | ACs | REQ-IDs |
|---|---|---|
| S1 | AC-3 | REQ-F-28 |
| S2 | AC-1,2 | REQ-F-24, REQ-F-25 |
| S3 | AC-1,2,5 | REQ-F-24, REQ-F-25 |
| S4/S5 | AC-1..5 | REQ-NF-06 |
Trace complete.

## Notes
- **No API layer step** -> the API & Contract gate is N/A for this story (it consumes APIs, adds none).
- Cookie-based session replaces AuthContext entirely (ARCH-03 / REQ-F-28): no localStorage anywhere.
- Client-side validation is a UX nicety; the server (Story 1.2/1.3 services) remains the source of truth.
- Page components are minimal by design (user-confirmed); Story 1.9 does the component/CSS port.
