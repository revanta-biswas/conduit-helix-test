# Code Generation Plan — Story 1.4: Articles API (CRUD, Feed & Tags)

**Tracker**: [#22](https://github.com/revanta-biswas/conduit-helix-test/issues/22) | **Epic**: Milestone #2 | **Branch**: story/1.4-articles-api
**Covers**: REQ-F-12 (article CRUD + feed), REQ-F-14 (tags), REQ-F-17 (N+1 fix), REQ-NF-02, REQ-NF-04

**Grounding**: story ACs (#1.4), architecture.md (ARCH-01 handlers->service, **ARCH-02 no N+1**,
ARCH-04 contract parity), functional-design.md (N+1 detailed design, slug rules, author authz),
application-design.md (Articles Service, Tags Service, helpers include builder), plus
backend/controllers/articles.js + routes/tags.js (read directly).

## Plan Steps
- [x] **S1 — helpers.js enrichment (N+1 fix)** (REQ-F-17, REQ-NF-02, ARCH-02) — extend src/lib/helpers.js:
  `articleToJSON(article, viewer, favoriterIds, followingIds)` — assembles the Conduit article shape
  (tagList, author{following}, favorited, favoritesCount) from ALREADY-eager-loaded data + pre-batched
  id sets. 🔴 NO per-article await in a loop.
- [x] **S2 — Articles service** (REQ-F-12) — src/lib/services/articles.js:
  - `list({author,tag,favorited,limit,offset}, viewer)` — findAndCountAll with include [tagList, author],
    where-filters; ONE batched favorites query + ONE batched following query for the whole page, then map
    via articleToJSON. Returns `{ articles, articlesCount }`.
  - `feed(viewer, {limit,offset})` — articles by authors the viewer follows; same batched enrichment.
  - `create(viewer, {title,description,body,tagList})` — slugify, unique-slug check, find-or-create tags,
    associate; returns the enriched article.
  - `get(slug, viewer)` — single article, eager-loaded + enriched.
  - `update(slug, viewer, changes)` — author-only (ForbiddenError); re-slug on title change.
  - `del(slug, viewer)` — author-only; returns the deleted message.
- [x] **S3 — Tags service** (REQ-F-14) — src/lib/services/tags.js: `list()` -> `{ tags: [name,...] }`.
- [x] **S4 — Route Handlers** (ARCH-01, ARCH-04):
  - src/app/api/articles/route.js — GET (list, soft auth), POST (create, requireSessionUser).
  - src/app/api/articles/feed/route.js — GET (feed, requireSessionUser).
  - src/app/api/articles/[slug]/route.js — GET (soft auth), PUT/DELETE (requireSessionUser + author).
  - src/app/api/tags/route.js — GET.
- [x] **S5 — Unit tests (>=90%)** — articles service (list/feed/create/get/update/delete, author authz,
  slug uniqueness, N+1-free assertion via query-count), tags service.
- [x] **S6 — API & Contract tests** — every endpoint: list 200, create 201/401/422, single 200/404,
  update 200/401/403/404, delete 200/401/403, feed 200/401, tags 200.
- [x] **S7 — Gherkin step defs (B1)**.

## N+1 Fix Design (the core of this story)
Legacy: per article, 1 getTagList + appendFollowers (getAuthor+hasFollower+countFollowers) +
appendFavorites (hasUser+countUsers) = ~5 queries/article -> 1+5N.
New: eager-load tagList+author in the findAndCountAll (1 query). Then for the WHOLE page:
- one `viewer.getFavorites({attributes:[id]})` -> Set of favorited article ids;
- favoritesCount via a single grouped count (Article.count through Favorites) OR per-article count kept
  O(1) by reading the eager-loaded Favorites — here we use one grouped query;
- following: one `viewer.getFollowing({attributes:[id]})` -> Set of followed author ids.
Then map in memory. Total queries independent of N (bounded ~4), verified by a query-count test.

## REQ/AC Trace
| Step | ACs | REQ-IDs |
|---|---|---|
| S1 | AC-4 | REQ-F-17, REQ-NF-02 |
| S2 | AC-1,2,5 | REQ-F-12 |
| S3 | AC-3 | REQ-F-14 |
| S4 | AC-1..5 | REQ-F-12,14 |
| S5/S6 | AC-1..5 | REQ-NF-06, REQ-NF-04 |
| S7 | AC-1..5 | contract |
Trace complete.

## Notes
- API layer present -> API & Contract gate applies.
- ARCH-02 is the headline constraint; a unit test asserts a bounded query count for a multi-article page.
