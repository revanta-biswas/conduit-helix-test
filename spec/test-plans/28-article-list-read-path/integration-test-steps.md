# Integration Test Steps — Story 1.10 Article List Read Path Under the Amended REQ-F-17

**Purpose**: Verify the boundary between the list/feed Route Handlers and the PostgreSQL datastore —
that every list row is fully joined (AC-3) and that a write to an article is reflected in the next
list response (AC-5).

**Scope**: Route Handlers ↔ Sequelize ↔ PostgreSQL. All observation is black-box (HTTP responses and
read-back), with no inspection of the read path's internals. AC-5 matters most where a denormalised
read model was chosen: a stale row is observable here and nowhere else.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `cr-test/epic-nextjs-migration` (epic cycle) |
| This story's PR | Story 1.10's `[STORY]` PR — merged into the epic branch before execution |
| Confirm the story is in the build | `git log --oneline \| grep "Story 1.10"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING). This plan does not restate them. |
| Local base URL / port | `http://localhost:3000` |
| Local services that must be up | PostgreSQL (the instance the epic branch's `.env.local` points at) |
| Test data / accounts to seed | `alice`, `bob`; articles created per case |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

> **Read the story's code-generation plan first.** It records which read path was chosen (AC-1). Where
> it records a denormalised read model, TC-INT-03…TC-INT-07 are the cases that prove its refresh path;
> where it records eager loading, they still run and simply cannot go stale.

---

### TC-INT-01 — Every list row is fully joined (no lazy-load holes)

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-F-17@v2 |
| **Type** | Integration (list read path) |
| **Priority** | P1 |
| **Preconditions** | Local instance running; `alice` and `bob` registered; `bob` logged in |
| **Test data** | 10 articles by `alice`, each with 2 tags; `bob` follows `alice` and has favorited 3 of them |

**Steps**
1. As `alice`, create 10 articles, each with `tagList: ["t1", "t2"]`.
2. As `bob`, `POST /api/profiles/alice/follow`.
3. As `bob`, favorite 3 of the 10 articles.
4. As `bob`, `curl -s -b jar.txt "http://localhost:3000/api/articles?limit=10"`.

**Expected result**
- `200 OK` with 10 articles.
- Every row carries `tagList` with both tags, `author.username` = `alice`, `author.following` = `true`,
  and boolean `favorited` / numeric `favoritesCount`.
- Exactly the 3 favorited rows have `favorited: true` and `favoritesCount: 1`; the other 7 have
  `favorited: false` and `favoritesCount: 0`.

**Pass/Fail criteria**: PASS when all 10 rows are complete and the favorited subset is exactly the 3
favorited. Any row with a missing or null derived field indicates a broken join or a partially
populated read model — FAIL.
**Cleanup**: Unfavorite, unfollow, delete the 10 articles.

---

### TC-INT-02 — Follow state is per-requesting-user, not baked into the row

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-F-17@v2 |
| **Type** | Integration (viewer-scoped enrichment) |
| **Priority** | P1 |
| **Preconditions** | Local instance running; `alice`, `bob`, `carol` registered |
| **Test data** | One `alice` article; `bob` follows `alice`, `carol` does not |

**Steps**
1. As `alice`, create "Viewer Scoped".
2. As `bob`, follow `alice`; as `carol`, do not.
3. As `bob`, `GET /api/articles`; record `author.following`.
4. As `carol`, `GET /api/articles`; record `author.following`.
5. Anonymously, `GET /api/articles`; record `author.following`.

**Expected result**
- Step 3: `following` is `true`.
- Step 4: `following` is `false`.
- Step 5: `following` is `false`.
- The article is the same row in all three responses; only the viewer-scoped flag differs.

**Pass/Fail criteria**: PASS when the same article reports different `following` values per requester.
An identical value for all three viewers means a viewer-independent value was denormalised into the
row — FAIL.
**Cleanup**: Unfollow; delete the article.

---

### TC-INT-03 — A newly created article appears in the next list response

| Field | Value |
|-------|-------|
| **Traces to** | AC-5 / REQ-F-17@v2 |
| **Type** | Integration (read-model freshness) |
| **Priority** | P1 |
| **Preconditions** | Local instance running; `alice` logged in |
| **Test data** | Article "Freshly Made" with `tagList: ["fresh"]` |

**Steps**
1. `GET /api/articles` and record `articlesCount` as **C0**.
2. As `alice`, `POST /api/articles` creating "Freshly Made" with `tagList: ["fresh"]`.
3. Immediately `GET /api/articles` again, with no wait and no restart.

**Expected result**
- Step 3: `articlesCount` is `C0 + 1`.
- "Freshly Made" is the first row (newest first), with `tagList` containing `fresh`, `author.username`
  = `alice`, `favorited: false`, `favoritesCount: 0`.

**Pass/Fail criteria**: PASS when the new article is present and fully populated on the very next
request. Absence, or presence with an empty `tagList`, is a FAIL — the refresh path did not run.
**Cleanup**: Delete "Freshly Made".

---

### TC-INT-04 — An updated article's title and tags are reflected in the next list response

| Field | Value |
|-------|-------|
| **Traces to** | AC-5 / REQ-F-17@v2 |
| **Type** | Integration (read-model freshness) |
| **Priority** | P1 |
| **Preconditions** | Local instance running; `alice` logged in |
| **Test data** | Article "Before Edit" with `tagList: ["old"]` |

**Steps**
1. As `alice`, create "Before Edit" with `tagList: ["old"]`.
2. `GET /api/articles` and confirm the row shows title "Before Edit" and tag `old`.
3. As `alice`, `PUT /api/articles/before-edit` setting title "After Edit" and `tagList: ["new"]`.
4. Immediately `GET /api/articles` again.

**Expected result**
- Step 4: the row's `title` is "After Edit", its `tagList` contains `new` and does **not** contain `old`.
- `GET /api/tags` includes `new`.

**Pass/Fail criteria**: PASS when the updated title and re-associated tags appear on the next request.
A stale title, or `old` still present on the row, is a FAIL.
**Cleanup**: Delete the article.

---

### TC-INT-05 — A favorite toggle is reflected in the next list response

| Field | Value |
|-------|-------|
| **Traces to** | AC-5, AC-3 / REQ-F-17@v2 |
| **Type** | Integration (read-model freshness) |
| **Priority** | P1 |
| **Preconditions** | Local instance running; `alice` and `bob` registered; `bob` logged in |
| **Test data** | `alice` article "Toggle Me" |

**Steps**
1. As `alice`, create "Toggle Me".
2. As `bob`, `GET /api/articles`; confirm `favorited: false`, `favoritesCount: 0`.
3. As `bob`, `POST /api/articles/toggle-me/favorite`.
4. Immediately as `bob`, `GET /api/articles`.
5. As `bob`, `DELETE /api/articles/toggle-me/favorite`.
6. Immediately as `bob`, `GET /api/articles`.

**Expected result**
- Step 4: `favorited: true`, `favoritesCount: 1`.
- Step 6: `favorited: false`, `favoritesCount: 0`.
- Both transitions are visible on the very next request, with no wait and no restart.

**Pass/Fail criteria**: PASS when both toggles are reflected immediately. A stale count or flag after
either toggle is a FAIL.
**Cleanup**: Delete the article.

---

### TC-INT-06 — A deleted article is absent from the next list response, with no orphan row

| Field | Value |
|-------|-------|
| **Traces to** | AC-5 / REQ-F-17@v2 |
| **Type** | Integration (read-model freshness / negative) |
| **Priority** | P1 |
| **Preconditions** | Local instance running; `alice` logged in |
| **Test data** | `alice` article "Doomed" with `tagList: ["doomedtag"]` |

**Steps**
1. As `alice`, create "Doomed" with `tagList: ["doomedtag"]`.
2. `GET /api/articles` and confirm it is present.
3. As `alice`, `DELETE /api/articles/doomed`.
4. Immediately `GET /api/articles`.
5. `GET /api/articles?tag=doomedtag`.

**Expected result**
- Step 4: "Doomed" is absent and `articlesCount` has decreased by 1.
- Step 5: an empty `articles` array — the deleted article is not reachable through its tag filter.

**Pass/Fail criteria**: PASS when the article is gone from both the unfiltered list and the tag
filter. A row surviving in either is a FAIL — a dangling entry in the read path.
**Cleanup**: None (the article is deleted).

---

### TC-INT-07 — Concurrent writes during a list read leave no inconsistent row (boundary)

| Field | Value |
|-------|-------|
| **Traces to** | AC-5 / REQ-F-17@v2 |
| **Type** | Integration (concurrency boundary) |
| **Priority** | P2 |
| **Preconditions** | Local instance running; `alice` and `bob` registered |
| **Test data** | 20 `alice` articles, each with 1 tag |

**Steps**
1. As `alice`, create 20 articles.
2. In one terminal, loop `GET /api/articles?limit=20` continuously for ~15 seconds.
3. While that loop runs, in a second terminal have `bob` favorite and unfavorite 5 of the articles
   repeatedly, and have `alice` re-tag 2 of them.
4. Stop both. Inspect every captured response.

**Expected result**
- Every captured response is `200 OK`.
- No response contains a row with a null or missing `tagList`, `author`, `favorited` or
  `favoritesCount`.
- `favoritesCount` on any row is always `0` or `1` (never negative, never above the number of users
  who favorited it).
- A final `GET /api/articles` after the writes settle shows the end state of the re-tagged articles.

**Pass/Fail criteria**: PASS when no captured response contains a malformed or impossible row and the
settled state is correct. A null derived field, a negative count, or a permanently stale row after the
writes stop is a FAIL.
**Cleanup**: Unfavorite all; delete the 20 articles.
