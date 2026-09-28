# Integration Test Steps — #25 Home & Article Pages (Server Components)

**Purpose**: Verify the boundary between the Server Component pages and the data layer they consume:
page → API/data query → rendered content. Confirm the rendered page correctly reflects data that
crosses the page↔datastore boundary, including session-dependent favorited/following state and
pagination query params. Black-box; observed only from the rendered output.

**Scope**: `/` (home feed + popular tags) and `/article/[slug]` (article body + comments) as they
integrate with the article/feed/tags/comments data served from PostgreSQL via Sequelize.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/nextjs-migration` |
| This story's merged PR | [PR #35](https://github.com/revanta-biswas/conduit-helix-test/pull/35) |
| Confirm the story is in the build | `git log --oneline \| grep -i "1.7\|#25\|home.*article"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | `http://localhost:3000` |
| Local services that must be up | PostgreSQL (via Sequelize) |
| Test data / accounts to seed | Same as e2e-test-steps.md: Alice (≥ 12 articles, ≥ 2 tags), Bob (follows Alice, favorited one Alice article), one article `<known-slug>` with markdown body + ≥ 2 comments |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-INT-01 — Home feed renders the articles present in the datastore (page → data boundary)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-20 |
| **Type** | Integration |
| **Priority** | P1 |
| **Preconditions** | SUT running; PostgreSQL up; seed data present. Have read access to the DB (e.g. `psql`) to independently count articles. |
| **Test data** | None |

**Steps**
1. In the database, count published articles and note the count and the newest article's title: e.g. `SELECT count(*) FROM "Articles";` and `SELECT title FROM "Articles" ORDER BY "createdAt" DESC LIMIT 1;`. TO CONFIRM: exact table/column names — the tester reads them from the DB, not from app source.
2. Navigate to `http://localhost:3000/`.
3. Compare the first-page article previews (titles, count) against the DB query.

**Expected result**
- The newest article's title from the DB appears as the first (or near-first, per default ordering) preview on the home feed.
- The feed reflects real datastore rows — creating no articles yourself, the feed matches the seeded data. The page↔data boundary returns live data, not a static placeholder.

**Pass/Fail criteria**: PASS if the rendered feed content matches the datastore contents at the page boundary. FAIL if the feed is empty despite seeded rows, or shows stale/placeholder content.
**Cleanup**: None (read-only DB).

---

### TC-INT-02 — Popular-tags sidebar reflects tags present in the datastore

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-20 |
| **Type** | Integration |
| **Priority** | P2 |
| **Preconditions** | SUT running; seed articles carry ≥ 2 distinct tags |
| **Test data** | None |

**Steps**
1. In the DB, list distinct tag names used by articles. TO CONFIRM: tag table/relationship names.
2. Navigate to `http://localhost:3000/`.
3. Compare the popular-tags sidebar entries against the DB tag list.

**Expected result**
- Every tag shown in the sidebar exists on at least one article in the datastore.
- Tags with no articles do not appear (no orphan/hardcoded tags).

**Pass/Fail criteria**: PASS if sidebar tags trace to real datastore tags. FAIL on hardcoded or missing tags.
**Cleanup**: None.

---

### TC-INT-03 — Logged-in Bob sees favorited=true / following=true where the datastore says so

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-F-29 |
| **Type** | Integration |
| **Priority** | P1 |
| **Preconditions** | SUT running; logged in as Bob; Bob follows Alice and has favorited one Alice article (seed (b)); `<known-slug>` is that favorited article |
| **Test data** | Bob's session; `<known-slug>` (Alice's article that Bob favorited) |

**Steps**
1. Log in as Bob.
2. Navigate to `http://localhost:3000/article/<known-slug>`.
3. Observe the favorite control state and the follow-author control state.

**Expected result**
- The favorite control shows the **favorited** state (e.g. filled / "Unfavorite" affordance) for this article because Bob favorited it.
- The follow-author control shows the **following** state (e.g. "Unfollow Alice") because Bob follows Alice.
- These states correctly reflect Bob's session at the page↔data boundary (session-scoped read).

**Pass/Fail criteria**: PASS if both controls reflect Bob's real relationships from the datastore. FAIL if either shows the opposite of the seeded relationship.
**Cleanup**: Log out. Do not toggle favorite/follow (that is Story 1.8 behavior, out of scope here).

---

### TC-INT-04 — Anonymous visitor gets favorited=false / following=false (no other user's state leaks) (negative)

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-F-29 |
| **Type** | Integration |
| **Priority** | P1 |
| **Preconditions** | SUT running; NOT logged in; `<known-slug>` is an article that Bob favorited (so a real "favorited=true" exists for some other user) |
| **Test data** | `<known-slug>` |

**Steps**
1. In a fresh/incognito window (no session cookie), navigate to `http://localhost:3000/article/<known-slug>`.
2. Observe the favorite control and the follow-author control.

**Expected result**
- The favorite control shows the **not-favorited** (false) state.
- The follow-author control shows the **not-following** (false) state.
- Bob's favorited/following relationship does NOT bleed into the anonymous view — the page reflects "false" for a session with no user, regardless of any other user's state in the datastore.

**Pass/Fail criteria**: PASS only if both states are false for the anonymous visitor. FAIL if any control shows favorited/following true (would indicate another user's state leaking to anonymous — a data-isolation defect).
**Cleanup**: None.

---

### TC-INT-05 — Article body + comments both cross the boundary for the same slug

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-21 |
| **Type** | Integration |
| **Priority** | P1 |
| **Preconditions** | SUT running; `<known-slug>` has a markdown body and ≥ 2 comments in the DB |
| **Test data** | `<known-slug>` |

**Steps**
1. In the DB, note the article body text and the comment bodies for `<known-slug>`. TO CONFIRM: comment table/column names.
2. Navigate to `http://localhost:3000/article/<known-slug>`.
3. Compare the rendered body and each rendered comment against the DB values.

**Expected result**
- The rendered article body content matches the DB article body (rendered from markdown).
- Every seeded comment for the article appears in the rendered comments list, with matching text and author.
- Both the article and its comments are fetched and rendered by the Server Component in one page load (no missing section).

**Pass/Fail criteria**: PASS if body and all comments render matching the datastore. FAIL if comments are missing or belong to a different article.
**Cleanup**: None.

---

### TC-INT-06 — Pagination offset changes which datastore rows are rendered (boundary)

| Field | Value |
|-------|-------|
| **Traces to** | AC-5 / REQ-F-20 |
| **Type** | Integration |
| **Priority** | P1 |
| **Preconditions** | SUT running; Alice has ≥ 12 articles so ≥ 2 pages exist |
| **Test data** | `http://localhost:3000/?offset=0` and `http://localhost:3000/?offset=10` (adjust to confirmed page size) |

**Steps**
1. Navigate to `http://localhost:3000/?offset=0`; record the list of article titles shown.
2. Navigate to `http://localhost:3000/?offset=10`; record the list of article titles shown.
3. Compare the two lists.

**Expected result**
- Page 1 (`offset=0`) and page 2 (`offset=10`) show **different, non-overlapping** article sets, consistent with limit/offset windowing of the datastore rows.
- The limit/offset query params drive which datastore rows the page renders — same as the current (pre-migration) behavior.

**Pass/Fail criteria**: PASS if changing `offset` returns a different, correct window of articles. FAIL if the two pages are identical, or overlap incorrectly, or offset is ignored.
**Cleanup**: None.
