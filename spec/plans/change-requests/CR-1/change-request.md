# CR-1 — REQ-F-17 no longer mandates Sequelize `include`; a denormalised read model is permitted

Mode: CHANGE REQUEST · Entry: A description
Epic: epic/nextjs-migration (LOCAL — no external tracker) · Epic branch: cr-test/epic-nextjs-migration @ 9c71d78
Written: 2026-09-28T09:07:05Z · AIRE v1.0 · Produced by: epic-change-request (CR17)

---

## 1. The change

REQ-F-17 fixed the article list/feed N+1 query pattern and named the mechanism: Sequelize `include`
eager loading. The agreement now drops that mechanism constraint. Article lists may instead read from a
single denormalised read model. The outcome REQ-F-17 exists to produce — a bounded number of queries per
list/feed request, independent of article count — is unchanged, and REQ-NF-02 continues to state it.

**Source**: inline description

## 2. Requirements — delta and versions

| REQ-ID | Class | Version | Before → After |
|---|---|---|---|
| REQ-F-17 | AMENDED | → @v2 | "replace the per-article `appendFollowers`/`appendFavorites`/`appendTagList` loop calls with Sequelize `include` eager loading" → "replace those loop calls with a bounded-query read path; either Sequelize `include` eager loading or a single denormalised read model satisfies it" |

Unchanged: 44 requirements, byte-identical — REQ-NF-02 among them (it constrains the outcome, not the
mechanism, and the amended text preserves that outcome).
Full per-requirement detail: `requirements-delta.md`.

## 3. Impact — stories, acceptance criteria and tests

| Story | Pre-run status (snapshot) | PR state (live) | AC | AC class | Route | Evidence |
|---|---|---|---|---|---|---|
| 1.4 Articles API — CRUD, Feed & Tags | Ready for Testing | PR #31 merged (`git branch --merged` lists `story/1.4-articles-api`) | AC-4 | AMENDED | CR-born → Story 1.10 | `spec/plans/stories.md:94` `**Covers**: … REQ-F-17 …` |
| 1.4 | Ready for Testing | PR #31 merged | AC-1, AC-2, AC-3, AC-5 | UNCHANGED | — | AC text names no enrichment mechanism (`spec/plans/stories.md:98-102`) |

Blocked stories: (none) — every story in the Story Tracker is `Ready for Testing` with a merged PR, and
all nine `ve/…` branches are merged into the epic branch.
Full ledger: `impact-ledger.md`.

**Impact tags** — `affects_requirements: 1` · `affects_stories: 1` · `affects_shipped: true` ·
`code_touched: true` · `doc_only: false`

## 4. Resolution — what this CR does

CR-BUILDS-STORY: 1.10

### 4a. CR-born stories (supersede a story whose code is merged)

Story 1.10 — Article list read path under the amended REQ-F-17 · Covers: REQ-F-17@v2, REQ-NF-02 ·
Supersedes: Story 1.4 (AC-4 only) · Requires: 1.4 · Enables: (none)

Acceptance criteria:

1. The article list and feed read paths (`GET /api/articles`, `GET /api/articles/feed`, including the
   `author`/`tag`/`favorited` filter variants) satisfy REQ-F-17@v2 through either Sequelize `include`
   eager loading or a single denormalised read model. The choice is recorded in the code-generation plan
   with the queries it issues.
2. A list/feed request for a page of N articles issues a bounded number of database queries, constant
   with respect to N — verified by query counting at N=1 and N=50, where the N=50 count does not exceed
   the N=1 count by more than the fixed per-request overhead.
3. Every list/feed response shape is byte-identical to the shape Story 1.4 shipped: `tagList`, `author`
   (with `following`), `favorited` and `favoritesCount` are populated on every row, with no field
   null or missing that was populated before.
4. No list/feed code path contains a `.map`/`for...of`/`forEach` loop issuing an `await` database call
   per iteration.
5. Where a denormalised read model is chosen, its refresh path keeps a list row consistent with the
   article it denormalises: an article created, updated, deleted, favorited, unfavorited or re-tagged is
   reflected in the next list/feed response for that article.

### 4b. Spec-only amendments (stories not yet started)

(none — no affected story is `Ready for Development`; the only affected story, 1.4, has merged code.)

### 4c. New stories (no story covered the requirement)

(none — REQ-F-17 is covered by Story 1.4, found via its `Covers` line.)

## 5. Test impact

### 5a. Contracts — per story: scenarios and test cases added / amended / retired

| Artifact | Action | Detail |
|---|---|---|
| `spec/behavior/story-1.10.feature` | added | 5 `@AC-n` scenarios, one per Story 1.10 AC, failure paths included |
| `spec/behavior/story-1.4.feature:35` | amended in place | `@AC-4` scenario retitled off the `include` mechanism onto the bounded-query outcome; `@amended-by-cr-1` added; `@AC-4` tag kept |
| `spec/test-plans/22-articles-api-crud-feed-tags/performance-test-steps.md` | amended | TC-PERF-01, TC-PERF-02 restated against the outcome, not the mechanism |
| `spec/test-plans/22-articles-api-crud-feed-tags/integration-test-steps.md` | amended | TC-INT-05 restated: fully-populated list rows, mechanism-independent |
| `spec/test-plans/28-article-list-read-path/` | added | Story 1.10's plan, including a "Re-verification of affected stories" section covering Story 1.4's list/feed behaviour |
| `spec/behavior.feature` | unchanged | no cross-story journey asserts the enrichment mechanism |

### 5b. Test Change Authorization list (CR10)

| File | Test | Action | Traces to |
|---|---|---|---|
| `tests/unit/lib/services/articles.test.js:91` | "issues a BOUNDED number of queries for a multi-article page (N+1 fix)" | update assertion | Story 1.4 AC-4 — AMENDED |
| `tests/behavior/steps/story-1.4_steps.js:98-111` | `the global article list is requested with query counting on` step definition | update assertion | Story 1.4 AC-4 — AMENDED |
| `tests/behavior/steps/story-1.4_steps.js:186-187` | `the number of database queries is at most {n}` step definition | update assertion | Story 1.4 AC-4 — AMENDED |
| `tests/api/articles.route.test.js` | list/feed response-shape assertions | update assertion — only if the read model changes a field's source | Story 1.4 AC-4 — AMENDED |

🔴 A test **not** on this list must pass unmodified. Every other red test is a regression fixed in the
application code. New tests may always be added.

No Playwright spec is on this list: `tests/e2e/` holds specs for stories 1.6 and 1.7 only, and neither
asserts the query mechanism.

### 5c. New tests to add (unit / API / step definitions / Playwright via playwright-implement)

- Unit: the chosen read path issues a bounded query count at N=1 and N=50 (Story 1.10 AC-2).
- Unit: every list row is fully populated — `tagList`, `author.following`, `favorited`,
  `favoritesCount` (AC-3).
- Step definitions: `tests/behavior/steps/story-1.10_steps.js` for the new feature file.
- Unit or API: read-model consistency after create / update / delete / favorite / re-tag (AC-5), only
  where a denormalised read model is chosen.
- Playwright: (none) — Story 1.10 changes no UI surface.

## 6. Implementation plan

- [ ] Step 1 — Read `spec/plans/change-requests/CR-1/change-request.md` and `spec/behavior/story-1.10.feature`; choose the read path (Sequelize `include` retained, or a denormalised read model) and record the choice with the queries it issues (REQ-F-17@v2, AC-1).
- [ ] Step 2 — Implement the chosen read path in the article list/feed code (`src/lib/services/articles.js` `list()` and `feed()`, plus `enrichPage`/`buildEnrichmentContext`), keeping every response field populated (AC-1, AC-3).
- [ ] Step 3 — Where a denormalised read model is chosen, implement its refresh path across create, update, delete, favorite, unfavorite and re-tag (AC-5).
- [ ] Step 4 — Assert no per-iteration `await` database call remains in any list/feed path (AC-4).
- [ ] Step 5 — Update exactly the tests on the Section 5b authorization list, and no others.
- [ ] Step 6 — Add the Section 5c tests, including `tests/behavior/steps/story-1.10_steps.js` (AC-2, AC-3, AC-5).
- [ ] Step 7 — Unit tests to `unitTestCoverageMin` coverage; run the full gate chain including Test Impact Reconciliation against Section 5b.

**Trace check**: Story 1.10 AC-1 (Steps 1, 2) · AC-2 (Steps 6, 7) · AC-3 (Steps 2, 6) · AC-4 (Step 4) ·
AC-5 (Steps 3, 6); Story 1.4 AC-4 AMENDED (Steps 4, 5). Every AC appears in at least one step.

## 7. Tracker, state and dependency actions on approval

- Tracker: LOCAL — Story 1.10 is recorded in `spec/plans/stories.md` and the Story Tracker with
  `Tracker ID` = `LOCAL`. No external call is made (`## Tracker` → `Type: LOCAL`,
  `Parent Epic: none`).
- Story Tracker: row for Story 1.10, `Ready for Development`, `Requires` = 1.4, `Recorded` set.
- Dependency graph: node `1.10` with `requires: ["1.4"]`; Story 1.4 gains `enables: ["1.10"]`.
- Affected story record: Story 1.4's entry in `stories.md` carries the CR-1 annotation on AC-4.
- Epic status: not applicable — `Parent Epic: none`, so no Epic transition is made.

## 8. Warnings

- Story 1.4's merged code is the current list/feed implementation and stays in place until Story 1.10
  builds. The amendment permits a new mechanism; it does not remove the shipped one.
- ARCH-02 as written scores 0 for any list method not using `include`, so it is amended here and
  `tests/.evals/rubrics/architecture-rubric.json` is regenerated from Section 10. Without that, the J1
  gate would fail Story 1.10 for doing what this CR authorises.
- `spec/test-plans/22-articles-api-crud-feed-tags/performance-test-steps.md:30` carries an unresolved
  `TO CONFIRM` on the exact bounded-query ceiling. Story 1.10 AC-2 states the check as a comparison
  between N=1 and N=50 rather than a fixed ceiling, so the amendment does not depend on that value being
  resolved.

## 9. Decisions & assumptions — made by the framework (overrule any with Request Changes)

| # | Decision | Why | Alternative not taken |
|---|---|---|---|
| 1 | REQ-F-17 classified AMENDED, not SUPERSEDED | The requirement still exists and still requires the N+1 pattern fixed; only the permitted mechanism widened | SUPERSEDED, which would withdraw the N+1 fix itself and contradict REQ-NF-02, untouched by this change |
| 2 | REQ-NF-02 left UNCHANGED and unversioned | It constrains the outcome (bounded queries per request), not the mechanism, and the amended text preserves that outcome | Amending it alongside, which would mint a version over byte-identical text (RV-5) |
| 3 | Story 1.10 is CR-born rather than amending Story 1.4 in place | Story 1.4's code is merged (PR #31, branch merged into the epic branch) | A spec-only amendment of Story 1.4, barred by CR9 for a story with merged code |
| 4 | ARCH-02 amended and the rubric regenerated; `architecture.md` 1.0.0 → 1.1.0 | ARCH-02 scores 0 for any list method without `include`, so a denormalised read model would fail J1 on the change that authorised it | Leaving ARCH-02 as written, which would make Story 1.10 unbuildable |
| 5 | The read model's shape, refresh strategy and consistency window are left to `dev-implement`, with AC-2 asserting the bounded-query outcome | The amendment widens the permitted mechanism; fixing one design here would re-close it | Specifying a materialised view or a denormalised column set in this bundle |
| 6 | Story 1.4 AC-4 is amended off the mechanism onto the outcome, and its ACs 1, 2, 3, 5 are left UNCHANGED | Only AC-4 names `include`; the others name endpoints, slugs, tags and response shapes | Classifying all five ACs AMENDED, which would over-count the route (Phase 8 check (a)) |
| 7 | Unit, API and step-definition tests are named on the Section 5b list, not edited here | Updating them before the code that makes them correct exists would leave the epic branch red with no way to tell an authorised amendment from a break | Amending them in this commit alongside the specs |
| 8 | Story 1.10 `requires` 1.4 | It replaces part of 1.4's contract and builds on the code 1.4 merged | `requires: []`, which would permit 1.10 to build before the code it amends exists |

## 10. Revision log

| # | When | What changed | Trigger |
|---|---|---|---|
| 1 | 2026-09-28T09:07:05Z | Initial staging | Run start |
