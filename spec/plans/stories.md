EPIC TICKET: https://github.com/revanta-biswas/conduit-helix-test/milestone/1

# User Stories — Next.js Modernization

Breakdown approach: Feature-Based, mirroring the migration plan's own 4 phases. See
`spec/spec-generation/story-generation.md` for the SPIDR slicing log and story-count rationale.

---

## Story 1: Next.js application scaffold

**Tracker ID**: #1 — https://github.com/revanta-biswas/conduit-helix-test/issues/1
**Covers**: REQ-F-01

**As** the Solo Developer,
**I want** a new `conduit-next/` Next.js 15 App Router package added to the npm workspaces,
**so that** I have a running, empty foundation to build the migration on without touching `backend/` or `frontend/`.

**Acceptance Criteria**:
- AC-1: `conduit-next/` exists as an npm workspace member (root `package.json` `workspaces` includes it), running Next.js 15 with the App Router.
- AC-2: `npm run dev -w conduit-next` (or equivalent) starts the app without errors on a port that does not collide with the existing `3000`/`3001`.
- AC-3: ESLint and Prettier are configured for `conduit-next/`, consistent with the plain-JavaScript decision (REQ-NF-06) — no TypeScript config is introduced.
- AC-4: `backend/` and `frontend/` are unmodified by this story (verified by diff).

---

## Story 2: Sequelize data layer port

**Tracker ID**: #2 — https://github.com/revanta-biswas/conduit-helix-test/issues/2
**Covers**: REQ-F-02, REQ-NF-02, REQ-NF-04

**As** the Solo Developer,
**I want** the 4 Sequelize models and their associations ported into `conduit-next/lib/db/` with a hot-reload-safe singleton,
**so that** every later Route Handler story has a working, tested data layer to build on.

**Acceptance Criteria**:
- AC-1: `Article`, `User`, `Tag`, and `Comment` models are ported to `conduit-next/lib/db/models/` with all existing associations (`belongsToMany` for Favorites, Followers, TagList) intact.
- AC-2: A Sequelize connection singleton pattern is implemented so Next.js dev-mode hot-reload does not create duplicate connection pools.
- AC-3: `sequelize.sync({ alter: true })` is NOT present anywhere in the ported code path; startup uses `sequelize.authenticate()` only.
- AC-4: Model-association integration tests (Vitest) run against the real dev PostgreSQL database and assert `Article.findAll({ include: [Tag, User] })` and equivalent association queries return the expected shape.
- AC-5: The database is not migrated, transformed, or altered by this story (REQ-NF-02) — same schema, same data, verified by row-count sanity check before/after.

---

## Story 3: Cookie-based authentication

**Tracker ID**: #3 — https://github.com/revanta-biswas/conduit-helix-test/issues/3
**Covers**: REQ-F-03, REQ-F-08, REQ-NF-03

**As** Alex (a registered user) and the Solo Developer,
**I want** the JWT auth flow rebuilt on Next.js Middleware + httpOnly cookies,
**so that** sessions are no longer exposed to XSS via `localStorage`, and every later API/page story can rely on a working, validated auth foundation.

**Acceptance Criteria**:
- AC-1: `POST /api/users` (register) and `POST /api/users/login` set a JWT in an httpOnly cookie with `Secure` and `SameSite` attributes (SECURITY-12).
- AC-2: `conduit-next/middleware.ts` validates the JWT server-side on every request to a protected route, with a pinned signature algorithm (no `alg: none` accepted) (SECURITY-08).
- AC-3: `backend/middleware/authentication.js`, `backend/helper/customErrors.js`, and `backend/helper/helpers.js` are ported to `conduit-next/lib/auth.ts`... `lib/errors.ts`, `lib/helpers.ts` equivalents (matching REQ-NF-06's plain-JavaScript decision — `.js`, not `.ts`, despite the migration plan's own example paths).
- AC-4: The full flow — register, login, get current user, access a protected route, logout — is manually and automatically verified end-to-end before any other Route Handler in this epic is built (this is the migration plan's #1 risk mitigation).
- AC-5: This story is a hard prerequisite for every other API/page story that touches authenticated behavior.

---

## Story 4: Users & current-user API

**Tracker ID**: #4 — https://github.com/revanta-biswas/conduit-helix-test/issues/4
**Covers**: REQ-F-04

**As** Alex,
**I want** `GET`/`PUT /api/user` ported to a Next.js Route Handler,
**so that** I can view and update my own profile data through the new stack.

**Acceptance Criteria**:
- AC-1: `GET /api/user` returns the current authenticated user's profile, matching the existing Conduit response shape exactly (REQ-NF-01).
- AC-2: `PUT /api/user` updates the current user's email/username/bio/image/password, with the same validation rules as the existing Express controller.
- AC-3: Both endpoints return the RealWorld error format (`{ errors: { body: [...] } }`) on validation failure.
- AC-4: Request bodies are bound via an explicit field allowlist — a client cannot set `id` or other privilege-bearing fields not in the update DTO (SECURITY-08 mass-assignment protection).

---

## Story 5: Article CRUD API

**Tracker ID**: #5 — https://github.com/revanta-biswas/conduit-helix-test/issues/5
**Covers**: REQ-F-05, REQ-NF-01

**As** Alex,
**I want** article create/read-by-slug/update/delete ported to a Route Handler,
**so that** I can author and manage my own articles in the new stack.

**Acceptance Criteria**:
- AC-1: `GET/POST/PUT/DELETE` on `conduit-next/app/api/articles/[...slug]/route.ts` cover create, read-by-slug, update, and delete, matching existing response shapes.
- AC-2: Authorization is enforced server-side — only the article's author may update or delete it (object-level authorization, SECURITY-08).
- AC-3: Every response shape is validated against the RealWorld API spec via the Postman/HTTPie collection (REQ-NF-01).
- AC-4: Request bodies use an explicit field allowlist — a client cannot set `slug`, `author`, or other server-controlled fields directly (SECURITY-08 mass-assignment protection).

---

## Story 5a: Article feeds API (N+1 fix)

**Tracker ID**: #6 — https://github.com/revanta-biswas/conduit-helix-test/issues/6
**Covers**: REQ-F-05, REQ-NF-01, REQ-NF-07

**As** Alex and Anonymous Visitor,
**I want** the global/personal/tag/author feeds ported to Route Handlers with the N+1 query pattern fixed,
**so that** article browsing stays fast as content grows.

**Acceptance Criteria**:
- AC-1: The global feed, personal feed (following), tag-filtered feed, and author-filtered feed all work with `limit`/`offset` pagination matching current behavior — depends on Story 5 (the article resource these feeds list).
- AC-2: The `appendFollowers`/`appendFavorites`/`appendTagList` per-article loop is replaced with Sequelize `include` eager loading — verified via query logging to use at most 2-3 queries per feed request, not 3N+1 (REQ-NF-07).
- AC-3: Every feed response shape is validated against the RealWorld API spec via the Postman/HTTPie collection (REQ-NF-01).

---

## Story 6: Favorites & comments API

**Tracker ID**: #7 — https://github.com/revanta-biswas/conduit-helix-test/issues/7
**Covers**: REQ-F-05

**As** Alex,
**I want** article favoriting/unfavoriting and comment create/list/delete ported to Route Handlers,
**so that** the social interaction features of Conduit work in the new stack.

**Acceptance Criteria**:
- AC-1: `POST`/`DELETE` favorite-toggle endpoints work under the ported Article routes, matching existing behavior and response shape.
- AC-2: Comment `POST` (create), `GET` (list), and `DELETE` (own comment only) work under the ported Article routes.
- AC-3: Authorization is enforced server-side — a user cannot delete another user's comment (object-level authorization, SECURITY-08).
- AC-4: This story depends on Story 5 (Articles CRUD) existing, since favorites/comments are sub-resources of the article route file.

---

## Story 7: Profiles, follow, and tags API

**Tracker ID**: #8 — https://github.com/revanta-biswas/conduit-helix-test/issues/8
**Covers**: REQ-F-06, REQ-F-07

**As** Alex,
**I want** profile viewing, follow/unfollow, and the tags list ported to Route Handlers,
**so that** I can view other users' profiles, follow/unfollow authors, and browse by tag in the new stack.

**Acceptance Criteria**:
- AC-1: `GET /api/profiles/:username` returns a public profile with correct `following` status for the requesting user.
- AC-2: `POST`/`DELETE /api/profiles/:username/follow` toggle the follow relationship, matching existing behavior.
- AC-3: `GET /api/tags` returns the full distinct tag list, matching the existing response shape (thin endpoint, folded into this story rather than standalone per the SPIDR log).

---

## Story 8: Home and Article-view pages

**Tracker ID**: #9 — https://github.com/revanta-biswas/conduit-helix-test/issues/9
**Covers**: REQ-F-09, REQ-F-10, REQ-F-11

**As** Anonymous Visitor and Alex,
**I want** the Home feed page and the single-Article view page ported to Next.js Server Components,
**so that** browsing and reading articles works with server-side rendering in the new stack.

**Acceptance Criteria**:
- AC-1: `conduit-next/app/(home)/page.tsx` renders the global/personal feed as a Server Component, fetching data directly (no Axios) — depends on Story 5a (feeds).
- AC-2: `conduit-next/app/article/[slug]/page.tsx` renders a single article with its comments as a Server Component, including markdown rendering matching current output.
- AC-3: All UI components these two pages use are ported from `frontend/src/components/` with existing CSS/styling preserved as-is (REQ-NF-06 — no Tailwind).
- AC-4: No Axios service-file dependency remains in the code these two pages use (REQ-F-11).

---

## Story 9: Article editor page

**Tracker ID**: #10 — https://github.com/revanta-biswas/conduit-helix-test/issues/10
**Covers**: REQ-F-09, REQ-F-10, REQ-F-11

**As** Alex,
**I want** the article creation/editing form ported to a Next.js Client Component,
**so that** I can create and edit my own articles in the new stack.

**Acceptance Criteria**:
- AC-1: `conduit-next/app/editor/page.tsx` (create) and `conduit-next/app/editor/[slug]/page.tsx` (edit) are Client Components using Server Actions or `fetch` against Story 5/6's Route Handlers — depends on Story 5.
- AC-2: Form validation matches the existing editor's validation (title/description/body required, tag list parsing).
- AC-3: No Axios service-file dependency remains in the editor's code path.
- AC-4: This story is separated from Story 8 because the write-heavy Client Component form is an architecturally distinct pattern from the read-heavy Server Component pages (Steps/CRUD SPIDR axis).

---

## Story 10: Profile page

**Tracker ID**: #11 — https://github.com/revanta-biswas/conduit-helix-test/issues/11
**Covers**: REQ-F-09, REQ-F-10, REQ-F-11

**As** Alex and Anonymous Visitor,
**I want** the user profile page (own articles / favorited articles / follow button) ported to Next.js,
**so that** I can view any user's profile and their content in the new stack.

**Acceptance Criteria**:
- AC-1: `conduit-next/app/profile/[username]/page.tsx` renders as a Server Component, showing the user's articles and favorited articles tabs — depends on Story 7.
- AC-2: The follow/unfollow button works as a Client Component island within the otherwise server-rendered page, calling Story 7's Route Handler.
- AC-3: No Axios service-file dependency remains in this page's code path.

---

## Story 11: Auth pages (Login / SignUp)

**Tracker ID**: #12 — https://github.com/revanta-biswas/conduit-helix-test/issues/12
**Covers**: REQ-F-09, REQ-F-10, REQ-F-11, REQ-F-12 (Auth Context slice)

**As** Anonymous Visitor,
**I want** the Login and SignUp pages ported to Next.js Client Components using the new cookie-based session,
**so that** I can register and log in through the new stack.

**Acceptance Criteria**:
- AC-1: `conduit-next/app/login/page.tsx` and `conduit-next/app/register/page.tsx` are Client Components submitting to Story 3's Route Handlers — depends on Story 3.
- AC-2: `AuthContext` is replaced with cookie-based session resolution (a server helper / `middleware.ts` read) — no client-side `localStorage` JWT handling remains anywhere in `conduit-next/`.
- AC-3: Auth state persists across page navigation and a full browser refresh (cookie-based, not client state).
- AC-4: Logout clears the session cookie server-side and redirects appropriately.

---

## Story 12: Settings page

**Tracker ID**: #13 — https://github.com/revanta-biswas/conduit-helix-test/issues/13
**Covers**: REQ-F-09, REQ-F-10, REQ-F-11

**As** Alex,
**I want** the Settings page ported to Next.js,
**so that** I can update my profile (bio, image, email, password) in the new stack.

**Acceptance Criteria**:
- AC-1: `conduit-next/app/settings/page.tsx` is a Client Component form submitting to Story 4's `PUT /api/user` — depends on Story 4.
- AC-2: Field validation matches the existing Settings form.
- AC-3: No Axios service-file dependency remains in this page's code path.

---

## Story 13: Feed filtering re-architecture

**Tracker ID**: #14 — https://github.com/revanta-biswas/conduit-helix-test/issues/14
**Covers**: REQ-F-12 (Feed Context slice)

**As** Alex and Anonymous Visitor,
**I want** feed filtering (global / personal / by tag) driven by URL search params instead of React Context + client-side state,
**so that** feed selection is shareable via URL and works naturally with Server Component re-rendering.

**Acceptance Criteria**:
- AC-1: `FeedContext` is removed; feed type and tag filter are read from `searchParams` in the Home page's Server Component.
- AC-2: Switching feed tabs (Global / Your Feed / Tag) updates the URL and triggers a Server Component re-render with the new feed — depends on Story 8.
- AC-3: Pagination (`limit`/`offset`) is also URL-search-param driven, consistent with the feed-type param.
- AC-4: This is a separate story from Story 8 (Rules axis — feed-filtering is a distinct business rule from page rendering, and the URL-param re-architecture is independently reviewable as its own bounded diff).

---

## Story 14: Production cutover to Fly.io

**Tracker ID**: #15 — https://github.com/revanta-biswas/conduit-helix-test/issues/15
**Covers**: REQ-F-13, REQ-NF-05

**As** the Solo Developer,
**I want** `conduit-next/` deployed to Fly.io as the production target,
**so that** the migration reaches a live, working cutover matching the existing demo's hosting.

**Acceptance Criteria**:
- AC-1: `next build && next start` succeeds locally with production environment variables before any deploy is attempted.
- AC-2: `conduit-next/` deploys successfully to Fly.io, configured with the production `DATABASE_URL` and other required env vars.
- AC-3: A `pg_dump` backup is taken immediately before cutover (REQ-NF-05 rollback safety).
- AC-4: All Phase 1 + Phase 2 acceptance criteria (Stories 3-13) pass against the live production deployment (full UAT checklist from the migration plan).
- AC-5: Rollback path is documented and verified: redeploying the old `backend/`+`frontend/` stack from the pre-cutover git state is possible within minutes, and the database is untouched.

---

## Story 15: Decommission old stack

**Tracker ID**: #16 — https://github.com/revanta-biswas/conduit-helix-test/issues/16
**Covers**: REQ-F-14

**As** the Solo Developer,
**I want** the old `backend/` and `frontend/` directories removed and the repo updated to reflect `conduit-next/` as the only application,
**so that** the migration is fully complete with no dead code left behind.

**Acceptance Criteria**:
- AC-1: `backend/` and `frontend/` directories are removed from the repository — only after Story 14's cutover has been stable for the confirmation period the user chooses at execution time.
- AC-2: The root `package.json` `workspaces` array is updated to remove `backend`/`frontend` and reflect `conduit-next/` (or `conduit-next/` is promoted to root, per whichever layout is confirmed at implementation time).
- AC-3: `README.md` is updated with new setup/run instructions for the unified Next.js app.
- AC-4: This is the final story of the epic — depends on Story 14 (cutover) being complete.

---

## Story 16: Playwright E2E coverage of the new application

**Tracker ID**: #17 — https://github.com/revanta-biswas/conduit-helix-test/issues/17
**Covers**: REQ-F-15

**As** the Solo Developer,
**I want** Playwright end-to-end tests covering auth, article CRUD, feed, favorites, and follow on the NEW Next.js pages,
**so that** the migrated application has automated regression coverage (mandatory Playwright Test Automation extension).

**Acceptance Criteria**:
- AC-1: E2E coverage exists for: register -> login -> logout, article create/edit/delete, global/personal/tag feed browsing, favorite/unfavorite, follow/unfollow — all against `conduit-next/` pages only (no coverage of the old SPA, per clarifying answer Q6).
- AC-2: Tests run against a seeded test database, matching the project's existing Playwright Test Automation extension conventions.
- AC-3: This story depends on Stories 8-13 (the pages it exercises) being complete.

---

## Requirements Coverage Matrix

| REQ-ID | Covering Stories | Status |
|---|---|---|
| REQ-F-01 | 1 | Full |
| REQ-F-02 | 2 | Full |
| REQ-F-03 | 3 | Full |
| REQ-F-04 | 4 | Full |
| REQ-F-05 | 5, 5a, 6 | Full |
| REQ-F-06 | 7 | Full |
| REQ-F-07 | 7 | Full |
| REQ-F-08 | 3, 4 | Full |
| REQ-F-09 | 8, 9, 10, 11, 12 | Full |
| REQ-F-10 | 8, 9, 10, 11, 12 | Full |
| REQ-F-11 | 8, 9, 10, 11, 12 | Full |
| REQ-F-12 | 11, 13 | Full |
| REQ-F-13 | 14 | Full |
| REQ-F-14 | 15 | Full |
| REQ-F-15 | 16 | Full |
| REQ-NF-01 | 4, 5, 5a | Full |
| REQ-NF-02 | 2 | Full |
| REQ-NF-03 | 3 | Full |
| REQ-NF-04 | 2 (and every story's own unit-coverage gate) | Full |
| REQ-NF-05 | 14 | Full |
| REQ-NF-06 | 1, 8, 9, 10, 12 (explicit non-goal acceptance criteria) | Full |
| REQ-NF-07 | 5a | Full |

17/17 stories generated (Story 5 split into 5 and 5a during the Step 18.6 granularity check — the original bundled CRUD + feed/pagination + N+1 performance concern, 3 scenario classes, which exceeded the one-scenario-class ceiling). 22/22 REQ-IDs fully covered.
