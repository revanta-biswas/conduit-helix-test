EPIC TICKET: https://github.com/revanta-biswas/conduit-helix-test/milestone/2 (Milestone #2 — "Epic: Next.js App Router Migration (Phases 0-2)")

# User Stories: conduit-helix-test Next.js Migration (Phases 0-2)

**Note on granularity**: Per explicit user direction ("make it under 10"), these 9 stories bundle
multiple resource groups / pages / CRUD verbs per story rather than fully SPIDR-splitting each one.
Several stories exceed the Step 1.5 hard sizing ceilings (>5 ACs, more than one scenario class) as a
deliberate, logged exception — see `spec/spec-generation/story-generation.md`.

---

## Story 1

.1: Next.js Foundation & Database Layer

**Tracker ID**: [#19](https://github.com/revanta-biswas/conduit-helix-test/issues/19)
**Requires**: none

**As a** solo developer
**I want** a working Next.js 15 App Router scaffold with the existing database layer ported over
**So that** I have a foundation to build the API and pages on, without touching the live `backend/`/`frontend/` system

**Persona**: Solo Developer

**Covers**: REQ-F-01, REQ-F-02, REQ-F-03, REQ-F-04, REQ-F-05

**Acceptance Criteria**:

1. A Next.js 15 App Router application exists under `src/`, alongside the untouched `backend/` and `frontend/` workspaces, configured with ESLint and Prettier (JavaScript, not TypeScript).
2. `src/lib/db/models/` contains `Article.js`, `User.js`, `Tag.js`, `Comment.js` ported from `backend/models/`, with all existing associations (`belongsToMany` for Favorites, Followers, TagList) intact.
3. `src/lib/db/index.js` initializes Sequelize using a singleton pattern that survives Next.js dev-mode hot-reload without creating duplicate connection pools.
4. `src/lib/db/config.js` reads DB connection settings from `.env.local` (Next.js environment variables), equivalent to `backend/config/config.js`.
5. Running `next dev` boots without errors, Sequelize connects to the existing PostgreSQL database, and at least one smoke test confirms all 4 models load with their associations queryable (e.g. `Article.findAll({ include: [Tag, User] })` returns without error).

---

## Story 1.2: Auth API — Register, Login & httpOnly Cookie Session

**Tracker ID**: [#20](https://github.com/revanta-biswas/conduit-helix-test/issues/20)
**Requires**: 1.1 (needs the DB layer/models to exist at compile time)

**As an** end user
**I want** to register and log in, with my session persisted via a secure cookie
**So that** I stay authenticated across page loads without my token being exposed to XSS

**Persona**: End User / Reader

**Covers**: REQ-F-10, REQ-F-15, REQ-F-16, REQ-F-18, REQ-NF-01, REQ-NF-03

**Acceptance Criteria**:

1. `POST /api/users` (register) and `POST /api/users/login` are implemented as Next.js Route Handlers, replacing `backend/routes/users.js` + `backend/controllers/users.js`; both set the JWT in an `httpOnly` cookie on success (never returned in a JSON body field the frontend stores in localStorage).
2. Next.js Middleware (`src/middleware.js`) + `src/lib/auth.js` verify the cookie on protected routes and attach the resolved user to the request context, replacing `backend/middleware/authentication.js`; unauthenticated requests to public endpoints still pass through (soft auth), matching current behavior.
3. The custom error class hierarchy (`MyError`, `ForbiddenError`, `NotFoundError`, `UnauthorizedError`, etc.) is ported from `backend/helper/customErrors.js` to `src/lib/errors.js`, and shared helpers (`slugify`, `appendFollowers`, `appendFavorites`, `appendTagList`) from `backend/helper/helpers.js` to `src/lib/helpers.js`, both used by this story's Route Handlers.
4. The new app's startup path calls `sequelize.authenticate()` only — `sequelize.sync({ alter: true })` is never invoked; schema is managed exclusively by the existing Sequelize CLI migrations under `backend/migrations/` (reused unchanged).
5. Full auth flow verified end-to-end: register → login → cookie is set → a subsequent request with the cookie resolves the correct user; error responses on invalid credentials match the Conduit spec format `{ errors: { body: [...] } }`.

---

## Story 1.3: User Profile API — Current User, Public Profiles & Follow

**Tracker ID**: [#21](https://github.com/revanta-biswas/conduit-helix-test/issues/21)
**Requires**: 1.2 (needs `src/lib/auth.js` middleware to enforce authentication on these endpoints)

**As an** end user
**I want** to view and update my own profile, view others' profiles, and follow/unfollow them
**So that** I can manage my identity and curate who I follow

**Persona**: End User / Reader

**Covers**: REQ-F-11, REQ-F-13

**Acceptance Criteria**:

1. `GET /api/user` and `PUT /api/user` are implemented as Route Handlers (get/update the authenticated user), replacing `backend/routes/user.js` + `backend/controllers/user.js`.
2. `GET /api/profiles/:username` returns a public profile (bio, image, following status relative to the requester), replacing the relevant part of `backend/controllers/profiles.js`.
3. `POST /api/profiles/:username/follow` and `DELETE /api/profiles/:username/follow` toggle the follow relationship via the existing `belongsToMany` self-referential association, matching the current single-controller toggle pattern.
4. All three endpoints require authentication (except viewing a public profile, which works for anonymous requests with `following: false`), enforced via the Story 1.2 auth middleware.
5. Response shapes match the existing Conduit API spec exactly (verified by comparing to the current `backend` responses for the same requests).

---

## Story 1.4: Articles API — CRUD, Feed & Tags

**Tracker ID**: [#22](https://github.com/revanta-biswas/conduit-helix-test/issues/22)
**Requires**: 1.2 (needs `src/lib/auth.js`, `src/lib/errors.js`, `src/lib/helpers.js` to exist at compile time)

**As an** author and reader
**I want** to create, read, update, delete, and browse articles (including feeds and tag filtering) with fast responses
**So that** I can manage my content and discover others' without a slow, N+1-query-laden feed

**Persona**: Author, End User / Reader

**Covers**: REQ-F-12 (article CRUD + feed slice), REQ-F-14, REQ-F-17, REQ-NF-02, REQ-NF-04

**Acceptance Criteria**:

1. `GET /api/articles` (global feed, with `author`/`tag`/`favorited`/`limit`/`offset` filters) and `GET /api/articles/feed` (personal feed) are implemented as Route Handlers, replacing the corresponding parts of `backend/controllers/articles.js`.
2. `POST /api/articles`, `GET/PUT/DELETE /api/articles/:slug` implement full article CRUD, including slug generation via the ported `slugify` helper and tag association on create/update.
3. `GET /api/tags` returns all tags, replacing the existing tags route.
4. The N+1 enrichment pattern (per-article `appendFollowers`/`appendFavorites`/`appendTagList` loop calls) is replaced with Sequelize `include` eager loading in every list/feed Route Handler; verified via query logging showing a bounded number of queries per feed request, independent of article count.
5. Every response shape (including error format `{ errors: { body: [...] } }`) matches the existing Conduit/RealWorld API spec exactly, verified by comparing old vs new responses for the same requests across create, read, update, delete, and both feed variants.

---

## Story 1.5: Favorites & Comments API

**Tracker ID**: [#23](https://github.com/revanta-biswas/conduit-helix-test/issues/23)
**Requires**: 1.4 (favorite/comment endpoints attach to the Article resource and routing this story creates)

**As a** reader
**I want** to favorite/unfavorite articles and read/add/delete comments
**So that** I can curate my favorites and participate in article discussions

**Persona**: End User / Reader, Author

**Covers**: REQ-F-12 (favorites + comments slice)

**Acceptance Criteria**:

1. `POST /api/articles/:slug/favorite` and `DELETE /api/articles/:slug/favorite` toggle the favorite relationship via the existing Article↔User `belongsToMany` association, matching the current single-controller toggle pattern, replacing `backend/controllers/favorites.js`.
2. `GET /api/articles/:slug/comments` lists comments for an article; `POST /api/articles/:slug/comments` adds one (authenticated); `DELETE /api/articles/:slug/comments/:id` removes one (author-only), replacing `backend/controllers/comments.js`.
3. Favorite count and `favorited` boolean are computed fresh on every response, matching current behavior (no stale cached counters introduced).
4. Comment deletion is restricted to the comment's own author; attempting to delete another user's comment returns a 403 matching the existing `ForbiddenError` shape.

---

## Story 1.6: Auth Pages & Session — Login, Register, Settings

**Tracker ID**: [#24](https://github.com/revanta-biswas/conduit-helix-test/issues/24)
**Requires**: 1.2 (auth API to call), 1.3 (settings page calls the profile update endpoint)

**As an** end user
**I want** to register, log in, and manage my account settings through pages that use my cookie-based session
**So that** I have the same account-management experience as today, without localStorage-based auth

**Persona**: End User / Reader

**Covers**: REQ-F-24, REQ-F-25, REQ-F-28

**Acceptance Criteria**:

1. Login (`src/app/login/page.js`) and Register (`src/app/register/page.js`) pages are implemented as Client Components, calling the Story 1.2 auth Route Handlers, replacing `frontend/src/routes/Login.jsx`.
2. Settings page (`src/app/settings/page.js`) is implemented as a Client Component, calling the Story 1.3 `PUT /api/user` endpoint to update bio, image, and email, replacing `frontend/src/routes/Settings.jsx`.
3. `AuthContext` (localStorage-based) is replaced with a cookie-based session resolution — the auth state pages/components consume is read from the server-verified cookie (via the Story 1.2 middleware/lib), never from `localStorage`.
4. Session persists across page navigation and browser refresh without requiring re-login, verified manually per the Migration Strategy's UAT checklist.
5. Logout clears the session cookie and redirects to a logged-out state, matching current logout behavior.

---

## Story 1.7: Home & Article Pages (Server Components)

**Tracker ID**: [#25](https://github.com/revanta-biswas/conduit-helix-test/issues/25)
**Requires**: 1.4 (feed/article API), 1.5 (comments/favorites shown on the article view)

**As a** reader
**I want** to browse the home feed and read individual articles with fast initial loads
**So that** I get the same content faster, with proper SSR

**Persona**: End User / Reader

**Covers**: REQ-F-20, REQ-F-21, REQ-F-29

**Acceptance Criteria**:

1. Home page (`src/app/(home)/page.js`) is a Server Component fetching the global/personal feed via the Story 1.4 API, replacing `frontend/src/routes/Home.jsx`, including pagination and popular-tags sidebar.
2. Article view page (`src/app/article/[slug]/page.js`) is a Server Component rendering a single article (including markdown body rendering and comments list), replacing `frontend/src/routes/Article/Article.jsx`.
3. `FeedContext` (global/personal/tag filter state) is replaced with URL search params driving Server Component re-render — switching feeds/tags is a navigation, not client state.
4. Both pages render without hydration errors and reflect the correct `favorited`/`following` state for the current session (or `false` for anonymous visitors).
5. Pagination works identically to current behavior (`limit`/`offset` query params via `react-paginate`-equivalent UI or Next.js-native pagination links).

---

## Story 1.8: Article Editor & Profile Page

**Tracker ID**: [#26](https://github.com/revanta-biswas/conduit-helix-test/issues/26)
**Requires**: 1.3 (profile API for the Profile page), 1.4 (article API for the Editor)

**As an** author
**I want** to create and edit my articles, and view my own or another user's profile
**So that** I can manage my content and see article/follower context for any user

**Persona**: Author, End User / Reader

**Covers**: REQ-F-22, REQ-F-23

**Acceptance Criteria**:

1. Article creation (`src/app/editor/page.js`) and edit (`src/app/editor/[slug]/page.js`) are implemented as Client Components calling the Story 1.4 article Route Handlers, replacing `frontend/src/routes/ArticleEditor.jsx`.
2. Profile page (`src/app/profile/[username]/page.js`) is a Server Component showing a user's own articles and favorited articles (tabbed), plus follow status and the follow/unfollow action, replacing `frontend/src/routes/Profile/Profile.jsx`.
3. Creating an article redirects to its article view page and the new article appears in the global feed and the author's profile.
4. Editing an existing article pre-fills the form with current values and persists changes correctly (verified against the Story 1.4 API's update endpoint).
5. Deleting an article from the editor removes it from all feeds and the author's profile.

---

## Story 1.9: Shared UI Components, Service Layer Elimination & Test Baseline

**Tracker ID**: [#27](https://github.com/revanta-biswas/conduit-helix-test/issues/27)
**Requires**: 1.6, 1.7, 1.8 (component port and service-layer elimination touch every page these stories built; a shared-file seed story per R1)

**As a** solo developer
**I want** all UI components ported, the Axios/React-Router dependency removed, and an automated test baseline in place
**So that** the migration is complete, maintainable, and has real test coverage instead of the near-zero coverage of the old stack

**Persona**: Solo Developer

**Covers**: REQ-F-26, REQ-F-27, REQ-F-30, REQ-F-40, REQ-NF-05, REQ-NF-06, REQ-NF-07

**Acceptance Criteria**:

1. All ~20 reusable UI components (`Navbar`, `ArticlesPreview`, `ArticlesPagination`, `FeedToggler`, `PopularTags`, `CommentList`/`CommentEditor`, `FavButton`/`FollowButton`, `ArticleMeta`/`AuthorInfo`, etc.) are ported from `frontend/src/components/` to `src/components/`, preserving existing CSS/styling as-is (no Tailwind), and are consumed by the pages built in Stories 1.6-1.8.
2. The 14 Axios service files are eliminated with no replacement dependency — all data access in `src/` uses direct `fetch` in Server Components or Server Actions in Client Components; `axios` and `react-router-dom` do not appear in `src/`'s dependency usage.
3. A Vitest + React Testing Library baseline is established under `tests/unit/` (mirroring `src/`), covering: model association tests (all 4 models), Route Handler tests for each API resource group built in Stories 1.2-1.5, and component tests for the auth forms, article editor, and feed.
4. No TypeScript files are introduced (per the confirmed JavaScript-only decision) and no Prisma dependency is added (Sequelize retained per the confirmed decision).
5. This story explicitly does NOT include Phase 3 work — no production deployment, DNS cutover, or removal of `backend/`/`frontend/` directories; those remain a manual follow-up outside this AIRE cycle (REQ-NF-07).

---

## Requirements Coverage Matrix

| REQ-ID    | Covering Stories | Status                                                |
| --------- | ---------------- | ----------------------------------------------------- |
| REQ-F-01  | 1.1              | ✅ Full                                               |
| REQ-F-02  | 1.1              | ✅ Full                                               |
| REQ-F-03  | 1.1              | ✅ Full                                               |
| REQ-F-04  | 1.1              | ✅ Full                                               |
| REQ-F-05  | 1.1              | ✅ Full                                               |
| REQ-F-10  | 1.2              | ✅ Full                                               |
| REQ-F-11  | 1.3              | ✅ Full                                               |
| REQ-F-12  | 1.4, 1.5         | ✅ Full (CRUD/feed in 1.4, favorites/comments in 1.5) |
| REQ-F-13  | 1.3              | ✅ Full                                               |
| REQ-F-14  | 1.4              | ✅ Full                                               |
| REQ-F-15  | 1.2              | ✅ Full                                               |
| REQ-F-16  | 1.2              | ✅ Full                                               |
| REQ-F-17  | 1.4              | ✅ Full                                               |
| REQ-F-18  | 1.2              | ✅ Full                                               |
| REQ-F-20  | 1.7              | ✅ Full                                               |
| REQ-F-21  | 1.7              | ✅ Full                                               |
| REQ-F-22  | 1.8              | ✅ Full                                               |
| REQ-F-23  | 1.8              | ✅ Full                                               |
| REQ-F-24  | 1.6              | ✅ Full                                               |
| REQ-F-25  | 1.6              | ✅ Full                                               |
| REQ-F-26  | 1.9              | ✅ Full                                               |
| REQ-F-27  | 1.9              | ✅ Full                                               |
| REQ-F-28  | 1.6              | ✅ Full                                               |
| REQ-F-29  | 1.7              | ✅ Full                                               |
| REQ-F-30  | 1.9              | ✅ Full                                               |
| REQ-F-40  | 1.9              | ✅ Full                                               |
| REQ-NF-01 | 1.2              | ✅ Full                                               |
| REQ-NF-02 | 1.4              | ✅ Full                                               |
| REQ-NF-03 | 1.2              | ✅ Full                                               |
| REQ-NF-04 | 1.4              | ✅ Full                                               |
| REQ-NF-05 | 1.9              | ✅ Full                                               |
| REQ-NF-06 | 1.9              | ✅ Full                                               |
| REQ-NF-07 | 1.9              | ✅ Full                                               |

**40/40 REQ-IDs fully covered by story ACs.** (Note: `requirements.md` numbers REQ-F IDs non-contiguously by section — 01-05, 10-18, 20-30, 40 — for readability; all 26 functional + 7 non-functional = 33 distinct REQ-IDs are listed above, all covered.)

## Granularity Check Outcome

**9 stories, 6 of 9 exceed the Step 1.5 hard sizing ceilings** (Stories 1.2, 1.4, 1.6, 1.7, 1.8, 1.9 each span more than one scenario class or bundle multiple CRUD verbs/pages). This is a **deliberate, user-directed exception** to keep the story count under 10, logged in `spec/spec-generation/story-generation.md` and `runtime-artifacts/audit.md` — not a silent violation. No further auto-splitting was applied, per the explicit user override.
