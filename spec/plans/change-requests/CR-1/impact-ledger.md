# CR-1 — Impact ledger

Epic branch: cr-test/epic-nextjs-migration @ 9c71d78 · Written: 2026-09-28T09:08:07Z · AIRE v1.0
Every row cites what proved it (CR6). Rows: 18 · uncited: 0.

---

## Walk 1 — REQ → stories (primary)

| REQ-ID | Story | Evidence |
|---|---|---|
| REQ-F-17 | 1.4 Articles API — CRUD, Feed & Tags | `spec/plans/stories.md:94` — `**Covers**: REQ-F-12 (article CRUD + feed slice), REQ-F-14, REQ-F-17, REQ-NF-02, REQ-NF-04` |
| REQ-F-17 | (no other story) | `grep -rn "REQ-F-17" spec/plans/stories.md` returns line 94 and the coverage-matrix row at line 236 only |

Coverage matrix confirmation: `spec/plans/stories.md:236` — `| REQ-F-17 | 1.4 | ✅ Full |`.

A changed REQ-ID with no covering story: none.

## Walk 2 — Story → ACs

| Story | AC | Class | Evidence |
|---|---|---|---|
| 1.4 | AC-4 | AMENDED | `spec/plans/stories.md:101` — "The N+1 enrichment pattern … is replaced with Sequelize `include` eager loading in every list/feed Route Handler" — names the mechanism the amendment widens |
| 1.4 | AC-1 | UNCHANGED | `spec/plans/stories.md:98` — names endpoints and filters, no enrichment mechanism |
| 1.4 | AC-2 | UNCHANGED | `spec/plans/stories.md:99` — CRUD, slug generation, tag association |
| 1.4 | AC-3 | UNCHANGED | `spec/plans/stories.md:100` — `GET /api/tags` |
| 1.4 | AC-5 | UNCHANGED | `spec/plans/stories.md:102` — response-shape parity, mechanism-independent |

`stories.md` carries no AC-level `AC-n → REQ-ID` breakdown for Story 1.4, so every AC was read and
judged individually; the four judged out of scope name no enrichment mechanism.

## Walk 3 — Story → code (confirmation, 3 sources)

| Source | Result |
|---|---|
| Epic-branch history | `git log --format='%H %s' origin/main..cr-test/epic-nextjs-migration` → `d302d1c [Story 1.4 / #22] Articles API: CRUD, feed, tags & N+1 fix` |
| Commit file list | `git show --stat d302d1c` → `src/lib/services/articles.js` (254 lines), `src/app/api/articles/route.js`, `src/app/api/articles/feed/route.js`, `src/lib/helpers.js` |
| Code read | `src/lib/services/articles.js:88-98` (`list()` `include` block: Tag as `tagList`, User as `author`), `:136` (`feed()` `include: includeOptions`), `:15` (`includeOptions`), `:30-68` (`buildEnrichmentContext`/`enrichPage` batched enrichment) |

Agreement: 3/3. The code implementing REQ-F-17 was read, not inferred from file names.

## Walk 4 — Story → tests and contracts

| Artifact | What it asserts | Evidence |
|---|---|---|
| `tests/unit/lib/services/articles.test.js:91-106` | bounded query count `<= 6` for a 5-article page | `it("issues a BOUNDED number of queries for a multi-article page (N+1 fix)")`; `expect(queryCount).toBeLessThanOrEqual(6)` |
| `tests/behavior/steps/story-1.4_steps.js:98-111` | query-counting step: `the global article list is requested with query counting on` | `this.result.queryCount = count` |
| `tests/behavior/steps/story-1.4_steps.js:186-187` | `the number of database queries is at most {n}` | `this.result.queryCount <= Number(n)` |
| `spec/behavior/story-1.4.feature:35-39` | `@AC-4` — "A feed page issues a bounded number of DB queries regardless of article count" | scenario body: "the number of database queries is at most 6" |
| `spec/test-plans/22-articles-api-crud-feed-tags/performance-test-steps.md:3-4,30,48,91` | TC-PERF-01, TC-PERF-02 — query count vs article count (N=1 vs N=50) | "the N+1 enrichment loop is replaced by eager `include` loading" |
| `spec/test-plans/22-articles-api-crud-feed-tags/integration-test-steps.md:139-161` | TC-INT-05 — eager-loaded list returns fully-joined objects | "the eager `include` populated all associations" |
| `tests/api/articles.route.test.js` | list/feed response shapes | in `d302d1c` file list (201 lines) |
| `spec/behavior.feature` | no scenario asserts the enrichment mechanism | `grep -n "N+1\|include\|quer" spec/behavior.feature` → no match |
| `tests/e2e/` | specs exist for stories 1.6 and 1.7 only | `ls tests/e2e/` → `24-auth-pages-session…`, `25-home-article-pages…`, `seed.spec.ts` |

## Walk 5 — Concurrency scan

| Check | Result | Evidence |
|---|---|---|
| Work units `In Development` without a merged PR | 0 | Story Tracker (git snapshot): all 9 stories `Ready for Testing`, `Merged: yes` |
| Open `ve/…` PRs on the change surface | 0 | all 9 `ve/…` branches listed by `git branch -a --merged origin/cr-test/epic-nextjs-migration` |
| Branch divergence | local 2 ahead, 0 behind origin | `git rev-list --left-right --count origin/cr-test/epic-nextjs-migration...HEAD` → `0 2` |

No story is mid-flight. No block.

---

## Architecture impact

| Artifact | Evidence | Consequence |
|---|---|---|
| `spec/plans/architecture.md:150-158` ARCH-02 | "issues a single eager-loaded query using `include`, never a per-row follow-up query"; weight 0.20 | amended by this CR; `architecture.md` 1.0.0 → 1.1.0 |
| `spec/plans/architecture.md:131` Section 9 delta row | "Single eager-loaded query via `include` — REQ-F-17/REQ-NF-02" | amended to state the outcome |
| `tests/.evals/rubrics/architecture-rubric.json:14-19` | ARCH-02 prompt mirrors the Section 10 text | regenerated from the amended Section 10 |
| `spec/plans/functional-design.md:98-122` | "N+1 Fix — Detailed Design" names `include` | design artifact of a completed stage; not rewritten — the amendment is recorded in this bundle and in `architecture.md` |

## Impact tags (CR8)

`affects_requirements: 1` · `affects_stories: 1` · `affects_shipped: true` · `code_touched: true` ·
`doc_only: false`
