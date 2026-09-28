# Code Generation Plan — Story 1.5: Favorites & Comments API

**Tracker**: [#23](https://github.com/revanta-biswas/conduit-helix-test/issues/23) | **Epic**: Milestone #2 | **Branch**: story/1.5-favorites-comments-api
**Covers**: REQ-F-12 (favorites + comments slice)

**Grounding**: story ACs (#1.5), architecture.md (ARCH-01/02/04), functional-design.md (comment-delete
author-only, idempotent favorite toggle), plus backend/controllers/{favorites,comments}.js.

## Plan Steps
- [x] **S1 — Favorites service** — src/lib/services/favorites.js: `toggle(slug, viewer, favorite)` ->
  add/removeUser on the article; returns the enriched article (reuse articles.get enrichment via a
  shared helper so favorited/favoritesCount are consistent, N+1-free). Idempotent. NotFound on bad slug.
- [x] **S2 — Comments service** — src/lib/services/comments.js: `list(slug)` (eager-load author, single
  query per page — no per-row loop, ARCH-02), `create(slug, viewer, body)` (FieldRequired on empty),
  `del(slug, commentId, viewer)` (author-only ForbiddenError).
- [x] **S3 — Route Handlers** (ARCH-01):
  - src/app/api/articles/[slug]/favorite/route.js — POST/DELETE (requireSessionUser).
  - src/app/api/articles/[slug]/comments/route.js — GET (soft auth), POST (requireSessionUser).
  - src/app/api/articles/[slug]/comments/[id]/route.js — DELETE (requireSessionUser + author).
- [x] **S4 — Unit tests (>=90%)** — favorites toggle (idempotent, count), comments (list/create/delete,
  author authz, empty-body validation).
- [x] **S5 — API & Contract tests** — favorite POST/DELETE (200/401/404), comments GET (200), POST
  (201/401/422/404), DELETE (200/401/403/404).
- [x] **S6 — Gherkin step defs (B1)**.

## REQ/AC Trace
| Step | ACs | REQ-IDs |
|---|---|---|
| S1 | AC-1 | REQ-F-12 |
| S2 | AC-2, AC-4 | REQ-F-12 |
| S3 | AC-1,2,4 | REQ-F-12 |
| S4/S5 | AC-1,2,4 | REQ-NF-06 |
| S6 | AC-1..4 | contract |
Trace complete.

## Notes
- API layer present -> API & Contract gate applies.
- Comment listing eager-loads the author in one query (ARCH-02); favorite enrichment reuses the
  articles helper so favorited/favoritesCount stay N+1-free and consistent with Story 1.4.
- Comment-delete author-only is the tightened rule from functional-design.md.
