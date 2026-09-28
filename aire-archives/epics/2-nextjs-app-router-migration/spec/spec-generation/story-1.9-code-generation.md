# Code Generation Plan — Story 1.9: Shared UI Components, Service-Layer Elimination & Test Baseline

**Tracker**: [#27](https://github.com/revanta-biswas/conduit-helix-test/issues/27) | **Epic**: Milestone #2 | **Branch**: story/1.9-components-services-testbaseline
**Covers**: REQ-F-26, REQ-F-27, REQ-F-30, REQ-F-40, REQ-NF-05, REQ-NF-06, REQ-NF-07

**🔴 FINAL STORY OF THE EPIC** — triggers the B3 epic-scope behaviour gate (spec/behavior.feature
cross-story journeys, authored here).

**Grounding**: story ACs (#1.9), architecture.md (ARCH-06 no axios/react-router), requirements.md
(REQ-F-26/27/30, REQ-NF-05/06/07), plus frontend/src/components/* + frontend/src/{styles,index}.css.

## Plan Steps
- [x] **S1 — Port shared presentational components** (REQ-F-26) — port the reusable, presentational
  components into src/components/, converted to Next.js idioms (next/link, NOT react-router; no legacy
  service-layer coupling). Focus set (the ones the built pages use / would use): Navbar, Footer, Avatar,
  ArticleMeta, ArticleTags, ArticlesPreview, FavButton, FollowButton, PopularTags, FeedToggler,
  CommentList, BannerContainer. Preserve class names so the ported CSS applies.
- [x] **S2 — Port CSS** (REQ-F-26) — copy frontend/src/styles.css + index.css into src/app/ (imported by
  the root layout) so the ported components render with the existing look. Preserve as-is (no Tailwind).
- [x] **S3 — Wire key components into the pages** — use Navbar+Footer in the root layout; use
  ArticlesPreview/PopularTags in the Home page; ArticleMeta/CommentList in the Article page (minimal,
  proving the components work end-to-end). Keep pages functional.
- [x] **S4 — Service-layer elimination verification** (REQ-F-27, REQ-F-30, REQ-NF-05, ARCH-06) — assert
  (in a test) that NO file under src/ imports axios or react-router-dom; document the Axios-service
  elimination (all data access is fetch/Server Components/Server Actions, established across 1.2-1.8).
- [x] **S5 — Test baseline** (REQ-F-40, REQ-NF-06) — add RTL component tests for key ported components
  (Avatar, ArticleTags, ArticlesPreview, FavButton) rendering in jsdom; add the no-axios/no-react-router
  guard test. Requires a jsdom test env for component tests (separate vitest project from the node one).
- [x] **S6 — spec/behavior.feature (B3 cross-story journeys)** — author the epic-scope journeys tagged
  @REQ-<id>: register->login->create article->favorite->comment->follow author->see personal feed.
  Bound to the composed services (the real end-to-end path through the migrated backend).
- [x] **S7 — Gherkin B1 step defs** for story-1.9.feature (component-port + elimination assertions).

## REQ/AC Trace
| Step | ACs | REQ-IDs |
|---|---|---|
| S1/S2/S3 | AC-1 | REQ-F-26 |
| S4 | AC-2 | REQ-F-27, REQ-F-30, REQ-NF-05 |
| S5 | AC-3 | REQ-F-40, REQ-NF-06 |
| S4 (no TS/Prisma) | AC-4 | REQ-NF-07 |
| plan scope | AC-5 | REQ-NF-07 (no Phase 3) |
| S6/S7 | AC-1..5 | B3 + contract |
Trace complete.

## Notes
- **REQ-NF-05/F-27/F-30 already satisfied by construction**: no story ever introduced axios or
  react-router into src/ — this story adds the guard test that keeps it true and documents it.
- **jsdom**: component RTL tests need a browser-like env. Add a SECOND vitest config
  (vitest.components.config.js, environment jsdom) so the node-env suite is unaffected; install jsdom
  (this also incidentally makes the legacy frontend suite runnable, but that legacy suite stays out of
  scope — I only wire jsdom for src/ component tests).
- **B3**: authored spec/behavior.feature runs on THIS last unit only (SH-LOOP-8).
- **No Phase 3** (REQ-NF-07): backend/ and frontend/ are NOT decommissioned here.
