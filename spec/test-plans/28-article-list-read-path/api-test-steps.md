# API Test Steps — Story 1.10 Article List Read Path Under the Amended REQ-F-17

**Purpose**: Verify that `GET /api/articles` and `GET /api/articles/feed` return the same contract-visible
results under REQ-F-17@v2, whichever bounded-query read path was chosen (AC-1, AC-3).

**Scope**: The list and feed endpoints and their `author` / `tag` / `favorited` / `limit` / `offset`
filter variants. Black-box: HTTP request in, HTTP response out. The chosen mechanism is not observable
here and is not asserted.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `cr-test/epic-nextjs-migration` (epic cycle) |
| This story's PR | Story 1.10's `[STORY]` PR — merged into the epic branch before execution |
| Confirm the story is in the build | `git log --oneline \| grep "Story 1.10"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING). This plan does not restate them. |
| Local base URL / port | `http://localhost:3000` |
| Local services that must be up | PostgreSQL (the existing instance the epic branch's `.env.local` points at) |
| Test data / accounts to seed | Accounts `alice`, `bob`; articles created per case below |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

### Common test data
- `alice` / `alice@test.local` / `password123`
- `bob` / `bob@test.local` / `password123`
- Log in via `POST /api/users/login` and keep the `httpOnly` session cookie in a cookie jar
  (`curl -c jar.txt -b jar.txt`).

---

### TC-API-01 — GET /api/articles returns the global list with every row fully populated (happy path)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-3 / REQ-F-17@v2 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | Local instance running; `alice` registered and logged in |
| **Test data** | Three articles by `alice`, each with at least one tag |

**Steps**
1. As `alice`, `POST /api/articles` three times with titles "List One", "List Two", "List Three",
   each with `tagList: ["alpha"]`.
2. `curl -s http://localhost:3000/api/articles`.

**Expected result**
- `200 OK`.
- `articlesCount` is 3 and `articles` has 3 elements.
- Every element carries a non-null `tagList` containing `alpha`, an `author` object with `username`,
  `bio`, `image` and a boolean `following`, plus boolean `favorited` and numeric `favoritesCount`.
- No element is missing any of those fields and none is `null` where the other elements have a value.

**Pass/Fail criteria**: PASS when all 3 rows are present and fully populated. A missing or null
`tagList`, `author`, `favorited` or `favoritesCount` on any row is a FAIL.
**Cleanup**: Delete the three articles via `DELETE /api/articles/:slug`.

---

### TC-API-02 — GET /api/articles filter variants return fully populated rows

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-3 / REQ-F-17@v2 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | Local instance running; `alice` and `bob` registered |
| **Test data** | `alice` article tagged `elixir`; `bob` article tagged `rust`, favorited by `alice` |

**Steps**
1. As `alice`, create "Alpha Post" with `tagList: ["elixir"]`.
2. As `bob`, create "Beta Post" with `tagList: ["rust"]`.
3. As `alice`, `POST /api/articles/beta-post/favorite`.
4. `curl -s "http://localhost:3000/api/articles?author=alice"`.
5. `curl -s "http://localhost:3000/api/articles?tag=rust"`.
6. As `alice`, `curl -s -b jar.txt "http://localhost:3000/api/articles?favorited=alice"`.

**Expected result**
- Step 4: `200 OK`, exactly "Alpha Post", fully populated per TC-API-01.
- Step 5: `200 OK`, exactly "Beta Post", `tagList` contains `rust`.
- Step 6: `200 OK`, exactly "Beta Post", `favorited` is `true` and `favoritesCount` is 1.

**Pass/Fail criteria**: PASS when each filter returns exactly the matching article with all fields
populated. A filter returning the wrong set, or rows with missing derived fields, is a FAIL.
**Cleanup**: Unfavorite, then delete both articles.

---

### TC-API-03 — GET /api/articles pagination boundary (limit / offset)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-3 / REQ-F-17@v2 |
| **Type** | API (boundary) |
| **Priority** | P2 |
| **Preconditions** | Local instance running; `alice` registered |
| **Test data** | Five articles by `alice`, created in a known order |

**Steps**
1. As `alice`, create "Page A" … "Page E" in that order.
2. `curl -s "http://localhost:3000/api/articles?limit=2&offset=0"`.
3. `curl -s "http://localhost:3000/api/articles?limit=2&offset=2"`.
4. `curl -s "http://localhost:3000/api/articles?limit=2&offset=99"`.

**Expected result**
- Step 2: 2 articles, newest first ("Page E", "Page D").
- Step 3: the next 2 ("Page C", "Page B"), with no overlap against step 2.
- Step 4: `articles` is an empty array, `articlesCount` still reports the full count of 5.
- Every returned row is fully populated per TC-API-01.

**Pass/Fail criteria**: PASS when the pages are disjoint, correctly ordered, and `articlesCount`
reports the unpaginated total. Duplicate rows across pages, or a count that reflects the page size,
is a FAIL.
**Cleanup**: Delete all five articles.

---

### TC-API-04 — GET /api/articles/feed returns followed authors' articles, fully populated

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-3 / REQ-F-17@v2 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | Local instance running; `alice` and `bob` registered; `alice` logged in |
| **Test data** | `bob` article "Feed Post" tagged `feed`; a `carol` article that must not appear |

**Steps**
1. As `bob`, create "Feed Post" with `tagList: ["feed"]`.
2. Register `carol` and create "Unfollowed Post" as `carol`.
3. As `alice`, `POST /api/profiles/bob/follow`.
4. As `alice`, `curl -s -b jar.txt http://localhost:3000/api/articles/feed`.

**Expected result**
- `200 OK`.
- Exactly "Feed Post" is returned; "Unfollowed Post" is absent.
- Its `author.following` is `true`, and `tagList`, `favorited`, `favoritesCount` are all populated.

**Pass/Fail criteria**: PASS when only followed authors' articles appear, fully populated, with
`following: true`. An unfollowed author's article appearing, or `following: false` on a followed
author, is a FAIL.
**Cleanup**: Unfollow `bob`; delete both articles.

---

### TC-API-05 — GET /api/articles/feed requires authentication (negative)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-17@v2 |
| **Type** | API (negative / auth) |
| **Priority** | P1 |
| **Preconditions** | Local instance running; no session cookie sent |
| **Test data** | None |

**Steps**
1. `curl -s -i http://localhost:3000/api/articles/feed` with no cookie jar.

**Expected result**
- `401 Unauthorized`.
- Body matches the Conduit error shape `{ "errors": { "body": [...] } }`.

**Pass/Fail criteria**: PASS on `401` with the documented error shape. A `200` with an empty list,
or a `500`, is a FAIL.
**Cleanup**: None.

---

### TC-API-06 — Anonymous list request defaults the viewer flags (negative / boundary)

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-F-17@v2 |
| **Type** | API (boundary) |
| **Priority** | P2 |
| **Preconditions** | Local instance running; one article exists, favorited by nobody |
| **Test data** | `alice` article "Anon Row" tagged `anon` |

**Steps**
1. As `alice`, create "Anon Row" with `tagList: ["anon"]`.
2. `curl -s http://localhost:3000/api/articles` with **no** cookie jar.

**Expected result**
- `200 OK`.
- The row's `tagList` contains `anon` and `author.username` is `alice`.
- `author.following` is `false`, `favorited` is `false`, `favoritesCount` is `0` — defaulted, not
  null and not absent.

**Pass/Fail criteria**: PASS when the viewer-dependent flags are present and `false`/`0`. A `null`,
a missing key, or a `500` is a FAIL.
**Cleanup**: Delete the article.

---

### TC-API-07 — List response shape is unchanged from Story 1.4 (regression / parity)

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-F-17@v2, REQ-NF-02 |
| **Type** | API (regression) |
| **Priority** | P1 |
| **Preconditions** | Local instance running; a captured list response from the epic branch **before** Story 1.10 merged |
| **Test data** | The same seeded articles used for the pre-Story-1.10 capture |

**Steps**
1. Before Story 1.10 merges, seed three tagged articles, favorite one as `alice`, and save
   `GET /api/articles` (authenticated as `alice`) to `before.json`.
2. After Story 1.10 merges, rebuild, re-seed identically, and save the same request to `after.json`.
3. Compare the two with a structural diff, ignoring `createdAt`/`updatedAt` and `slug` suffixes.

**Expected result**
- The key sets match exactly at every level — no field added, removed or renamed.
- `tagList`, `author` (including `following`), `favorited` and `favoritesCount` hold the same values
  for the same seeded data.

**Pass/Fail criteria**: PASS when the structural diff is empty apart from the ignored timestamp and
slug fields. Any added, removed, renamed or re-typed field is a FAIL.
**Cleanup**: Delete the seeded articles from both runs.
