# Code Review — Story 1.4: Articles API (CRUD, Feed & Tags) (v1)

**Tracker**: [#22](https://github.com/revanta-biswas/conduit-helix-test/issues/22) | **Epic**: Milestone #2 | **Branch**: story/1.4-articles-api
**Reviewer**: automated (dev-implement Section A) — read-only
**Covers**: REQ-F-12, REQ-F-14, REQ-F-17, REQ-NF-02, REQ-NF-04

## Verdict: ✅ CLEAN — all ACs Met, 0 🔴, 0 🟠

| AC | Requirement | Status | Evidence |
|---|---|---|---|
| AC-1 | Global/personal feed + filters + pagination | ✅ | articles.list/feed; unit + API + B1 |
| AC-2 | Full article CRUD by slug | ✅ | create/get/update/del; author-authz tests; B1 |
| AC-3 | Tags endpoint | ✅ | tags.list; GET /api/tags 200; B1 |
| AC-4 | **N+1 eliminated** | ✅ | eager load + batched enrichment; **query-count test ≤6 for 5 articles**; B1 @AC-4 |
| AC-5 | Contract parity with Conduit spec | ✅ | shapes match backend/controllers/articles.js; API tests |

## Gates (cited)
- Unit 74/74 @94.27%; API-contract 10/10; B1 12/12 + B2 29/29 containerised; regression 74/74; D1–D7 clean.
- **J1=1.0** (all 6 ARCH — ARCH-02 the headline, query-count proven); **J2=1.0** (SEC-01/03/05/07). Judge claude-sonnet-5, rubric 1.0.0.

## The N+1 fix (REQ-F-17 / ARCH-02) — the core of this story
Legacy `allArticles`/`articlesFeed` looped per article calling `appendTagList`+`appendFollowers`+`appendFavorites` (~5 queries/article → 1+5N). The port:
- eager-loads `tagList` + `author` in the `findAndCountAll` (1 query),
- builds a per-page enrichment context in a bounded number of queries (favorited ids, grouped favorites counts, following ids),
- maps to Conduit shape in memory via `helpers.articleToJSON` (zero DB access).
A unit test spies on `sequelize.query` and asserts ≤6 queries for a 5-article page — the constraint is measured, not just claimed.

## Security Baseline (Phase 2.5)
No 🔴/🟠. Update/delete author-only (403); ORM parameterisation for all filters.

## Notes
- Default page `limit` set to 20 (the legacy default was 3 — a small, sensible modernisation; the frontend Story 1.7 can override via query param). Flagged for human confirmation.
- The `sequelize` re-export from articles.js exists solely so the query-count test can spy on it; it is never called at runtime and does not weaken ARCH-05.
