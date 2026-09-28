# Code Generation Plan — Story 1.8: Article Editor & Profile Page

**Tracker**: [#26](https://github.com/revanta-biswas/conduit-helix-test/issues/26) | **Epic**: Milestone #2 | **Branch**: story/1.8-editor-profile-page
**Covers**: REQ-F-22, REQ-F-23

**Grounding**: story ACs (#1.8), architecture.md (ARCH-01/06), application-design.md (Editor Client
Components, Profile Server Component), plus frontend/src/routes/{ArticleEditor.jsx,Profile/}. Reuses
the Story 1.4 articles service (list with author/favorited filters) and Story 1.3 profiles service.

**Scope (user-confirmed)**: MINIMAL functional pages; Story 1.9 ports real components + CSS.

## Plan Steps
- [x] **S1 — Editor payload builder** — src/lib/editor-payload.js: `buildArticlePayload({title,description,
  body,tagList})` -> Conduit `{ article: {...} }`, tagList parsed from a comma string. Pure, unit-testable.
- [x] **S2 — Profile data assembler** — src/lib/services/profile-page.js: `getProfilePage(username, viewer)`
  -> `{ profile, articles, favorited }` by composing profiles.getProfile + articles.list({author}) +
  articles.list({favorited}). Reuses existing N+1-free services (ARCH-02); adds no new queries pattern.
- [x] **S3 — Editor pages (Client Components, minimal)**:
  - src/app/editor/page.js — create form -> POST /api/articles via client-api -> redirect to the article.
  - src/app/editor/[slug]/page.js — edit form (pre-filled) -> PUT /api/articles/:slug.
- [x] **S4 — Profile page (Server Component, minimal)** — src/app/profile/[username]/page.js: renders the
  user's articles + favorited tabs + follow status, via getProfilePage using the server session.
- [x] **S5 — Unit tests (>=90%)** — editor payload builder (tag parsing, shape), profile-page assembler
  (own articles, favorited articles, following flag, not-found).
- [x] **S6 — Gherkin step defs (B1)** — bound to the payload builder + profile-page assembler.

## REQ/AC Trace
| Step | ACs | REQ-IDs |
|---|---|---|
| S1 | AC-1 | REQ-F-22 |
| S2 | AC-2 | REQ-F-23 |
| S3 | AC-1,3,4,5 | REQ-F-22 |
| S4 | AC-2 | REQ-F-23 |
| S5/S6 | AC-1..5 | REQ-NF-06 |
Trace complete.

## Notes
- **No NEW API layer** (reuses 1.3/1.4 endpoints) -> the API & Contract gate is N/A for this story.
- Editor is a Client Component (forms); Profile is a Server Component (data fetch) — the RSC/Client
  split per architecture.md.
- Profile-page assembler composes existing services -> no new N+1 (ARCH-02 preserved).
