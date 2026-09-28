# Requirements: conduit-helix-test Next.js Migration

## Intent Analysis Summary

- **User request**: "using helix mcp bring the mordenzation plan then use helix aire fraework skip ci for this entirely only devlopmemnt" — run the AIRE framework against the Helix-sourced modernization (migration) plan, skipping CI pipeline generation, development only.
- **Request type**: Migration
- **Scope estimate**: System-wide (entire monorepo — both `backend/` and `frontend/` workspaces migrate to a unified Next.js app)
- **Complexity estimate**: Complex (full-stack framework migration, auth strategy change, ORM porting, RSC/Client Component split)
- **Depth**: Standard-to-Comprehensive — the Migration Strategy document from Helix/Atlas already supplies most of the detail (phases, risks, effort, data plan, testing strategy); this document translates that plan into AIRE's requirements format and resolves the few gaps AIRE needed answered.

**Context Project artifacts consulted**: none (user declined both existing-knowledge and new-references in Workspace Detection).
**Design references consulted**: none named.
**Atlas/Epic sources**: `spec/plans/atlas-deep-dive.md` (System Exploration deep dive), `spec/plans/epic-brief.md` (Migration Strategy) — both pulled from Helix, full content, provenance blocks intact.

---

## Scope for This AIRE Cycle

Per user decision (Requirements Analysis Q3): this cycle covers **Migration Strategy Phase 0 (Setup) through Phase 2 (Frontend Page Migration)** — a fully working Next.js app under `src/`, with the existing `backend/`/`frontend/` directories left untouched and still the live system. Phase 3 (production deploy/DNS cutover, decommissioning old directories) is **out of scope** for this cycle — explicitly deferred to a manual follow-up once the user has validated the new app locally.

**Directory mapping**: the Migration Strategy's `conduit-next/` target directory is treated as AIRE's `src/` root (per `common/directory-structure.md` — all new application code lives in `src/`). Every place the Migration Strategy says `conduit-next/app/api/...` etc., read it as `src/app/api/...`.

---

## Functional Requirements

### Setup & Foundation

- **REQ-F-01**: Initialize a Next.js 15 App Router application under `src/`, alongside the existing untouched `backend/` and `frontend/` workspaces.
- **REQ-F-02**: Configure ESLint and Prettier for the new `src/` app (JavaScript, not TypeScript, per user decision).
- **REQ-F-03**: Port the 4 Sequelize models (`Article`, `User`, `Tag`, `Comment`) and their associations from `backend/models/` into `src/lib/db/models/`, verbatim in logic, with import paths and the Sequelize instantiation adapted to a Next.js singleton pattern (prevents duplicate connection pools under dev hot-reload).
- **REQ-F-04**: Port `backend/config/config.js` DB connection config into `src/lib/db/config.js`, adapted to read Next.js environment variables (`.env.local`).
- **REQ-F-05**: The new app must boot with `next dev`, connect to the existing PostgreSQL database, and load all 4 models with their associations intact.

### API Layer (Route Handlers)

- **REQ-F-10**: Implement `POST /api/users` (register) and `POST /api/users/login` as Next.js Route Handlers, replacing `backend/routes/users.js` + `backend/controllers/users.js`.
- **REQ-F-11**: Implement `GET /api/user` and `PUT /api/user` (get/update current user) as Route Handlers, replacing `backend/routes/user.js` + `backend/controllers/user.js`.
- **REQ-F-12**: Implement the full articles resource group as Route Handlers: list/feed (`GET /api/articles`, `GET /api/articles/feed`), single article CRUD (`GET/PUT/DELETE /api/articles/:slug`), create (`POST /api/articles`), favorites (`POST/DELETE /api/articles/:slug/favorite`), and comments (`GET/POST/DELETE` on `/api/articles/:slug/comments[/:id]`) — replacing `backend/routes/articles.js` + `backend/routes/articles/favorites.js` + `backend/controllers/articles.js` + `backend/controllers/favorites.js` + `backend/controllers/comments.js`.
- **REQ-F-13**: Implement `GET/POST/DELETE /api/profiles/:username[/follow]` as Route Handlers, replacing `backend/routes/profiles.js` + `backend/controllers/profiles.js`.
- **REQ-F-14**: Implement `GET /api/tags` as a Route Handler, replacing the existing tags route.
- **REQ-F-15**: Port JWT authentication as Next.js Middleware (`src/middleware.ts`... — JS: `src/middleware.js`) + `src/lib/auth.js`, replacing `backend/middleware/authentication.js`. Auth uses `httpOnly` cookies set by the login/register Route Handlers (replacing localStorage JWT storage).
- **REQ-F-16**: Port the custom error class hierarchy (`MyError`, `ForbiddenError`, `NotFoundError`, `UnauthorizedError`, etc.) from `backend/helper/customErrors.js` into `src/lib/errors.js`, and the shared helpers (`slugify`, `appendFollowers`, `appendFavorites`, `appendTagList`) from `backend/helper/helpers.js` into `src/lib/helpers.js`.
- **REQ-F-17**: Fix the N+1 query pattern: replace the per-article `appendFollowers`/`appendFavorites`/`appendTagList` loop calls with Sequelize `include` eager loading in the Route Handlers that list/feed articles.
- **REQ-F-18**: Remove `sequelize.sync({ alter: true })` from the new app's startup path; use `sequelize.authenticate()` only, with schema managed by the existing Sequelize CLI migrations (`backend/migrations/`, reused as-is).

### Frontend Pages (App Router)

- **REQ-F-20**: Implement the Home page (`src/app/(home)/page.js`) as a Server Component fetching the global/personal feed, replacing `frontend/src/routes/Home.jsx`.
- **REQ-F-21**: Implement the Article view page (`src/app/article/[slug]/page.js`) as a Server Component, replacing `frontend/src/routes/Article/Article.jsx`.
- **REQ-F-22**: Implement the Article editor (create + edit) as Client Components (`src/app/editor/page.js`, `src/app/editor/[slug]/page.js`), replacing `frontend/src/routes/ArticleEditor.jsx`.
- **REQ-F-23**: Implement the Profile page (`src/app/profile/[username]/page.js`) as a Server Component, replacing `frontend/src/routes/Profile/Profile.jsx`.
- **REQ-F-24**: Implement Login and Register pages as Client Components (`src/app/login/page.js`, `src/app/register/page.js`), replacing `frontend/src/routes/Login.jsx`.
- **REQ-F-25**: Implement the Settings page as a Client Component (`src/app/settings/page.js`), replacing `frontend/src/routes/Settings.jsx`.
- **REQ-F-26**: Port all ~20 reusable UI components from `frontend/src/components/` into `src/components/`, preserving existing CSS/styling as-is (no Tailwind).
- **REQ-F-27**: Replace the 14 Axios service files with direct `fetch` calls in Server Components and Server Actions in Client Components — no Axios dependency in `src/`.
- **REQ-F-28**: Replace `AuthContext` (localStorage-based) with cookie-based session resolution (server-side session read via the auth middleware/lib), preserving the same auth-state surface consumed by pages/components.
- **REQ-F-29**: Replace `FeedContext` (global/personal/tag feed filter state) with URL search params driving Server Component re-render.
- **REQ-F-30**: Replace all React Router DOM `<Link>`/routing usages with Next.js `<Link>` and file-system routing.

### Testing

- **REQ-F-40**: Establish a Vitest + React Testing Library baseline in `src/` (tests under `tests/unit/` per AIRE convention, mirroring `src/`), covering: model association tests for all 4 models, Route Handler tests for each API resource group, and component tests for key UI flows (auth forms, article editor, feed).

---

## Non-Functional Requirements

- **REQ-NF-01** (Security): Authentication tokens must be carried in `httpOnly` cookies, not `localStorage`, closing the XSS exposure identified in the Atlas deep dive.
- **REQ-NF-02** (Performance): Article list/feed responses must not exhibit N+1 query behavior — verified via Sequelize query logging showing a bounded number of queries per feed request, independent of article count.
- **REQ-NF-03** (Data safety): The production/dev database schema must never be altered implicitly at boot; schema changes only via explicit Sequelize CLI migrations.
- **REQ-NF-04** (Compatibility): The new API's request/response contract must match the existing Conduit/RealWorld API spec exactly (endpoints, payload shapes, error format `{ errors: { body: [...] } }`) so the ported frontend (and any existing API consumers) work unchanged.
- **REQ-NF-05** (Maintainability): No dependency on Axios or React Router DOM in the new `src/` app — Next.js-native patterns only (`fetch`, Server Actions, file-system routing).
- **REQ-NF-06** (Testability): Establish automated test coverage for the migrated code as it is written (model, Route Handler, and component tests) — the existing near-zero coverage is not carried forward as acceptable for new code.
- **REQ-NF-07** (Non-goals, explicit): No production deployment, DNS cutover, or decommissioning of `backend/`/`frontend/` in this cycle (Phase 3 deferred). No TypeScript migration. No Tailwind adoption. No Prisma switch — Sequelize is retained.

---

## User Scenarios (carried from the Migration Strategy's UAT checklist — will become story acceptance criteria)

| Flow | Scenario |
|------|------|
| Auth | Register new user → JWT set as httpOnly cookie |
| Auth | Login → navigate to protected pages |
| Auth | Refresh page → stay logged in (cookie persists) |
| Articles | Browse global feed, paginate |
| Articles | Filter by tag |
| Articles | View single article with comments |
| Articles | Create article → appears in feed |
| Articles | Edit own article |
| Articles | Delete own article |
| Social | Follow a user → see their articles in personal feed |
| Social | Favorite an article → see it in profile favorites |
| Profile | View own profile, view another user's profile |
| Settings | Update bio, image, email |

---

## Business Context

- **Goal**: Unify the split React SPA + Express API monorepo into one Next.js app, per the Helix-sourced Migration Strategy, while fixing known technical debt (N+1 queries, unsafe `sequelize.sync`, XSS-prone auth storage) along the way.
- **Constraints**: Solo developer, self-paced (no hard deadline), clean-cutover-acceptable risk tolerance, PostgreSQL database is non-negotiable and stays in place.
- **Success criteria**: see Migration Strategy `epic-brief.md` — restated as REQ-F-01 through REQ-F-40 above, scoped to Phases 0-2.

## Technical Context

- **Integration points**: PostgreSQL only (via Sequelize) — no third-party APIs, queues, or external services.
- **System boundaries**: `src/` (new Next.js app) is additive during this cycle; `backend/` and `frontend/` remain the live system and are not touched until a future, out-of-scope Phase 3.
- **Data requirements**: no schema changes; same tables, same columns, same migrations.

## Quality Attributes

- Reliability: existing Sequelize CLI migrations remain the schema source of truth; no implicit schema alteration.
- Maintainability: service-layer elimination (Axios → fetch/Server Actions) reduces indirection; N+1 fix and error-hierarchy port preserve existing conventions.
- Testability: Vitest + RTL baseline established for all new code as REQ-F-40.
- Accessibility: not explicitly required by the Migration Strategy; components are ported as-is (no accessibility audit in scope for this cycle).

---

## Extension Configuration

| Extension | Enabled | Rationale |
|---|---|---|
| Property-Based Testing | No | Small solo CRUD blogging app with limited algorithmic complexity — user declined |
| Resiliency Baseline | No | Not a business-critical/high-availability workload — user declined |
| Security Baseline | Yes (mandatory, always-on) | Applies regardless of user choice |
| Playwright Test Automation | Yes (mandatory, always-on) | Applies regardless of user choice |

## CI Configuration (per user's original request)

CI pipeline generation (`.github/workflows/agentic-eval-pipeline.yml`), the SonarQube setup gate, and the epic-level `smoke-test-epic` are **skipped for this cycle**. All other gates (unit tests, coverage thresholds, Gherkin/behavior gates, D1-D7 static gates, judge gates) still run locally via `dev-implement`.
