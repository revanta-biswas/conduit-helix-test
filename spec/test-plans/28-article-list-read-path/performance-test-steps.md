# Performance Test Steps — Story 1.10 Article List Read Path Under the Amended REQ-F-17

**Purpose**: Verify AC-2 — a list/feed request for a page of N articles issues a bounded number of
database queries, constant with respect to N (REQ-F-17@v2, REQ-NF-02).

**Scope**: Query count per request, measured at N=1 and N=50. The mechanism producing the bound
(Sequelize `include` eager loading or a denormalised read model) is not asserted — only the bound.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `cr-test/epic-nextjs-migration` (epic cycle) |
| This story's PR | Story 1.10's `[STORY]` PR — merged into the epic branch before execution |
| Confirm the story is in the build | `git log --oneline \| grep "Story 1.10"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING). This plan does not restate them. |
| Local base URL / port | `http://localhost:3000` |
| Local services that must be up | PostgreSQL, with Sequelize SQL logging enabled for the run |
| Test data / accounts to seed | `alice`; 1 then 50 articles, each with 2 tags and 1 favorite |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

### Measuring query count
Enable Sequelize statement logging for the run (the project's `.env.local` / db config carries the
switch — confirm the flag with the dev team if it is not already set). Count the SQL statements the
server logs while serving exactly one request: clear or mark the log immediately before the request,
issue it, then count the statements logged after the mark.

### Target
| Metric | Target |
|--------|--------|
| Queries per `GET /api/articles` (or `/feed`) | **Bounded — constant with respect to article count.** The count at N=50 must not exceed the count at N=1 by more than the fixed per-request overhead (the small, article-count-independent set of statements the read path issues regardless of page size). It must not grow by one or more per returned article. |

---

### TC-PERF-01 — Query count does not scale with article count — global list

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-17@v2, REQ-NF-02 |
| **Type** | Performance (query count) |
| **Priority** | P1 |
| **Preconditions** | Local instance running with SQL logging on; database empty of articles |
| **Test data** | `alice`; 1 article, then 49 further articles, each with 2 tags |

**Steps**
1. As `alice`, create 1 article with 2 tags.
2. Mark the server log, then `curl -s "http://localhost:3000/api/articles?limit=50"`.
3. Count the SQL statements logged for that request. Record it as **Q1**.
4. Create 49 further articles, each with 2 tags (50 total).
5. Mark the log again, then repeat the same request.
6. Count the statements. Record it as **Q50**.

**Expected result**
- Both requests return `200 OK`, the second with 50 articles.
- `Q50 - Q1` is a small constant, independent of the 49 extra articles.
- `Q50` is nowhere near `Q1 + 49` or `Q1 + 3*49` — the growth is not per-article.

**Record the numbers**
| Measurement | Value |
|-------------|-------|
| Q1 (1 article) | |
| Q50 (50 articles) | |
| Q50 − Q1 | |
| Read path chosen (from the story's code-generation plan) | |

**Pass/Fail criteria**: PASS when `Q50 - Q1` is a fixed overhead that does not scale with article
count. A difference at or near 49 (one query per extra article) or 147 (three per article) is a
FAIL — the N+1 pattern is present.
**Cleanup**: Delete all 50 articles; restore the logging setting.

---

### TC-PERF-02 — Query count does not scale with article count — personal feed

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-17@v2, REQ-NF-02 |
| **Type** | Performance (query count) |
| **Priority** | P1 |
| **Preconditions** | Local instance running with SQL logging on; `alice` follows `bob` |
| **Test data** | `bob`; 1 article, then 49 further articles, each with 2 tags |

**Steps**
1. As `alice`, `POST /api/profiles/bob/follow`.
2. As `bob`, create 1 article with 2 tags.
3. Mark the log, then as `alice` `curl -s -b jar.txt "http://localhost:3000/api/articles/feed?limit=50"`.
4. Count the statements. Record as **F1**.
5. As `bob`, create 49 further articles, each with 2 tags.
6. Mark the log, repeat the same feed request, and count. Record as **F50**.

**Expected result**
- Both requests return `200 OK`, the second with 50 articles.
- `F50 - F1` is a small constant, independent of the 49 extra articles.

**Record the numbers**
| Measurement | Value |
|-------------|-------|
| F1 (1 article) | |
| F50 (50 articles) | |
| F50 − F1 | |

**Pass/Fail criteria**: PASS when `F50 - F1` does not scale with article count. Growth of one or more
queries per returned article is a FAIL.
**Cleanup**: Unfollow `bob`; delete all 50 articles; restore the logging setting.

---

### TC-PERF-03 — Query count is bounded with viewer flags in play (boundary)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2, AC-3 / REQ-F-17@v2 |
| **Type** | Performance (query count / boundary) |
| **Priority** | P2 |
| **Preconditions** | Local instance running with SQL logging on |
| **Test data** | 50 articles across 10 authors; `alice` follows 5 of them and has favorited 25 articles |

**Steps**
1. Seed 50 articles across 10 authors, each with 2 tags.
2. As `alice`, follow 5 of the authors and favorite 25 of the articles.
3. Mark the log, then as `alice` `curl -s -b jar.txt "http://localhost:3000/api/articles?limit=50"`.
4. Count the statements. Record as **QV**.
5. Compare `QV` against `Q50` from TC-PERF-01 (the anonymous, no-favorites case).

**Expected result**
- `200 OK` with 50 articles, each carrying correct `following`, `favorited` and `favoritesCount`.
- `QV - Q50` is a small constant — the viewer's follows and favorites are resolved in a bounded number
  of statements, not one per article.

**Record the numbers**
| Measurement | Value |
|-------------|-------|
| QV (50 articles, viewer with 5 follows + 25 favorites) | |
| Q50 (from TC-PERF-01) | |
| QV − Q50 | |

**Pass/Fail criteria**: PASS when `QV - Q50` is a fixed overhead. Growth proportional to the number of
articles, follows or favorites is a FAIL.
**Cleanup**: Unfollow, unfavorite, delete the 50 articles; restore the logging setting.

---

### TC-PERF-04 — Response time for a 50-article page (boundary)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-NF-02 |
| **Type** | Performance (latency) |
| **Priority** | P3 |
| **Preconditions** | Local instance running, warmed with one prior request |
| **Test data** | The 50 articles from TC-PERF-01 |

**Steps**
1. Issue `GET /api/articles?limit=50` once to warm the process.
2. Issue it 10 more times, recording each wall-clock duration
   (`curl -s -o /dev/null -w "%{time_total}\n"`).
3. Record the median and the slowest of the 10.

**Record the numbers**
| Measurement | Value |
|-------------|-------|
| Median (10 runs) | |
| Slowest (10 runs) | |

**Expected result**
- Every request returns `200 OK` with 50 fully populated articles.
- Durations are consistent across the 10 runs, with no run an order of magnitude slower than the median.

> ⚠️ TO CONFIRM: `requirements.md` REQ-NF-02 states the bound as a query count, not a latency target,
> and no p95 latency figure is specified for the list endpoint. This case records numbers for the
> dev team rather than asserting a threshold; it fails only on a non-`200` response or a run that is
> an order of magnitude off the median.

**Pass/Fail criteria**: PASS when all 10 runs return `200 OK` with complete data and no run is an
order of magnitude slower than the median.
**Cleanup**: Delete the 50 articles.
