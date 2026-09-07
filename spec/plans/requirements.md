# Requirements — Next.js Modernization

## Intent Analysis

- **User request**: Pull the modernization plan from Helix and start the aire-helix workflow to execute it.
- **Request type**: Migration
- **Scope estimate**: System-wide (both `backend/` and `frontend/` workspaces, database access layer, auth, and deployment)
- **Complexity estimate**: Complex (4-phase migration, auth model change, ORM porting, full page/route re-platform)
- **Depth**: Comprehensive

**Source**: `spec/plans/modernization-plan.md` (Atlas Migration Strategy, document_id 3638) is the primary input. `spec/plans/atlas-deep-dive.md` (Atlas System Exploration, document_id 3627) grounds understanding of the current system. Both pulled via the Helix MCP — see provenance blocks in each file.

**Clarifying answers incorporated** (`spec/spec-generation/requirement-verification-questions.md`):
1. New app lives at `conduit-next/`, added to npm workspaces, old stack untouched until cutover.
2. JavaScript (ES Modules) throughout — no TypeScript adoption.
3. Sequelize only — no Prisma evaluation in scope.
4. Existing CSS/styling approach ported as-is — no Tailwind adoption.
5. Deployment target: Fly.io (matches the existing demo link in README.md).
6. Playwright E2E automation targets the new Next.js pages only — no regression coverage added for the old SPA.
7. Removal of `backend/` and `frontend/` is included as the final story of this epic (not a manual follow-up).

---

## Functional Requirements

### REQ-F-01: Next.js application scaffold
A new `conduit-next/` package MUST be created as an npm workspace member, running Next.js 15 (App Router), alongside the existing `backend/` and `frontend/` packages (both left untouched until cutover).

### REQ-F-02: Sequelize data layer ported into Next.js
The 4 Sequelize models (`Article`, `User`, `Tag`, `Comment`) and their associations MUST be ported verbatim from `backend/models/` into `conduit-next/lib/db/`, using a singleton connection pattern that survives Next.js dev-mode hot-reload. The existing Sequelize CLI migrations remain the schema source of truth; `sequelize.sync({ alter: true })` MUST NOT be used in the ported code path.

### REQ-F-03: Authentication via httpOnly cookies
Auth MUST move from client-side `localStorage` JWT storage to server-set `httpOnly` cookies, enforced by Next.js Middleware. The full flow — register, login, get current user, protected-route access, logout — MUST be implemented and validated before any other Route Handler is built (highest-risk change per the migration plan).

### REQ-F-04: Users & Auth API — Route Handlers
`POST /api/users` (register) and `POST /api/users/login` MUST be ported to `conduit-next/app/api/users/route.ts`, and `GET`/`PUT /api/user` to `conduit-next/app/api/user/route.ts`, preserving the existing Conduit REST API contract and error-response shape (`{ errors: { body: [...] } }`).

### REQ-F-05: Articles API — Route Handlers, with N+1 fix
All article endpoints (CRUD, favorites, comments) MUST be ported to `conduit-next/app/api/articles/[...slug]/route.ts`. The N+1 query pattern in `appendFollowers`/`appendFavorites`/`appendTagList` MUST be resolved using Sequelize `include` eager loading as part of this port — not deferred.

### REQ-F-06: Profiles & Follow API — Route Handlers
`GET/POST/DELETE /api/profiles/:username/follow` MUST be ported to `conduit-next/app/api/profiles/[username]/route.ts`.

### REQ-F-07: Tags API — Route Handler
`GET /api/tags` MUST be ported to `conduit-next/app/api/tags/route.ts`.

### REQ-F-08: Shared backend helpers ported
`backend/middleware/authentication.js`, `backend/helper/customErrors.js`, and `backend/helper/helpers.js` MUST be ported to `conduit-next/middleware.ts` + `conduit-next/lib/auth.ts`, `conduit-next/lib/errors.ts`, and `conduit-next/lib/helpers.ts` respectively.

### REQ-F-09: Page migration — Home, Article, Editor, Profile, Auth, Settings
All 6 existing page routes (Home, Article view, Article Editor, Profile, Login/SignUp, Settings) MUST be ported to Next.js App Router (`conduit-next/app/`), using React Server Components for data-fetching pages (Home, Article, Profile) and Client Components only where interactivity requires it (Editor form, auth forms, comment forms).

### REQ-F-10: UI components ported
All ~20 existing React components MUST be ported from `frontend/src/components/` to `conduit-next/components/`, preserving existing behavior and (per the clarifying answers) existing CSS/styling approach unchanged.

### REQ-F-11: Axios service layer eliminated
The 14 Axios service files under `frontend/src/services/` MUST be eliminated. Server Components fetch data directly; Client Components use Server Actions or `fetch` against the new Route Handlers.

### REQ-F-12: Auth and Feed state re-architected for App Router
`AuthContext` MUST be replaced with cookie-based session resolution (server-side session read, e.g. via `middleware.ts` / a server helper). `FeedContext` MUST be replaced with URL search params driving Server Component re-render for feed filtering (global/personal/tag).

### REQ-F-13: Production deployment to Fly.io
The cutover phase MUST produce a working Fly.io deployment of `conduit-next/`, replacing the current split deployment, matching the existing demo link's hosting target.

### REQ-F-14: Old stack decommissioned
As the final story of this epic, the `backend/` and `frontend/` directories MUST be removed from the repository, the root `package.json` workspaces updated to drop them and reference `conduit-next/` (or promote it to root), and the README updated with new setup/run instructions.

### REQ-F-15: Playwright E2E coverage of the new application
Per the mandatory Playwright Test Automation extension, E2E coverage MUST be established for the new Next.js pages (auth flow, article CRUD, feed, favorites, follow). Coverage of the old SPA is explicitly out of scope (clarifying answer Q6).

---

## Non-Functional Requirements

### REQ-NF-01: API contract parity
Every ported endpoint's JSON response shape MUST match the RealWorld API spec exactly — validated via the RealWorld Postman/HTTPie collection referenced in the migration plan's Testing Strategy, so existing consumers of the API are not broken.

### REQ-NF-02: No data migration / in-place DB retention
The PostgreSQL database MUST NOT be migrated, transformed, or moved. Schema and data stay exactly as they are; only the application layer changes.

### REQ-NF-03: Security — auth cookie hardening
Session cookies MUST set `Secure`, `HttpOnly`, and `SameSite` attributes per SECURITY-12 (Security Baseline, always-mandatory extension). JWTs MUST be validated server-side on every request with a pinned signature algorithm (no `alg: none`) per SECURITY-08.

### REQ-NF-04: Test coverage on migrated code
Unit test coverage on all new/ported `conduit-next/` code MUST meet `unitTestCoverageMin` from `tests/.evals/config.json` (framework-standard gate — no separate threshold introduced by this migration).

### REQ-NF-05: Rollback safety per phase
Each phase MUST preserve a working rollback path: Phase 0 = delete `conduit-next/`; Phase 1-2 = old stack remains live and untouched; Phase 3 = git branch with the old stack retrievable, plus a `pg_dump` backup taken immediately before cutover.

### REQ-NF-06: No TypeScript, no ORM swap, no styling framework (explicit non-goals)
Per the clarifying answers, this migration explicitly does NOT include: TypeScript adoption, a Prisma evaluation/spike, or a Tailwind CSS adoption. These are documented non-goals, not omissions — a later story or epic MAY revisit them, but this epic's acceptance criteria must not require them.

### REQ-NF-07: Performance — N+1 elimination verified
Article list/feed responses MUST use at most 2-3 Sequelize queries per request (not 3N+1), verified via query logging during Phase 1, per the migration plan's Performance Testing section.

---

## Architectural Considerations

- **Target architecture**: Next.js 15 App Router monolith, per `modernization-plan.md` "Target Architecture" section — this is the starting point for the later `spec/plans/architecture.md` (written once, at the STOP CHECKPOINT).
- **Migration approach**: Phased Migration (Module-by-Module) — API layer first (REQ-F-02 through REQ-F-08), then frontend (REQ-F-09 through REQ-F-12), then cutover (REQ-F-13, REQ-F-14). This phase order should inform the Dependency Graph stage's `requires` edges between stories.
- **Existing-system truth**: `spec/plans/atlas-deep-dive.md` — MVC backend (routes -> controllers -> models), Active Record Sequelize models, thin Axios service layer on the frontend, Context API for auth/feed state.

## Context Project / Design References

- Context Project: none supplied (user declined both existing-knowledge and new-references at Workspace Detection).
- Design References: none named in any input so far — `## Design References` registry not created; will be created reactively per `common/design-reference-grounding.md` if the user names one later.
