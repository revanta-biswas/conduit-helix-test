# Code Generation Plan — Story 1.7: Home & Article Pages (Server Components)

**Tracker**: [#25](https://github.com/revanta-biswas/conduit-helix-test/issues/25) | **Epic**: Milestone #2 | **Branch**: story/1.7-home-article-pages
**Covers**: REQ-F-20, REQ-F-21, REQ-F-29

**Grounding**: story ACs (#1.7), architecture.md (ARCH-02 reuse N+1-free services, ARCH-03),
application-design.md (Home/Article Server Components, FeedContext -> URL params),
functional-design.md (FeedContext replaced by URL search params). Reuses articles + tags + comments
services (1.4/1.5). markdown-to-jsx (already a frontend dep) for the article body.

**Scope (user-confirmed)**: MINIMAL functional pages; Story 1.9 ports real components + CSS.

## Plan Steps
- [x] **S1 — Feed-selection resolver** (REQ-F-29) — src/lib/feed-params.js: `resolveFeed(searchParams,
  viewerPresent)` -> `{ mode: 'global'|'personal'|'tag', tag?, listQuery }` from `?feed=`/`?tag=`/
  `?page=`. Pure, unit-testable. Replaces FeedContext client state with URL-derived state.
- [x] **S2 — Home page assembler** — src/lib/services/home-page.js: `getHomePage(searchParams, viewer)`
  -> `{ articles, articlesCount, tags, mode }` composing feed-params + articles.list/feed (1.4) +
  tags.list (1.4). Reuses N+1-free services (ARCH-02).
- [x] **S3 — Article page assembler** — src/lib/services/article-page.js: `getArticlePage(slug, viewer)`
  -> `{ article, comments }` composing articles.get (1.4) + comments.list (1.5). NotFound propagates.
- [x] **S4 — Home page (Server Component)** — src/app/(home)/page.js: renders feed + FeedToggler links
  (global/personal/tag as <Link> navigations, not client state) + popular-tags sidebar + pagination links.
- [x] **S5 — Article page (Server Component)** — src/app/article/[slug]/page.js: renders the article
  (markdown body via markdown-to-jsx) + author meta + comments; not-found view on missing slug.
- [x] **S6 — Unit tests (>=90%)** — feed-params resolver (global/personal/tag/pagination), home-page
  assembler (global vs personal vs tag), article-page assembler (article+comments, not-found).
- [x] **S7 — Gherkin step defs (B1)** — bound to the resolver + the two assemblers.

## REQ/AC Trace
| Step | ACs | REQ-IDs |
|---|---|---|
| S1 | AC-3 | REQ-F-29 |
| S2 | AC-1 | REQ-F-20 |
| S3 | AC-2 | REQ-F-21 |
| S4 | AC-1,3,5 | REQ-F-20, REQ-F-29 |
| S5 | AC-2,4 | REQ-F-21 |
| S6/S7 | AC-1..5 | REQ-NF-06 |
Trace complete.

## Notes
- **No NEW API layer** (reuses 1.4/1.5 services) -> API & Contract gate N/A.
- **FeedContext eliminated** (REQ-F-29): feed selection is a URL search param, resolved server-side;
  switching feeds is a <Link> navigation (RSC re-render), not client state.
- markdown-to-jsx moved to a root/src dependency for the article body (already in frontend workspace).
