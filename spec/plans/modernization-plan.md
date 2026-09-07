> **Source**: Atlas via Helix MCP
> **Server / tool**: helix · get_solution_document_tool
> **Estate**: conduit-helix-test (solution_id 960, repo revanta-biswas/conduit-helix-test @ 5e127d8569b300e0a21dc2c20ea680da4967b1aa)
> **Scope pulled**: whole-estate migration strategy (document_id 3638, "Migration Strategy: conduit-helix-test")
> **Fetched**: 2026-09-07T10:11:36Z
> **Freshness**: Atlas document version 25, last updated 2026-09-07T10:10:25Z

# Migration Strategy: conduit-helix-test

**Created:** 2026-09-07
**For:** Revanta
**Status:** COMPLETE
**Steps Completed:** 11 of 11

**Strategy Scope:**
- **Migration Type:** Refactor (incremental, keep pieces working)
- **Target Architecture:** Next.js App Router monolith (frontend + backend unified)
- **Business Constraints:** Solo developer, fast pace, clean cutover acceptable

---

## Executive Summary

Migrate **conduit-helix-test** from a decoupled React 19 SPA + Express.js 5 MVC API monorepo to a unified **Next.js 15 App Router** full-stack application. The migration eliminates the split codebase, adds server-side rendering, improves auth security (localStorage JWT -> httpOnly cookies), fixes a critical N+1 query bottleneck, and provides a modern full-stack developer experience with a single `npm run dev`.

**Migration Approach:** Phased Migration (Module-by-Module) — API layer first, frontend second, clean cutover at the end
**Estimated Duration:** 8-10 calendar weeks (solo, full-time)
**Estimated Effort:** ~7 person-weeks (+25% buffer)
**Risk Level:** Medium-Low
**Total Phases:** 4 (Phase 0: Setup, Phase 1: API, Phase 2: Frontend, Phase 3: Cutover)
**Data Migration Complexity:** Minimal — PostgreSQL database retained in-place; no data movement required

**Key Recommendations:**
1. **Build and validate auth first** — The JWT->cookie migration is the highest-risk change; complete and test the full auth flow before any other Route Handler to avoid cascading issues
2. **Port Sequelize models as-is** — Don't switch to Prisma during migration; the existing models work and migration is risky enough without an ORM swap; evaluate Prisma post-migration
3. **Resolve N+1 in Phase 1** — Fixing `appendFollowers`/`appendFavorites`/`appendTagList` loops with Sequelize `include` eager loading while writing Route Handlers is low-effort and high-value; don't defer it

---

## Current State & Requirements

### Current System Characteristics

**Architecture:** Decoupled full-stack monorepo — React 19 SPA (frontend, port 3000) + Express.js 5 MVC REST API (backend, port 3001) + PostgreSQL via Sequelize ORM. npm workspaces monorepo with `backend/` and `frontend/` as separate packages. In production, the backend serves the frontend's static Vite build.

**Technology Stack:**
- Frontend: React 19.2.4, React Router DOM 7.x, Vite 7.3.5 + SWC, Axios 1.13.6
- Backend: Express.js 5.2.1, Sequelize 6.37.8, PostgreSQL (pg 8.20.0), JWT + bcrypt
- Testing: Vitest 4.0.18 (3 utility test files — minimal coverage)
- Build: npm workspaces monorepo

**Key Components (42 total):**
- 5 backend route files -> 6 controllers -> 4 Sequelize models
- 14 frontend service files (one Axios function per API endpoint)
- ~20 React components with barrel exports
- 2 React Contexts (AuthContext, FeedContext), 1 custom hook

**Integration Points:**
- Single external service: PostgreSQL database
- No third-party APIs, queues, or cloud services
- JWT auth: tokens stored in localStorage, passed as `Authorization: Token <jwt>`

**Pain Points:**
- Split codebase friction: two separate codebases, two `package.json` files, two servers to run
- No SSR/SEO: pure client-side SPA
- N+1 query pattern: article list/feed controllers call `appendFollowers`, `appendFavorites`, `appendTagList` per article in a loop
- `sequelize.sync({ alter: true })` on every boot — production schema risk
- 14 separate Axios service files — no shared Axios instance with centralized auth header injection
- localStorage JWT — vulnerable to XSS; no refresh token mechanism
- Zero meaningful test coverage — 3 utility tests only
- No API spec — no Swagger/OpenAPI documentation

### Modernization Drivers

- Unify the stack — one Next.js app replaces two separate servers, one `package.json`, one deployment
- Add SSR/SSG — React Server Components and Next.js rendering give proper SSR and improved SEO
- Simplify auth — move from localStorage JWT to Next.js middleware + `httpOnly` cookies
- Eliminate Axios service layer — Server Actions and Route Handlers replace the 14 frontend service files
- Fix architectural debt — address N+1 queries, add error boundaries, establish test coverage
- Modern DX — App Router file-system routing, TypeScript-ready, built-in optimizations

### Success Criteria

- Single Next.js application replaces both `frontend/` and `backend/` workspaces
- All 5 Conduit API resource groups (users, user, articles, profiles, tags) functional via Next.js Route Handlers
- PostgreSQL database retained; Sequelize models or equivalent ORM carry over intact
- Authentication works via Next.js middleware (JWT in httpOnly cookie or Authorization header)
- All existing pages render correctly (Home, Article, Profile, Editor, Settings, Auth)
- N+1 query pattern resolved with proper Sequelize eager loading
- `sequelize.sync({ alter: true })` removed from production path
- Test coverage established for critical flows (auth, article CRUD, feed)
- Solo developer can run the full app with a single `npm run dev`

### Constraints

- Timeline: self-paced, fast — no hard deadline
- Team: solo developer (1 person, all roles)
- Risk Tolerance: clean cutover acceptable — app can be offline during migration
- Non-negotiables: PostgreSQL database stays; no platform/hosting migration in scope

---

## Migration Approach Evaluation

### Recommended: Phased Migration (Module-by-Module)

Migrate in discrete phases, starting with the Next.js scaffold and database layer, then migrating API routes group by group, then frontend pages, and finally cutting over and decommissioning the old stack. Each phase produces a runnable, testable checkpoint.

| Approach | Fit | Risk | Duration | Recommended? |
|----------|-----|------|----------|--------------|
| **Phased Migration** | High | Low | 6-8 weeks | Yes |
| Strangler Fig | Medium | Low | 10-14 weeks | No |
| Big Bang | High | High | 2-3 weeks | No |
| Parallel Run | Low | Medium | 12-16 weeks | No |
| Database First | Low | Low | N/A — DB stays | No |
| API First | Medium | Medium | 8-10 weeks | No |

---

## Target Architecture

### Target Architecture Style

**Next.js 15 App Router Monolith** — a single Next.js application that unifies the current React SPA frontend and Express.js REST API backend into one codebase, one deployment, and one `npm run dev`.

- **Frontend:** React Server Components (RSC) for data-fetching pages (Home, Article view, Profile); Client Components only where interactivity requires it
- **Backend:** Next.js Route Handlers under `app/api/` replacing all Express.js routes — preserving the existing Conduit REST API contract
- **Auth:** JWT carried in `httpOnly` cookies + Next.js Middleware for route protection — replaces localStorage JWT
- **Data Access:** Sequelize ORM retained; N+1 queries resolved with `include` eager loading
- **Routing:** Next.js file-system routing (`app/` directory) replaces React Router DOM

| Pain Point | Target Solution |
|------------|-----------------|
| Split codebase (2 servers) | Single Next.js app, one `npm run dev` |
| No SSR/SEO | React Server Components for article/profile pages |
| 14 separate Axios service files | Eliminated — RSCs fetch directly; Client Components use server actions |
| localStorage JWT (XSS risk) | httpOnly cookies via Route Handlers |
| N+1 query pattern | Sequelize `include` eager loading in Route Handlers |
| `sequelize.sync` on every boot | Replaced with explicit Sequelize CLI migrations |
| Zero test coverage | Vitest + React Testing Library established in Phase 1 |
| No API spec | OpenAPI annotations or Swagger added to Route Handlers |

### Target Technology Stack

- Framework: Next.js 15 (App Router)
- Frontend: React 19 (Server + Client Components), Tailwind CSS (optional)
- Backend: Next.js Route Handlers (replaces Express.js), Next.js Middleware (replaces auth middleware)
- ORM: Sequelize 6 (retained) OR Prisma (optional post-migration upgrade)
- Database: PostgreSQL (unchanged)
- Auth: `jose` or `jsonwebtoken` for JWT, httpOnly cookies
- Testing: Vitest + React Testing Library + Playwright for E2E
- Language: TypeScript (recommended, optional)

### Migration Architecture (Interim State)

```
conduit-helix-test/
├── backend/          <- OLD: Express server (untouched during Phase 1-2)
├── frontend/         <- OLD: React SPA (untouched during Phase 1-2)
└── conduit-next/     <- NEW: Next.js app being built
    ├── app/
    │   ├── api/      <- Route Handlers (replacing Express routes)
    │   └── (pages)/  <- App Router pages (replacing React Router)
    ├── lib/
    │   └── db/       <- Sequelize models (ported from backend/models/)
    └── middleware.ts <- Auth middleware (replacing backend/middleware/)
```

### Architectural Evolution Path

```
Phase 0 (Current)     Phase 1               Phase 2               Phase 3 (Target)
React SPA             Next.js scaffold      All API routes        Unified Next.js
    +             ->   + DB layer        ->   + all pages       -> app (old stack
Express MVC            (API routes: 0)       (API routes: 5/5)    decommissioned)
    +                  (Pages: 0/6)          (Pages: 6/6)
PostgreSQL
```

---

## Phased Migration Plan

### Phase 0: Prerequisites & Setup (Week 1)

**Scope:** Initialize Next.js 15 app (`conduit-next/`) alongside existing monorepo; configure TypeScript/ESLint/Prettier; set up Sequelize connection in Next.js (`lib/db/`), copying models from `backend/models/`; configure env vars; set up Vitest + React Testing Library baseline; verify DB connection and model associations.

**Effort:** ~0.5 person-weeks | **Rollback:** delete `conduit-next/` — zero impact on running system

### Phase 1: API Layer Migration (Weeks 2-4)

**Scope:** Port all 5 Express route groups to Next.js Route Handlers:
- POST /api/users (register), POST /api/users/login -> app/api/users/route.ts
- GET/PUT /api/user -> app/api/user/route.ts
- GET/POST/PUT/DELETE /api/articles + favorites + comments -> app/api/articles/[...slug]/route.ts
- GET/POST/DELETE /api/profiles/:username/follow -> app/api/profiles/[username]/route.ts
- GET /api/tags -> app/api/tags/route.ts
- Port `backend/middleware/authentication.js` -> middleware.ts + lib/auth.ts
- Port `backend/helper/customErrors.js` -> lib/errors.ts
- Port `backend/helper/helpers.js` -> lib/helpers.ts
- Fix N+1: replace per-article enrichment loops with Sequelize `include` eager loading
- Fix sequelize.sync: replace `sync({ alter: true })` with explicit `sequelize.authenticate()` only

**Effort:** ~2 person-weeks | **Rollback:** old Express server still running — no cutover yet

### Phase 2: Frontend Page Migration (Weeks 4-7)

**Scope:** Port all 6 page routes to Next.js App Router (Home, Article, ArticleEditor, Profile, Login/SignUp, Settings); port ~20 UI components; replace Axios service files with direct `fetch` in Server Components + Server Actions; replace `AuthContext` with cookie-based session; replace `FeedContext` with URL search params; replace React Router `<Link>` with Next.js `<Link>`.

**Effort:** ~2.5 person-weeks | **Rollback:** old React SPA still running

### Phase 3: Cutover & Decommission (Week 8)

**Scope:** Final integration testing; DNS/deployment cutover; configure production env vars; run DB migrations; smoke test production; archive/remove old `backend/` and `frontend/` directories; update root `package.json`; update README.

**Effort:** ~0.5 person-weeks | **Rollback:** git branch with old stack remains; DNS revertible within minutes

---

## Risk Assessment & Mitigation

| Risk | Category | Likelihood | Impact | Mitigation Strategy |
|------|----------|------------|--------|---------------------|
| Sequelize model porting breaks associations | Data | M | H | Port models one at a time; write association tests before proceeding |
| App Router RSC/Client Component boundary confusion | Team | H | M | Establish clear rule: data fetching = Server, interactivity = Client |
| JWT cookie auth behaves differently from localStorage | Integration | M | H | Implement auth Route Handler first; test full login->protected-route flow before any page migration |
| N+1 fix introduces Sequelize `include` bugs | Data | M | M | Query logging in dev; integration tests comparing response shapes to Conduit API spec |
| App Router `fetch` caching causes stale data | Performance | M | M | Use `cache: 'no-store'` for user-specific/mutable data |
| `sequelize.sync` removal breaks schema on first boot | Data | L | H | Explicit `db:migrate` step; test fresh DB setup before cutover |
| Component port misses Outlet/nested route behavior | Integration | M | M | Map all React Router routes to Next.js equivalents before Phase 2 |
| Solo developer burnout / scope creep | Team | M | H | Timebox each phase strictly; defer TypeScript if it slows Phase 1-2 |
| Production deployment config errors | Downtime | L | H | Test full production build locally before cutover |
| Old DB migrations incompatible with Next.js Sequelize setup | Data | L | M | Test `db:migrate` against a copy of production DB before cutover |

**Top 3 Risks:**
1. **JWT auth strategy change** (Integration/High) — build and test the complete auth flow first, before any other route.
2. **Sequelize association porting** (Data/High) — write model-level integration tests before porting controllers.
3. **RSC vs Client Component boundary confusion** (Team/Medium) — establish the Server/Client rule before Phase 2.

**Risk-Adjusted Migration Confidence: Medium-High**

---

## Data Migration Plan

**Strategy: In-Place Retention** — the PostgreSQL database is not migrated. Same database, same schema, same data from day one. No ETL, no data transfer. Sequelize models port directly. Existing Sequelize CLI migrations remain the source of truth for schema. The only data-path change is removing `sequelize.sync({ alter: true })`.

**Data Mapping:** all 4 models (Article, User, Tag, Comment) copy verbatim with updated import paths; `config.js` updates to Next.js env vars; a Sequelize singleton pattern is required to survive Next.js dev-mode hot-reload.

**Validation:** model association tests, API response shape comparison against the RealWorld API spec, Postman/HTTPie collection run, row-count sanity check post-cutover.

**Rollback:** pre-cutover zero data risk (old server still live); post-cutover rollback = redeploy old stack from git branch, DB untouched; take a `pg_dump` immediately before Phase 3 as insurance.

---

## Testing Strategy

**Shadow Testing** — the old Express server remains the reference implementation through Phases 0-2; compare old vs new endpoint responses directly. Use the RealWorld Postman collection as the canonical test suite.

**Phase Gates:**
- Phase 1: all 20+ endpoints correct, full auth flow, article CRUD, feed/pagination/favorites/follow/comments working, error format matches spec, N+1 eliminated
- Phase 2: all 6 pages render without hydration errors, auth persists across navigation, feed/pagination/markdown/editor/profile/settings all work
- Phase 3: full E2E passes, `next build` succeeds, app boots and connects to DB, all prior gates hold in production

**Performance:** no formal load testing needed at this scale; sanity-check response times (<500ms dev), verify N+1 elimination via query logging, compare bundle size and baseline `curl` timing against the current Express API.

---

## Effort & Timeline

| Phase | Effort (person-weeks) | Calendar Duration |
|-------|---|---|
| Phase 0: Setup | 0.5 | Week 1 |
| Phase 1: API Layer | 2.0 | Weeks 2-4 |
| Phase 2: Frontend | 2.5 | Weeks 4-7 |
| Phase 3: Cutover | 0.5 | Week 8 |
| Buffer (25%) | 1.4 | Distributed |
| **TOTAL** | **~7 person-weeks** | **~8 calendar weeks** |

*Phases 1 and 2 overlap slightly — Phase 2 can begin once auth and articles API routes are stable (end of Week 3).*

**Resources:** solo developer covers all roles (dev, architect, QA, DevOps); no DBA required (DB retained in-place).

**Skills needed:** Next.js 15 App Router, React Server Components, Sequelize (existing knowledge carries over), httpOnly cookie auth with JWT.

---

## Referenced Paths (drift-detection manifest — source files only; `conduit-next/` targets do not exist yet)

**High Relevance:** `package.json` (root), `backend/index.js`, `frontend/src/main.jsx`, `backend/models/Article.js`, `backend/models/User.js`, `backend/models/Tag.js`, `backend/models/Comment.js`, `backend/controllers/articles.js`, `frontend/src/context/AuthContext.jsx`

**Medium Relevance:** `backend/routes/articles.js`, `backend/routes/articles/favorites.js`, `backend/middleware/authentication.js`, `backend/helper/helpers.js`, `backend/helper/customErrors.js`, `backend/config/config.js`, `frontend/src/services/`

**Low Relevance:** `README.md`, `frontend/src/components/`, `backend/migrations/`, `vitest.config.js`

---

## Metadata

- **Migration Type:** Refactor (incremental, preserve DB + business logic)
- **Recommended Approach:** Phased Migration (API Layer -> Frontend -> Cutover)
- **Total Phases:** 4
- **Estimated Duration:** 8-10 calendar weeks (solo full-time)
- **Estimated Effort:** ~7 person-weeks + 25% buffer
- **Risk Level:** Medium-Low
- **Data Migration Complexity:** Minimal (DB retained in-place, no data movement)

*Generated by Software Archaeology (SAR) Module - Web Platform*
