> **Source**: Atlas via Helix MCP
> **Server / tool**: helix · get_solution_document_tool (Migration Strategy document)
> **Estate**: conduit-helix-test (solution_id 960)
> **Scope pulled**: whole-repo migration strategy — Next.js 15 App Router unification
> **Fetched**: 2026-09-09T06:16:42Z
> **Freshness**: document updated 2026-09-07T10:10:25Z (not re-run at fetch time)
> **Parent Epic**: none (no GitHub milestone/tracking issue provided — this brief is the Epic content; User Stories Part 3 will ask before pushing stories, and a Milestone will be created at that point)

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

Migrate **conduit-helix-test** from a decoupled React 19 SPA + Express.js 5 MVC API monorepo to a unified **Next.js 15 App Router** full-stack application. The migration eliminates the split codebase, adds server-side rendering, improves auth security (localStorage JWT → httpOnly cookies), fixes a critical N+1 query bottleneck, and provides a modern full-stack developer experience with a single `npm run dev`.

**Migration Approach:** Phased Migration (Module-by-Module) — API layer first, frontend second, clean cutover at the end
**Estimated Duration:** 8–10 calendar weeks (solo, full-time)
**Estimated Effort:** ~7 person-weeks (+25% buffer)
**Risk Level:** Medium-Low
**Total Phases:** 4 (Phase 0: Setup, Phase 1: API, Phase 2: Frontend, Phase 3: Cutover)
**Data Migration Complexity:** Minimal — PostgreSQL database retained in-place; no data movement required

**Key Recommendations:**
1. **Build and validate auth first** — The JWT→cookie migration is the highest-risk change; complete and test the full auth flow before any other Route Handler to avoid cascading issues
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
- 5 backend route files → 6 controllers → 4 Sequelize models
- 14 frontend service files (one Axios function per API endpoint)
- ~20 React components with barrel exports
- 2 React Contexts (AuthContext, FeedContext), 1 custom hook

**Integration Points:**
- Single external service: PostgreSQL database
- No third-party APIs, queues, or cloud services
- JWT auth: tokens stored in localStorage, passed as `Authorization: Token <jwt>`

**Pain Points:**
- **Split codebase friction:** Two separate codebases, two `package.json` files, two servers to run — developer experience overhead for a solo developer
- **No SSR/SEO:** Pure client-side SPA — no server-side rendering; initial page load requires full JS hydration
- **N+1 query pattern:** Article list/feed controllers call `appendFollowers`, `appendFavorites`, `appendTagList` per article in a loop — 3 extra DB queries per article
- **`sequelize.sync({ alter: true })` on every boot** — Production schema risk; alters columns on every server start
- **14 separate Axios service files** — One function per API operation; no shared Axios instance with centralized auth header injection
- **localStorage JWT** — Vulnerable to XSS; no refresh token mechanism
- **Zero meaningful test coverage** — 3 utility tests only; no route, controller, model, or component tests
- **No API spec** — No Swagger/OpenAPI documentation; consumers must reverse-engineer from code

### Modernization Drivers

**Why Migrate to Next.js:**
- **Unify the stack** — Eliminate the split monorepo; one Next.js app replaces two separate servers, one `package.json`, one deployment
- **Add SSR/SSG** — React Server Components and Next.js rendering give the Conduit app proper server-side rendering and improved SEO for article pages
- **Simplify auth** — Move from localStorage JWT to Next.js middleware + `httpOnly` cookies for better XSS protection
- **Eliminate Axios service layer** — Server Actions and Route Handlers in Next.js App Router replace the 14 frontend service files
- **Fix architectural debt** — Migration is the right moment to address N+1 queries, add proper error boundaries, and establish test coverage
- **Modern DX** — App Router file-system routing, TypeScript-ready, built-in optimizations (Image, Font, Script)

### Success Criteria

- ✅ Single Next.js application replaces both `frontend/` and `backend/` workspaces
- ✅ All 5 Conduit API resource groups (users, user, articles, profiles, tags) functional via Next.js Route Handlers
- ✅ PostgreSQL database retained; Sequelize models or equivalent ORM carry over intact
- ✅ Authentication works via Next.js middleware (JWT in httpOnly cookie or Authorization header)
- ✅ All existing pages render correctly (Home, Article, Profile, Editor, Settings, Auth)
- ✅ N+1 query pattern resolved with proper Sequelize eager loading
- ✅ `sequelize.sync({ alter: true })` removed from production path
- ✅ Test coverage established for critical flows (auth, article CRUD, feed)
- ✅ Solo developer can run the full app with a single `npm run dev`

### Constraints

- **Timeline:** Self-paced, fast — no hard deadline
- **Team:** Solo developer (1 person, all roles)
- **Risk Tolerance:** Clean cutover acceptable — app can be offline during migration
- **Non-negotiables:** PostgreSQL database stays; no platform/hosting migration in scope

---

## Migration Approach Evaluation

### Recommended: Phased Migration (Module-by-Module)

**Description:** Migrate the system in discrete phases, starting with the Next.js scaffold and database layer, then migrating API routes group by group, then migrating frontend pages, and finally cutting over and decommissioning the old stack. Each phase produces a runnable, testable checkpoint.

**Why Recommended:**
- **Fits solo + fast pace:** Each phase is a focused, completable unit of work for one developer — no context-switching between old and new simultaneously
- **Clean cutover acceptable:** We don't need a live strangler pattern; the system can run in the new stack and cut over at the end of Phase 3
- **Low coupling:** The existing codebase has clean separation (routes → controllers → models) that maps 1:1 onto Next.js Route Handlers — phases can follow this natural boundary
- **Validates incrementally:** Each phase produces a working API and UI, so we find integration issues early rather than at final cutover

**Pros:**
- Each phase is independently testable and demoable
- Natural rollback points between phases
- Follows the grain of the existing architecture
- Builds confidence progressively (data layer → API → UI)

**Cons:**
- Requires maintaining Next.js scaffold + old codebase briefly in parallel until Phase 3 cutover
- No user-facing value until Phase 3 is complete (internal migration)

### Approaches Evaluated

| Approach | Fit | Risk | Duration | Recommended? |
|----------|-----|------|----------|--------------|
| **Phased Migration** | High | Low | 6-8 weeks | ✅ Yes |
| Strangler Fig | Medium | Low | 10-14 weeks | No |
| Big Bang | High | High | 2-3 weeks | No |
| Parallel Run | Low | Medium | 12-16 weeks | No |
| Database First | Low | Low | N/A — DB stays | No |
| API First | Medium | Medium | 8-10 weeks | No |

**Strangler Fig** — Would be ideal for a live production system needing zero downtime. Overkill here since clean cutover is acceptable; adds complexity (reverse proxy, routing logic) without benefit for a solo developer.

**Big Bang** — Tempting given solo fast pace, but the risk of integration surprises at the finish line is too high. Phased approach gives the same speed with checkpoints.

**Parallel Run** — Too much overhead for a solo developer; maintaining two full stacks simultaneously for extended periods is exhausting and error-prone.

**API First** — Could work, but since we're moving to Next.js Route Handlers (not a separate API service), this pattern adds unnecessary indirection.

---

## Target Architecture

### Target Architecture Style

**Next.js 15 App Router Monolith** — A single Next.js application that unifies the current React SPA frontend and Express.js REST API backend into one codebase, one deployment, and one `npm run dev`.

- **Frontend:** React Server Components (RSC) for data-fetching pages (Home, Article view, Profile); Client Components only where interactivity requires it (ArticleEditor, comment forms, auth forms)
- **Backend:** Next.js Route Handlers under `app/api/` replacing all Express.js routes — preserving the existing Conduit REST API contract (`/api/users`, `/api/articles`, etc.) for forward compatibility
- **Auth:** JWT carried in `httpOnly` cookies (set by Route Handlers on login/register) + Next.js Middleware for route protection — replaces localStorage JWT
- **Data Access:** Sequelize ORM retained (existing models carry over with minimal changes); N+1 queries resolved with `include` eager loading
- **Routing:** Next.js file-system routing (`app/` directory) replaces React Router DOM

**How it addresses current pain points:**

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

- **Framework:** Next.js 15 (App Router)
- **Frontend:** React 19 (Server + Client Components), Tailwind CSS (optional styling upgrade)
- **Backend:** Next.js Route Handlers (replaces Express.js), Next.js Middleware (replaces auth middleware)
- **ORM:** Sequelize 6 (retained — models port directly) OR Prisma (optional upgrade for better TypeScript support)
- **Database:** PostgreSQL (unchanged — same schema, same data)
- **Auth:** `jose` or `jsonwebtoken` for JWT, httpOnly cookies
- **Testing:** Vitest + React Testing Library + Playwright for E2E
- **Language:** TypeScript (migration is the right time to add types — optional but strongly recommended)

### Migration Architecture (Interim State)

During Phase 1 and Phase 2, both the old Express server and the new Next.js app exist in the repository:

```
conduit-helix-test/
├── backend/          ← OLD: Express server (untouched during Phase 1-2)
├── frontend/         ← OLD: React SPA (untouched during Phase 1-2)
└── conduit-next/     ← NEW: Next.js app being built
    ├── app/
    │   ├── api/      ← Route Handlers (replacing Express routes)
    │   └── (pages)/  ← App Router pages (replacing React Router)
    ├── lib/
    │   └── db/       ← Sequelize models (ported from backend/models/)
    └── middleware.ts ← Auth middleware (replacing backend/middleware/)
```

The old stack remains the live system until Phase 3 cutover. The new Next.js app is developed and tested locally in parallel. No traffic routing or proxy is needed since cutover is clean.

### Architectural Evolution Path

```
Phase 0 (Current)     Phase 1               Phase 2               Phase 3 (Target)
─────────────────     ─────────────         ─────────────         ────────────────
React SPA             Next.js scaffold      All API routes        ✅ Unified Next.js
    +             →   + DB layer        →   + all pages       →   app (old stack
Express MVC           (API routes: 0)       (API routes: 5/5)     decommissioned)
    +                 (Pages: 0/6)          (Pages: 6/6)
PostgreSQL
```

---

## Phased Migration Plan

### Phase 0: Prerequisites & Setup (Week 1)

**Scope:**
- Initialize Next.js 15 app (`conduit-next/`) alongside existing monorepo
- Configure TypeScript, ESLint, Prettier
- Set up Sequelize connection in Next.js (`lib/db/`) — copy models from `backend/models/`
- Configure environment variables for Next.js (`.env.local`)
- Set up Vitest + React Testing Library baseline
- Verify DB connection and model associations work in Next.js context

**Dependencies:** None — old stack untouched
**Effort:** ~0.5 person-weeks (solo)
**Success Criteria:**
- `next dev` runs without errors
- Sequelize connects to PostgreSQL and models load
- At least one smoke test passes

**Rollback:** Delete `conduit-next/` folder — zero impact on running system

---

### Phase 1: API Layer Migration (Weeks 2–4)

**Scope:** Port all 5 Express route groups to Next.js Route Handlers:
- POST /api/users (register), POST /api/users/login → app/api/users/route.ts
- GET/PUT /api/user → app/api/user/route.ts
- GET/POST/PUT/DELETE /api/articles + favorites + comments → app/api/articles/[...slug]/route.ts
- GET/POST/DELETE /api/profiles/:username/follow → app/api/profiles/[username]/route.ts
- GET /api/tags → app/api/tags/route.ts
- Port `backend/middleware/authentication.js` → middleware.ts + lib/auth.ts
- Port `backend/helper/customErrors.js` → lib/errors.ts
- Port `backend/helper/helpers.js` → lib/helpers.ts
- **Fix N+1:** Replace per-article enrichment loops with Sequelize `include` eager loading
- **Fix sequelize.sync:** Replace `sync({ alter: true })` with explicit `sequelize.authenticate()` only

**Dependencies:** Phase 0 complete
**Effort:** ~2 person-weeks (solo)
**Success Criteria:**
- All 20+ Conduit API endpoints respond correctly (tested with Postman/HTTPie against the RealWorld API spec)
- Auth flow works: register, login, get current user, JWT in cookie
- Article CRUD, feed, favorites, follows all functional
- N+1 queries eliminated (verify with query logging)
- Test suite covers all Route Handler groups

**Rollback:** Old Express server still running — no cutover yet; just stop developing in `conduit-next/api/`

---

### Phase 2: Frontend Page Migration (Weeks 4–7)

**Scope:** Port all 6 page routes to Next.js App Router:
- Home → app/(home)/page.tsx — Server Component fetching global/personal feed
- Article → app/article/[slug]/page.tsx — Server Component with generateStaticParams
- ArticleEditor → app/editor/page.tsx + app/editor/[slug]/page.tsx — Client Component (form)
- Profile → app/profile/[username]/page.tsx — Server Component
- Login / SignUp → app/login/page.tsx, app/register/page.tsx — Client Components
- Settings → app/settings/page.tsx — Client Component
- Port all ~20 UI components from `frontend/src/components/` → `components/`
- Replace Axios service files with direct `fetch` in Server Components + Server Actions in Client Components
- Replace `AuthContext` with cookie-based session (`getServerSession` or `auth()`)
- Replace `FeedContext` with URL search params + Server Component re-render
- Replace React Router `<Link>` with Next.js `<Link>`

**Dependencies:** Phase 1 complete (API layer working)
**Effort:** ~2.5 person-weeks (solo)
**Success Criteria:**
- All 6 pages render correctly in Next.js
- Auth persists across page navigations (cookie-based)
- Feed filtering and pagination works
- Article markdown rendering works
- No Axios dependency remaining in `conduit-next/`

**Rollback:** Old React SPA still running — pages exist in Next.js but old frontend is still live

---

### Phase 3: Cutover & Decommission (Week 8)

**Scope:**
- Final integration testing of complete Next.js app
- DNS/deployment cutover to Next.js app (Vercel, Railway, Fly.io, or existing host)
- Configure production environment variables
- Run DB migrations (ensure schema matches)
- Smoke test production deployment
- Archive and remove old `backend/` and `frontend/` directories from repo
- Update `package.json` at root — remove workspaces, point to `conduit-next/`
- Update README with new setup instructions

**Dependencies:** Phases 0–2 complete, full E2E test suite passing
**Effort:** ~0.5 person-weeks (solo)
**Success Criteria:**
- Production Next.js app fully functional
- All Conduit spec flows verified in production
- Old Express server and Vite SPA directories removed
- README updated

**Rollback:** Git branch containing old stack remains; DNS can be reverted within minutes

---

**Migration Sequence:**
```
Phase 0 (Setup) → Phase 1 (API) → Phase 2 (Frontend) → Phase 3 (Cutover) → Old stack decommissioned
Week 1             Weeks 2-4       Weeks 4-7              Week 8
```

---

## Risk Assessment & Mitigation

| Risk | Category | Likelihood | Impact | Mitigation Strategy |
|------|----------|------------|--------|---------------------|
| Sequelize model porting breaks associations | Data | M | H | Port models one at a time; write association tests before proceeding; test with real DB data |
| Next.js App Router RSC/Client Component boundary confusion | Team | H | M | Establish a clear rule: forms and interactive elements = Client; data fetching = Server; enforce via code review checklist |
| JWT cookie auth behaves differently from localStorage | Integration | M | H | Implement auth Route Handler first; test full login→protected-route flow before any page migration |
| N+1 fix introduces Sequelize `include` bugs | Data | M | M | Add query logging in dev; write integration tests comparing response shapes to Conduit API spec |
| App Router `fetch` caching causes stale data | Performance | M | M | Use `cache: 'no-store'` for user-specific and mutable data; only cache static public content |
| `sequelize.sync` removal breaks schema on first boot | Data | L | H | Replace with explicit `db:migrate` step in setup docs; test fresh DB setup from migrations before cutover |
| Component port misses Outlet/nested route behavior | Integration | M | M | Map all React Router routes to Next.js equivalents before Phase 2; use `layout.tsx` for shared layouts |
| Solo developer burnout / scope creep | Team | M | H | Timebox each phase strictly; defer TypeScript migration to post-cutover if it slows Phase 1-2 |
| Production deployment config errors | Downtime | L | H | Test full production build locally (`next build && next start`) before cutover; use preview deployment |
| Old DB migrations incompatible with Next.js Sequelize setup | Data | L | M | Test `db:migrate` against a copy of production DB before cutover |

**Top 3 Risks:**

1. **JWT auth strategy change** (Integration / High Impact) — Moving from localStorage to httpOnly cookies is the highest-risk architectural change. Any mistake here means the app appears to work but auth silently fails. **Mitigation:** Build and test the complete auth flow (register → login → get current user → protected route → logout) as the very first Route Handler; do not proceed to other routes until this is bulletproof.

2. **Sequelize association porting** (Data / High Impact) — The existing models have complex `belongsToMany` associations (Article↔User via Favorites, User↔User via Followers, Article↔Tag via TagList). A misconfigured association silently returns wrong data. **Mitigation:** Write model-level integration tests against the real dev DB before porting any controllers; compare output shapes to the Conduit API spec.

3. **RSC vs Client Component boundary confusion** (Team / Medium Impact) — App Router's Server/Client split is the biggest conceptual shift. Getting this wrong produces hydration errors and broken interactivity. **Mitigation:** Establish a simple rule before Phase 2: pages that read data = Server Components; anything with state, event handlers, or browser APIs = Client Components. Add `'use client'` as needed.

**Risk-Adjusted Migration Confidence: Medium-High** — The codebase is small (~3,500 LOC), well-structured, and has a clean 1:1 mapping between existing patterns and Next.js equivalents. The main risks are well-understood and have clear mitigations. Biggest unknowns are auth cookie behavior and App Router mental model shifts.

---

## Data Migration Plan

### Strategy

**In-Place Retention** — The PostgreSQL database is **not being migrated**. The same database, same schema, same data is used by the Next.js app from day one. This is the single greatest simplification of this migration.

- No ETL, no data transfer, no schema transformation
- Sequelize models port directly from `backend/models/` to the new `lib/db/` directory
- Existing Sequelize CLI migrations remain valid and are the source of truth for schema
- The only data change is removing `sequelize.sync({ alter: true })` from the startup path

**Timing:** The new Next.js app connects to the same DB instance from Phase 0. No migration event needed.

### Data Mapping

| Source (Current) | Target (Next.js) | Transformation |
|-----------------|------------------|----------------|
| `backend/models/Article.js` | conduit-next/lib/db/models/Article.js | Copy verbatim; update import path for Sequelize |
| `backend/models/User.js` | conduit-next/lib/db/models/User.js | Copy verbatim; update import path |
| `backend/models/Tag.js` | conduit-next/lib/db/models/Tag.js | Copy verbatim; update import path |
| `backend/models/Comment.js` | conduit-next/lib/db/models/Comment.js | Copy verbatim; update import path |
| `backend/models/index.js` | conduit-next/lib/db/index.js | Adapt Sequelize init to Next.js singleton pattern (prevent multiple connections in dev hot-reload) |
| `backend/config/config.js` | conduit-next/lib/db/config.js | Update to use process.env.DATABASE_URL or Next.js env variables |
| PostgreSQL schema (unchanged) | PostgreSQL schema (unchanged) | No transformation — same tables, same columns |

**Key Consideration — Sequelize Singleton in Next.js:**
Next.js dev mode hot-reloads the Node.js module system repeatedly. Without a singleton pattern, each hot-reload creates a new Sequelize connection pool. Pattern:
```js
// lib/db/index.js
const globalForSequelize = global as typeof global & { sequelize?: Sequelize };
export const sequelize = globalForSequelize.sequelize ?? new Sequelize(...);
if (process.env.NODE_ENV !== 'production') globalForSequelize.sequelize = sequelize;
```

### Validation Approach

Since the DB is unchanged, validation focuses on ensuring the ported models behave identically:

- ✅ **Model association tests** — Write Vitest integration tests for all 4 models before Phase 1 begins; assert that `Article.findAll({ include: [Tag, User] })` returns the expected shape
- ✅ **API response shape comparison** — For each Route Handler, compare JSON responses against the [RealWorld API spec](https://realworld-docs.netlify.app/docs/specs/backend-specs/endpoints) — this is the authoritative contract
- ✅ **Postman/HTTPie collection** — Run the full Conduit API spec test suite against the new Route Handlers before Phase 3 cutover
- ✅ **Row count sanity check** — After Phase 3 cutover, verify record counts across all tables are unchanged

### Synchronization During Migration

Not applicable — single database, no dual-write, no sync needed. The old Express server and new Next.js app can both connect to the same PostgreSQL instance during development (Phases 0–2). There is no conflict since they share the same schema.

### Data Rollback Strategy

Since data is not being moved, the rollback is entirely at the application layer:

- **Pre-cutover (Phases 0–2):** Zero data risk — old Express server remains the live system
- **Post-cutover (Phase 3):** Rollback = redeploy old Express + Vite SPA from git branch; DB is untouched so all data is intact
- **Estimated rollback time:** < 5 minutes (redeploy from existing branch + DNS)
- **Pre-cutover DB backup:** Take a full PostgreSQL `pg_dump` immediately before Phase 3 cutover as insurance

---

## Testing Strategy

### Parallel Testing Approach

**Shadow Testing** — The old Express server remains the reference implementation throughout Phases 0–2. For each Route Handler written, run both the old and new endpoints with identical requests and compare responses:

```bash
# Compare old vs new for any endpoint
curl http://localhost:3001/api/articles        # old Express
curl http://localhost:3000/api/articles        # new Next.js Route Handler
diff <(old response) <(new response)
```

Use the [RealWorld Postman collection](https://github.com/gothinkster/realworld/tree/main/api) as the canonical test suite — it covers all Conduit API endpoints with real request/response validation. Run it against the Next.js app at end of Phase 1.

### Acceptance Criteria

**Phase 1 Gate (API Layer complete):**
- [ ] All 20+ Conduit API endpoints respond correctly (verified by RealWorld Postman collection)
- [ ] Auth flow complete: register → login → get current user → protected route → logout
- [ ] Article CRUD: create, read, update, delete (with slug) working
- [ ] Feed endpoints: global feed, personal feed, tag filter, author filter, favorited filter working
- [ ] Pagination working (`limit`, `offset` query params)
- [ ] Favorites toggle (POST/DELETE) working
- [ ] Follow/unfollow toggle working
- [ ] Comments CRUD working
- [ ] Error responses match Conduit spec format `{ errors: { body: [...] } }`
- [ ] N+1 queries eliminated (verify with `logging: console.log` in Sequelize config)

**Phase 2 Gate (Frontend complete):**
- [ ] All 6 pages render without hydration errors
- [ ] Auth persists across page navigations and browser refresh
- [ ] Feed switching (Global/Your Feed/Tag) works
- [ ] Pagination works on all list views
- [ ] Article markdown renders correctly
- [ ] Article editor creates and updates articles
- [ ] Profile page shows correct articles and follow status
- [ ] Settings page updates user profile

**Phase 3 Gate (Cutover):**
- [ ] Full E2E test passes (Playwright or manual walkthrough)
- [ ] Production build compiles without errors: `next build`
- [ ] App boots and connects to DB on first start
- [ ] All Phase 1 + Phase 2 criteria pass in production environment

### Performance Testing

Since this is a solo project and the Conduit app is small (~3,500 LOC), formal load testing is not required. Focus instead on:

- **Response time sanity check** — Key pages (Home feed, Article view) should load in < 500ms in development; verify with Chrome DevTools Network tab
- **Next.js build size** — Run `next build` and check bundle sizes; the React SPA currently uses Vite, Next.js should produce similar or smaller bundles for static pages
- **DB query monitoring** — Enable Sequelize `logging: console.log` during Phase 1 to verify N+1 elimination; each article list request should use at most 2-3 queries (not 3N+1)
- **Baseline comparison** — Measure current Express API response time with `time curl http://localhost:3001/api/articles`; Next.js Route Handlers should match or beat this

### User Acceptance Testing

For a solo developer, UAT is self-directed. Use this checklist before Phase 3 cutover:

| Flow | Test | Pass? |
|------|------|-------|
| Auth | Register new user, verify JWT cookie set | ☐ |
| Auth | Login, navigate to protected pages | ☐ |
| Auth | Refresh page, stay logged in | ☐ |
| Articles | Browse global feed, paginate | ☐ |
| Articles | Filter by tag | ☐ |
| Articles | View single article with comments | ☐ |
| Articles | Create article, verify it appears in feed | ☐ |
| Articles | Edit own article | ☐ |
| Articles | Delete own article | ☐ |
| Social | Follow a user, see their articles in personal feed | ☐ |
| Social | Favorite an article, see it in profile favorites | ☐ |
| Profile | View own profile, view another user's profile | ☐ |
| Settings | Update bio, image, email | ☐ |

**Go/No-Go:** All items must pass before Phase 3 cutover.

### Per-Phase Testing Gates

| Phase | Test Focus | Acceptance Gate |
|-------|-----------|-----------------|
| Phase 0 | DB connection + model loading | Sequelize connects, models load, smoke test passes |
| Phase 1 | API Route Handler correctness | RealWorld Postman collection 100% pass |
| Phase 2 | Page rendering + UI correctness | UAT checklist 100% complete |
| Phase 3 | Production deployment | `next build` succeeds, all Phase 1+2 criteria in production |

---

## Effort & Timeline

### Effort Estimates per Phase

| Phase | Scope Summary | Effort (solo person-weeks) | Calendar Duration |
|-------|--------------|---------------------------|-------------------|
| Phase 0: Setup | Next.js scaffold, DB connection, model port | 0.5 | Week 1 |
| Phase 1: API Layer | 5 route groups → Route Handlers, auth, helpers | 2.0 | Weeks 2–4 |
| Phase 2: Frontend | 6 pages + 20 components, auth pattern, RSC/Client split | 2.5 | Weeks 4–7 |
| Phase 3: Cutover | Integration test, deploy, decommission old stack | 0.5 | Week 8 |
| **Buffer (25%)** | Unknowns, debugging, iteration | **1.4** | Distributed |
| **TOTAL** | | **~7 person-weeks** | **~8 calendar weeks** |

*Note: Phases 1 and 2 overlap slightly — Phase 2 can begin once the auth and articles API routes are stable (end of Week 3), not waiting for all of Phase 1.*

### Key Milestones

| Milestone | Target | Dependencies |
|-----------|--------|-------------|
| Next.js app boots, DB connects | End of Week 1 | Node.js 18+, PostgreSQL accessible |
| Auth Route Handlers complete | End of Week 2 | Phase 0 |
| All API Route Handlers complete | End of Week 4 | Auth complete |
| All pages rendering in Next.js | End of Week 7 | API layer stable |
| UAT checklist 100% complete | End of Week 7 | Pages complete |
| Production cutover | Week 8 | UAT sign-off |
| Old stack removed from repo | Week 8 | Cutover stable ≥ 24h |

### Resource Requirements

- **Developers:** 1 (solo — all phases)
- **Architects:** 1 (same solo developer, architecture decisions made during Phase 0)
- **QA:** 1 (same solo developer, self-testing against RealWorld spec)
- **DevOps:** 1 (same solo developer, deployment config during Phase 3)
- **DBA:** Not required — database is retained in-place

**Skills needed:**
- Next.js 15 App Router (new learning required if unfamiliar)
- React Server Components pattern (new learning required)
- Sequelize (existing knowledge carries over)
- httpOnly cookie auth with JWT (minor adaptation from existing JWT knowledge)

### Total Cost Estimate

**Total Effort:** ~7 person-weeks (solo, with 25% buffer)
**Total Duration:** ~8 calendar weeks
**Risk-adjusted estimate:** 8–10 weeks accounting for App Router learning curve and unexpected integration issues

*For a solo developer working part-time: multiply by 2–3x for calendar time.*

---

## Referenced Paths

> Drift detection manifest — tracks SOURCE files in the current repo that inform this migration strategy. Target files (conduit-next/) do not exist yet and are excluded from drift tracking.

### High Relevance

- `package.json` - Root monorepo config; migration changes this fundamentally
- `backend/index.js` - Backend entry point being replaced; contains the sequelize.sync risk
- `frontend/src/main.jsx` - Frontend entry point being replaced
- `backend/models/Article.js` - Data model being ported; complex associations
- `backend/models/User.js` - Data model being ported; follower/favorite associations
- `backend/models/Tag.js` - Data model being ported
- `backend/models/Comment.js` - Data model being ported
- `backend/controllers/articles.js` - Business logic being ported; N+1 fix target
- `frontend/src/context/AuthContext.jsx` - Auth pattern being redesigned

### Medium Relevance

- `backend/routes/articles.js` - Route structure being replaced by Route Handlers
- `backend/routes/articles/favorites.js` - Favorites sub-routes
- `backend/middleware/authentication.js` - Auth middleware being replaced by Next.js middleware
- `backend/helper/helpers.js` - Shared utilities being ported to lib/helpers
- `backend/helper/customErrors.js` - Error classes being ported
- `backend/config/config.js` - DB config being adapted for Next.js env vars
- `frontend/src/services/` - 14 Axios service files being eliminated

### Low Relevance

- `README.md` - Will need updating post-migration
- `frontend/src/components/` - UI components being reused in Next.js
- `backend/migrations/` - Sequelize migrations carried forward unchanged
- `vitest.config.js` - Test config being adapted for Next.js

---

## Metadata

- **Migration Type:** Refactor (incremental, preserve DB + business logic)
- **Recommended Approach:** Phased Migration (API Layer → Frontend → Cutover)
- **Total Phases:** 4 (Phase 0 Setup, Phase 1 API, Phase 2 Frontend, Phase 3 Cutover)
- **Estimated Duration:** 8–10 calendar weeks (solo full-time)
- **Estimated Effort:** ~7 person-weeks + 25% buffer
- **Risk Level:** Medium-Low
- **Data Migration Complexity:** Minimal (DB retained in-place, no data movement)

---

*Generated by Software Archaeology (SAR) Module - Web Platform*
