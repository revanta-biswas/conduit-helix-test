# Code Generation Plan — Story 1.2: Auth API (Register, Login & httpOnly Cookie Session)

**Tracker**: [#20](https://github.com/revanta-biswas/conduit-helix-test/issues/20) | **Epic**: Milestone #2 | **Branch**: story/1.2-auth-api
**Covers**: REQ-F-10, REQ-F-15, REQ-F-16, REQ-F-18, REQ-NF-01, REQ-NF-03

**Grounding**: story ACs (#1.2), requirements.md, architecture.md (Section 3 layering: Route Handler ->
Service -> Model, auth cross-cutting, ARCH-03 no localStorage, ARCH-04 contract parity, ARCH-05 no
unsafe sync), application-design.md (Auth Library, Auth Middleware, Errors/Helpers Library, Users/User
Service), functional-design.md (tightened validation rules table, error hierarchy, httpOnly cookie),
nfr.md (REQ-NF-01), plus the actual backend/{helper,middleware,controllers}/*.js (read directly).

## Plan Steps

- [x] **S1 — Errors + helpers libraries** (REQ-F-16)
  - `src/lib/errors.js` — port MyError/ForbiddenError/NotFoundError/UnauthorizedError/ValidationError/
    FieldRequiredError/AlreadyTakenError verbatim (ESM), plus a `statusFor(error)` mapping to the Conduit
    HTTP codes (401/403/404/422/500) and a `toErrorResponse(error)` producing `{ errors: { body: [msg] } }`.
  - `src/lib/helpers.js` — port `slugify` (needed by Story 1.4; included now as the shared helper module
    this story creates per dependency-graph shared_files). appendFollowers/appendFavorites/appendTagList
    are deferred to Story 1.4's eager-load redesign — NOT ported as N+1 loops here.
- [x] **S2 — Auth library + cookie session** (REQ-F-15, REQ-NF-01)
  - `src/lib/auth.js` — `signSession(user)` (jsonwebtoken, JWT_SECRET/JWT_KEY from env), `verifySession(token)`,
    `getSessionUser(request)` (reads the httpOnly cookie, resolves the User, returns null on absence — soft
    auth), `requireSessionUser(request)` (throws UnauthorizedError if absent), cookie name `conduit_token`,
    httpOnly + sameSite=lax + secure-in-production. Cookie set/clear helpers return the Set-Cookie header
    value (Route Handlers apply them to NextResponse).
- [x] **S3 — Next.js Middleware** (REQ-F-15)
  - `src/middleware.js` — Next.js middleware that, for protected API routes, verifies the cookie and
    (soft-auth) lets public routes through. Matcher scoped to `/api/*`.
- [x] **S4 — Users service (register/login business logic)** (REQ-F-10, tightened validation)
  - `src/lib/services/users.js` — `register({username,email,password})` and `login({email,password})`.
    Tightened validation (functional-design.md): email format, password >= 8 chars, username 3-30
    [A-Za-z0-9_-], username uniqueness, email uniqueness. bcrypt hash/compare (port backend/helper/bcrypt).
    Returns the user (password redacted by the model's toJSON) + a signed token.
- [x] **S5 — Route Handlers** (REQ-F-10, REQ-F-15, ARCH-01, ARCH-04)
  - `src/app/api/users/route.js` — POST (register) -> 201 + httpOnly cookie + `{ user }`.
  - `src/app/api/users/login/route.js` — POST (login) -> 200 + httpOnly cookie + `{ user }`.
  - Thin: parse body, call the service, map errors via lib/errors, set the cookie. NEVER import a model
    directly (ARCH-01).
- [x] **S6 — sequelize.sync removal confirmation** (REQ-F-18, ARCH-05)
  - Confirmed already satisfied by Story 1.1's src/lib/db/index.js (authenticate() only). This story adds
    nothing that syncs; a behaviour scenario re-asserts it.
- [x] **S7 — Unit tests (SH-LOOP-1, >=90%)** (REQ-NF-06)
  - `tests/unit/lib/errors.test.js`, `tests/unit/lib/auth.test.js`, `tests/unit/lib/services/users.test.js`
    — validation rules, bcrypt round-trip, JWT sign/verify, error->status mapping. sqlite in-memory DB.
- [x] **S8 — Gherkin step defs (B1)** — `tests/behavior/steps/story-1.2_steps.js` bound to the users
  service + auth library public surface.

## REQ/AC Trace Self-Check

| Plan step | ACs | REQ-IDs |
|---|---|---|
| S1 | AC-1 (errors) | REQ-F-16 |
| S2 | AC-2 | REQ-F-15, REQ-NF-01 |
| S3 | AC-2 | REQ-F-15 |
| S4 | AC-1, AC-5 | REQ-F-10 |
| S5 | AC-1, AC-5 | REQ-F-10, REQ-F-15 |
| S6 | AC-4 | REQ-F-18, REQ-NF-03 |
| S7 | AC-1,2,5 | REQ-NF-06 |
| S8 | AC-1..5 | (behaviour contract) |

Every covered REQ-ID (10,15,16,18; NF-01,NF-03) in >=1 step; every AC in >=1 step. Trace complete.

## Notes / Deviations
- **API Layer step present** -> the API & Contract Testing Gate (Step 6.2) APPLIES this story.
- **helpers.js** ships only `slugify` now (the shared module this story owns per dependency-graph);
  the enrichment functions are intentionally NOT ported as N+1 loops — Story 1.4 adds the eager-load
  redesign (ARCH-02). Stated plainly, not a silent omission.
- **JWT env var**: the legacy backend uses `JWT_KEY`; requirements/`.env.local.example` use `JWT_SECRET`.
  auth.js reads `JWT_SECRET ?? JWT_KEY` so both work — recorded as a compatibility choice.
