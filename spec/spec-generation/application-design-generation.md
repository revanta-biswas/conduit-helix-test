# Application Design Plan — Next.js Modernization

## Context Analyzed
- `spec/plans/requirements.md` (22 REQ-IDs) and `spec/plans/stories.md` (17 stories) read.
- No Context References or Design References registered — none supplied by the user, nothing to re-consult (Step 1.5 N/A).

## Plan Checklist
- [ ] Generate `components.md` section: component definitions (Route Handlers as components, page components, shared lib modules) and responsibilities
- [ ] Generate `component-methods.md` section: method/handler signatures (HTTP verb + path -> handler; component props/exports)
- [ ] Generate `services.md` section: service-layer orchestration (the `lib/` modules that Route Handlers and Server Components both call into)
- [ ] Generate `component-dependency.md` section: dependency matrix + data flow, consistent with `spec/plans/dependency-graph.yml`
- [ ] Consolidate all of the above into `spec/plans/application-design.md`

## Clarifying Questions

## Question 1
**Component Identification** — Should the ported Sequelize data-access logic be exposed to Route Handlers directly (import the model, call `.findAll()` etc. inline), or wrapped in a repository/service layer (e.g. `lib/services/articleService.js`) that Route Handlers call into?

A) Repository/service layer per resource (`lib/services/articleService.js`, `userService.js`, etc.) — Route Handlers stay thin, calling the service; matches the existing backend's `controllers/` separation from `models/`

B) Direct model access from Route Handlers — no extra layer, since the migration plan says "port Sequelize models as-is" and this keeps the diff smallest

C) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 2
**Component Methods** — For error handling, should Route Handlers use a shared error-response helper (matching the existing `backend/helper/customErrors.js` pattern), or Next.js's own `error.tsx`/thrown-`Response` conventions?

A) Shared `lib/errors.js` helper, ported from `customErrors.js`, invoked explicitly in every Route Handler's catch block — matches Story 3's AC-3 exactly and keeps the RealWorld `{ errors: { body: [...] } }` shape uniform across every endpoint

B) Next.js App Router `error.tsx` boundaries for pages, with ad-hoc `NextResponse.json(..., { status })` per Route Handler

C) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 3
**Service Layer Design** — Should Server Components (pages) call the Route Handlers via `fetch('/api/...')`, or call the service layer (Question 1's answer) directly in-process, skipping the HTTP round-trip?

A) Server Components call the service layer directly (in-process function call, no HTTP round-trip) — faster, and Next.js's own convention for co-located full-stack apps; Route Handlers exist for Client Component calls and external API compatibility only

B) Server Components always go through `fetch('/api/...')`, exactly like Client Components — keeps a single code path for all data access, simpler mental model, at the cost of an unnecessary network hop on the server

C) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 4
**Component Dependencies** — Should the ~20 ported UI components keep their current flat `frontend/src/components/` organization, or be reorganized by feature/page under `conduit-next/components/`?

A) Reorganize by feature (`components/article/`, `components/profile/`, `components/auth/`, `components/shared/`) — clearer boundaries matching the page-story split (Stories 8-13), easier to review each story's component changes in isolation

B) Keep the current flat organization, ported as-is, to minimize migration risk and diff size

C) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 5
**Design Patterns** — The migration plan's own interim-state diagram shows `lib/db/` for Sequelize models. Should `lib/` also hold the auth helpers (Question 1/2's services + Story 3's `auth.js`/`errors.js`/`helpers.js`), or should auth get its own top-level directory (e.g. `conduit-next/auth/`)?

A) Everything shared/cross-cutting lives under `lib/` (`lib/db/`, `lib/services/`, `lib/auth.js`, `lib/errors.js`, `lib/helpers.js`) — one shared-code root, matching the migration plan's own example paths

B) `auth/` gets its own top-level directory, separate from `lib/`, since auth is the highest-risk, most security-sensitive part of the migration and deserves visible separation

C) Other (please describe after [Answer]: tag below)

[Answer]: A
