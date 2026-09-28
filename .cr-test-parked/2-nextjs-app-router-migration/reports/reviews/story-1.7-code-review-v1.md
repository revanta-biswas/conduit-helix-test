# Code Review — Story 1.7: Home & Article Pages (Server Components) (v1)

**Tracker**: [#25](https://github.com/revanta-biswas/conduit-helix-test/issues/25) | **Epic**: Milestone #2 | **Branch**: story/1.7-home-article-pages
**Reviewer**: automated (dev-implement Section A) — read-only · **Covers**: REQ-F-20, REQ-F-21, REQ-F-29

## Verdict: ✅ CLEAN — all ACs Met, 0 🔴, 0 🟠

| AC | Requirement | Status |
|---|---|---|
| AC-1 | Home page (feed + tags + pagination) as Server Component | ✅ src/app/(home)/page.js + home-page assembler; tests |
| AC-2 | Article view (markdown + comments) as Server Component | ✅ src/app/article/[slug]/page.js + article-page assembler; tests |
| AC-3 | FeedContext replaced by URL search params | ✅ src/lib/feed-params.js; resolver tests (global/personal/tag/pagination) |
| AC-4 | Renders correct favorited/following state | ✅ reuses the enriched articles service (viewer-aware) |
| AC-5 | Pagination via limit/offset query params | ✅ feed-params page→offset; tests |

## Gates
- Unit 136/136 @97.36%; B1 8/8 + B2 67/67 containerised; regression 136/136; D1–D7 clean. API & Contract N/A.
- **J1=1.0** (ARCH-02 assemblers stay N+1-free, 03 FeedContext eliminated, 05, 06); **J2=1.0** (SEC-05, 07). Judge claude-sonnet-5, rubric 1.0.0.

## Notes
- **FeedContext eliminated (REQ-F-29)**: feed selection is a URL search param resolved server-side; switching feeds is a `<Link>` navigation (RSC re-render), not client state.
- **RSC**: both pages are Server Components that fetch server-side — proper SSR (REQ-F-20/21).
- **Home page moved** from `src/app/page.js` (Story 1.1's placeholder) to `src/app/(home)/page.js` (the real Home). The placeholder was removed to avoid a duplicate `/` route; Story 1.1's B1 assertion was updated to accept either location (a legitimate structural change, not a weakened test) — this was the one SH-LOOP-7 B2 fix.
- **ESLint**: added `react/jsx-uses-vars` so JSX-only imports (Link, Markdown) aren't false-flagged as unused; this strictly reduces false positives (it lowered the pre-existing frontend lint count too), introducing no new findings.
- **markdown-to-jsx** XSS surface reviewed: no `dangerouslySetInnerHTML`, sanitises by default.
