# Performance Test Steps — #22 Articles API — CRUD, Feed & Tags

**Purpose**: Verify AC-4's non-functional requirement (REQ-NF-02 / REQ-NF-04): the N+1 enrichment
loop is replaced by eager `include` loading, so the **number of SQL queries per feed/list request is
bounded and does NOT scale with the number of articles returned**. Also capture a response-time
comparison of the new Next.js handlers vs the old Express backend.

**Scope**: `GET /api/articles`, `GET /api/articles/feed`. Two procedures — (A) query-count vs
article-count, (B) response-time old-vs-new. Black-box: query counting uses the DATABASE's own query
log, not application source.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/nextjs-migration` (story #22 merged via PR #31) |
| This story's merged PR | https://github.com/revanta-biswas/conduit-helix-test/pull/31 |
| Confirm the story is in the build | `git log --oneline \| grep -i "1.4\|#22\|articles"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING). This plan does not restate them. |
| Local base URL / port (new) | `http://localhost:3000`, API under `/api/` |
| Old backend base URL (comparison) | `http://localhost:3001/api` |
| Local services that must be up | PostgreSQL (via Sequelize) with query logging observable |
| Test data / accounts to seed | Ability to seed exactly N articles (N=1 and N=50); User A with a personal feed |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

## Performance targets (from AC-4 / REQ-NF-02, REQ-NF-04)
| Metric | Target |
|--------|--------|
| Queries per `GET /api/articles` (or `/feed`) | **Bounded — constant with respect to article count.** The query count at N=50 must NOT be ~50x the count at N=1. A small fixed number of queries (e.g. count + main-with-includes + a handful of association loads) is acceptable; it must not grow one-or-more per returned article. `TO CONFIRM: the exact bounded ceiling the team commits to (e.g. "≤ 5 queries per list request") — REQ-NF-02 target value.` |
| New-backend response time vs old | New p95 should be **≤ the old backend's p95** (migration must not regress). `TO CONFIRM: absolute latency target from REQ-NF-04, if any (e.g. p95 < 300ms).` |

### How to enable DB query logging (observation only — pick whichever is available)
- **PostgreSQL server log**: set `log_statement = 'all'` (and `log_min_duration_statement = 0`) in
  `postgresql.conf` or via `SET`, then `tail -f` the Postgres log file during each request. Count the
  statements emitted for one request.
- **pg_stat_statements**: `SELECT sum(calls) FROM pg_stat_statements;` — snapshot before and after a
  single request; the delta is the query count for that request. (Run `SELECT pg_stat_statements_reset();`
  to zero it first.)
- If neither is available, `TO CONFIRM: how the team wants query counts observed — ask dev to expose
  Sequelize logging to a file for the test window.`

> Isolate one request: run each measured request alone with no other traffic hitting the DB, so the
> counted statements belong only to that request.

---

### TC-PERF-01 — Query count does not scale with article count (N=1 vs N=50) — global feed

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-NF-02 |
| **Type** | Performance (query-count / N+1 regression) |
| **Priority** | P1 |
| **Preconditions** | Local instance running; DB query logging enabled; ability to seed exactly N published articles, each with ≥1 tag, ≥1 author, some favorited |
| **Test data** | Two DB states: **State-1** = exactly 1 article; **State-50** = exactly 50 articles |

**Steps**
1. Reset the DB to **State-1** (1 article). Reset the query counter (`pg_stat_statements_reset()` or
   truncate the log).
2. Issue a single request: `curl -s "http://localhost:3000/api/articles?limit=50" > /dev/null`.
3. Record the number of SQL statements executed for that request → `Q1`.
4. Reset the DB to **State-50** (50 articles, `limit=50` so all are returned). Reset the counter.
5. Issue a single request: `curl -s "http://localhost:3000/api/articles?limit=50" > /dev/null`.
6. Record the number of SQL statements executed → `Q50`.
7. Compute `Q50 - Q1` and the ratio `Q50 / Q1`.

**Expected result**
- `Q50` is approximately equal to `Q1` (a small fixed additive difference at most — e.g. from a
  count query — never ~49 extra queries).
- `Q50 - Q1` is far below 50 (the old N+1 pattern would add roughly one query per article ×3 for
  followers/favorites/tags). Concretely, `Q50 - Q1` must be a small constant, not proportional to 49.
- The returned `articlesCount`/element count confirms 50 articles were actually enriched (so the low
  count is not because rows were dropped).

**Record the numbers**
| DB state | Articles returned | Query count | 
|----------|-------------------|-------------|
| State-1 | 1 | Q1 = ____ |
| State-50 | 50 | Q50 = ____ |
| Delta | — | Q50 − Q1 = ____ |
| Ratio | — | Q50 / Q1 = ____ |

**Pass/Fail criteria**: PASS if `Q50 − Q1` is a small constant independent of article count
(bounded eager loading). FAIL if the query count grows roughly linearly with article count
(N+1 pattern still present) — this is the primary AC-4 assertion.
**Cleanup**: Restore the DB to its baseline seed; disable verbose query logging.

---

### TC-PERF-02 — Query count does not scale with article count — personal feed

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-NF-02 |
| **Type** | Performance (query-count / N+1 regression) |
| **Priority** | P1 |
| **Preconditions** | As TC-PERF-01, but the seeded articles are all by authors User A FOLLOWS, so they appear in A's personal feed; DB query logging enabled |
| **Test data** | `$TOKEN_A`; **State-1f** = A follows 1 author with 1 article; **State-50f** = A follows authors totalling 50 articles |

**Steps**
1. Set DB to **State-1f**. Reset the query counter.
2. `curl -s -H "Authorization: Token $TOKEN_A" "http://localhost:3000/api/articles/feed?limit=50" > /dev/null`. Record `Q1f`.
3. Set DB to **State-50f**. Reset the counter.
4. Repeat the feed request. Record `Q50f`.
5. Compute `Q50f − Q1f`.

**Expected result**
- `Q50f − Q1f` is a small constant, not proportional to the 49-article increase — the personal feed
  handler also uses eager `include`, not the per-article append loop.

**Record the numbers**
| DB state | Articles returned | Query count |
|----------|-------------------|-------------|
| State-1f | 1 | Q1f = ____ |
| State-50f | 50 | Q50f = ____ |
| Delta | — | Q50f − Q1f = ____ |

**Pass/Fail criteria**: PASS if the feed's query count is bounded/constant with respect to article
count. FAIL if it scales linearly.
**Cleanup**: Restore baseline seed; disable verbose logging.

---

### TC-PERF-03 — Response-time comparison: new Next.js handler vs old Express backend

| Field | Value |
|-------|-------|
| **Traces to** | AC-4, AC-5 / REQ-NF-04 |
| **Type** | Performance (latency comparison) |
| **Priority** | P2 |
| **Preconditions** | BOTH backends running against equivalent data seeded with 50 articles; both warmed with a few throwaway requests first |
| **Test data** | Same query on both: `?limit=50`; `$TOKEN_A` per backend for the feed |

**Steps**
1. Warm each endpoint with 3 discarded requests.
2. Measure the OLD global feed 20 times:
   `for i in $(seq 20); do curl -s -o /dev/null -w "%{time_total}\n" "http://localhost:3001/api/articles?limit=50"; done` — record all times.
3. Measure the NEW global feed 20 times against `http://localhost:3000/api/articles?limit=50` the same way.
4. Repeat steps 2–3 for the personal feed (`/api/articles/feed`, each backend's `$TOKEN_A`).
5. For each set compute min / median / p95 (sort the 20 samples; p95 ≈ the 19th value).

**Expected result**
- The NEW backend's median and p95 are **≤** the OLD backend's for both the global and personal feed
  (the migration + eager loading must not regress latency; ideally it improves it by removing N+1
  round-trips).

**Record the numbers**
| Endpoint | Backend | min (s) | median (s) | p95 (s) |
|----------|---------|---------|------------|---------|
| GET /articles?limit=50 | old (:3001) | | | |
| GET /articles?limit=50 | new (:3000) | | | |
| GET /articles/feed | old (:3001) | | | |
| GET /articles/feed | new (:3000) | | | |

**Pass/Fail criteria**: PASS if new p95 ≤ old p95 for both endpoints (no regression). A material
regression (new noticeably slower) is a FAIL and should be raised as a performance defect.
`TO CONFIRM: the acceptable regression margin, if the team allows a small tolerance.`
**Cleanup**: Restore baseline seed on both backends.
