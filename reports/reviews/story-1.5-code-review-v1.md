# Code Review — Story 1.5: Favorites & Comments API (v1)

**Tracker**: [#23](https://github.com/revanta-biswas/conduit-helix-test/issues/23) | **Epic**: Milestone #2 | **Branch**: story/1.5-favorites-comments-api
**Reviewer**: automated (dev-implement Section A) — read-only · **Covers**: REQ-F-12 (favorites + comments)

## Verdict: ✅ CLEAN — all ACs Met, 0 🔴, 0 🟠

| AC | Requirement | Status |
|---|---|---|
| AC-1 | Favorite/unfavorite toggle (idempotent) | ✅ favorites.toggle; count tests |
| AC-2 | Comment list/create | ✅ comments.list/create; author eager-loaded |
| AC-4 | Comment delete author-only | ✅ 403 for non-author; tests |

## Gates
- Unit 108/108 @95.72%; API 6/6; B1 9/9 + B2 46/46 containerised; regression 108/108; D1–D7 clean.
- **J1=1.0**, **J2=1.0** (SEC-01/03/05/06/07). Judge claude-sonnet-5, rubric 1.0.0.

## Notes
- **N+1-free (ARCH-02)**: favorites reuses the articles service's batched enrichment; comment listing eager-loads the author in one query (replacing the legacy per-comment `appendFollowers` loop).
- **Cross-story B2 fix**: this story surfaced (and fixed) a Gherkin step ambiguity where Story 1.3's `When "X" follows "Y"` and Story 1.4's `Given "X" follows "Y"` had identical regex — renamed 1.4's setup step to `is following` so the cumulative B2 suite is unambiguous. A B2 failure is the current story's to fix, per the workflow.
- Comment-delete author-only is the tightened rule from Functional Design.
