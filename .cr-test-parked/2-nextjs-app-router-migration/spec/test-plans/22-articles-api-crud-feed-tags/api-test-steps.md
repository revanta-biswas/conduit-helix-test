# API Test Steps — #22 Articles API — CRUD, Feed & Tags

**Purpose**: Verify every Articles/Tags Route Handler exposes the correct HTTP contract — status
codes, response body shape, and headers — for happy paths, auth paths, bad payloads and boundary
values. All cases are **black-box HTTP** against the locally built instance; no source code is read.

**Scope**: `GET /api/articles`, `GET /api/articles/feed`, `POST /api/articles`,
`GET|PUT|DELETE /api/articles/:slug`, `GET /api/tags`. Response-shape parity vs the old Express
backend (AC-5) is covered here and cross-referenced from the integration plan.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/nextjs-migration` (story #22 merged via PR #31) |
| This story's merged PR | https://github.com/revanta-biswas/conduit-helix-test/pull/31 |
| Confirm the story is in the build | `git log --oneline \| grep -i "1.4\|#22\|articles"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING). This plan does not restate them. |
| Local base URL / port (new, Next.js) | `http://localhost:3000`, API under `/api/` |
| Old backend base URL (comparison only, AC-5) | `http://localhost:3001/api` (existing Express app) |
| Local services that must be up | PostgreSQL (via Sequelize); both apps pointed at an equivalent/seeded DB |
| Test data / accounts to seed | See **Common test data** below |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

### Common test data
| Item | Value |
|------|-------|
| User A (author) | email `alice@test.io`, username `alice`, password `Passw0rd!` |
| User B (other) | email `bob@test.io`, username `bob`, password `Passw0rd!` |
| Auth header format | `Authorization: Token <jwt>` (RealWorld convention). **TO CONFIRM: whether the ported handlers expect `Token <jwt>` or `Bearer <jwt>` — confirm with dev.** |
| Obtain a JWT | `POST /api/users/login` with `{ "user": { "email": "...", "password": "..." } }`, read `user.token` from the response |
| Sample article payload | `{ "article": { "title": "How to Train Your Dragon", "description": "Ever wonder how?", "body": "You have to believe", "tagList": ["dragons","training"] } }` |

> Notation: `$TOKEN_A` = User A's JWT, `$TOKEN_B` = User B's JWT, `$SLUG` = slug returned when the
> sample article is created. RealWorld standard error shape is `{ "errors": { "body": [ "..." ] } }`.

---

### TC-API-01 — GET /api/articles returns the global feed (happy path)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-12 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | Local instance running; DB seeded with ≥3 published articles by different authors |
| **Test data** | No auth header (global feed is public) |

**Steps**
1. Run `curl -s -i http://localhost:3000/api/articles`.
2. Inspect the status line, `Content-Type` header, and body.

**Expected result**
- `HTTP/1.1 200 OK`.
- `Content-Type: application/json`.
- Body has top-level keys `articles` (array) and `articlesCount` (integer).
- Each element of `articles` contains: `slug`, `title`, `description`, `body`, `tagList` (array),
  `createdAt`, `updatedAt`, `favorited` (boolean), `favoritesCount` (integer), and an `author`
  object with `username`, `bio`, `image`, `following` (boolean).
- `articlesCount` equals the total number of matching articles (not just the page length).

**Pass/Fail criteria**: PASS if status is 200 and every listed field is present with the correct
type on every element. Any missing/renamed field, wrong type, or non-200 status is a FAIL.
**Cleanup**: None (read-only).

---

### TC-API-02 — GET /api/articles filters by author, tag, favorited

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-12 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | Local instance running; article by `alice` tagged `dragons`, and at least one article NOT by `alice` and NOT tagged `dragons`; User B has favorited exactly one known article |
| **Test data** | `$TOKEN_B` for the `favorited` sub-check |

**Steps**
1. `curl -s "http://localhost:3000/api/articles?author=alice"` — note returned slugs.
2. `curl -s "http://localhost:3000/api/articles?tag=dragons"` — note returned slugs.
3. `curl -s "http://localhost:3000/api/articles?favorited=bob"` — note returned slugs.

**Expected result**
- Step 1: every returned article's `author.username` == `alice`; articles by other authors are absent.
- Step 2: every returned article's `tagList` contains `dragons`; articles without it are absent.
- Step 3: every returned article is one that user `bob` has favorited; `articlesCount` matches.
- All three responses are `200` with the same element shape as TC-API-01.

**Pass/Fail criteria**: PASS if each filter narrows the set correctly and excludes non-matching
articles. Returning unfiltered results, or dropping matching ones, is a FAIL.
**Cleanup**: None.

---

### TC-API-03 — GET /api/articles pagination boundary (limit / offset)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-12 |
| **Type** | API (boundary) |
| **Priority** | P2 |
| **Preconditions** | DB seeded with ≥25 articles so paging is observable |
| **Test data** | None (public) |

**Steps**
1. `curl -s "http://localhost:3000/api/articles?limit=5&offset=0"` — record slugs (page 1).
2. `curl -s "http://localhost:3000/api/articles?limit=5&offset=5"` — record slugs (page 2).
3. `curl -s "http://localhost:3000/api/articles?limit=0"`.
4. `curl -s "http://localhost:3000/api/articles?limit=9999&offset=100000"`.
5. `curl -s "http://localhost:3000/api/articles?limit=abc"`.

**Expected result**
- Step 1: `articles` length ≤ 5; `articlesCount` reflects the full unpaged total.
- Step 2: page 2 slugs are disjoint from page 1 (no overlap, no gap).
- Step 3: `limit=0` returns an empty `articles` array with the correct `articlesCount` (or the
  documented default). **TO CONFIRM: exact behaviour of `limit=0` — dev/BA to confirm.**
- Step 4: an offset past the end returns `200` with empty `articles`, not an error.
- Step 5: non-numeric `limit` is handled gracefully — either the default limit is applied (`200`) or a
  `422` with `{ errors: { body: [...] } }`. It must NOT return a 500. **TO CONFIRM: intended handling
  of non-numeric pagination params.**

**Pass/Fail criteria**: PASS if paging windows are correct/non-overlapping and out-of-range/invalid
inputs never produce a 500. FAIL on overlap, wrong count, or an unhandled server error.
**Cleanup**: None.

---

### TC-API-04 — GET /api/articles/feed returns the personal feed (happy path)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-12 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | User A follows User B; User B has ≥1 article; a third author (unfollowed) also has articles |
| **Test data** | `$TOKEN_A` |

**Steps**
1. `curl -s -H "Authorization: Token $TOKEN_A" http://localhost:3000/api/articles/feed`.
2. Inspect body.

**Expected result**
- `200 OK`; body shape identical to TC-API-01 (`articles` + `articlesCount`).
- Every returned article's author is a user that A follows (i.e. User B); articles by unfollowed
  authors are absent.
- `author.following` is `true` on every returned element.

**Pass/Fail criteria**: PASS if the feed contains only followed-author articles with correct shape.
Including unfollowed authors' articles, or wrong `following` flag, is a FAIL.
**Cleanup**: None.

---

### TC-API-05 — GET /api/articles/feed requires authentication (negative)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-12, REQ-F-17 |
| **Type** | API (negative / auth) |
| **Priority** | P1 |
| **Preconditions** | Local instance running |
| **Test data** | No token; then a malformed token |

**Steps**
1. `curl -s -i http://localhost:3000/api/articles/feed` (no auth header).
2. `curl -s -i -H "Authorization: Token not-a-real-jwt" http://localhost:3000/api/articles/feed`.

**Expected result**
- Both requests return `401 Unauthorized` (RealWorld convention for the personal feed without a
  valid token).
- Body is the standard error shape `{ "errors": { "body": [ ... ] } }` OR an empty 401 body,
  matching the old backend. **TO CONFIRM: whether the old backend returns 401 with a body or a bare
  401 — verify parity in TC-API-16.**
- No `articles` payload is leaked.

**Pass/Fail criteria**: PASS if both return 401 and no article data is returned. A 200, a 500, or
leaked article data is a FAIL.
**Cleanup**: None.

---

### TC-API-06 — POST /api/articles creates an article + generates slug (happy path)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-12 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | User A authenticated |
| **Test data** | `$TOKEN_A`; sample article payload (title `How to Train Your Dragon`, tagList `["dragons","training"]`) |

**Steps**
1. `curl -s -i -X POST http://localhost:3000/api/articles -H "Authorization: Token $TOKEN_A" -H "Content-Type: application/json" -d '{ "article": { "title": "How to Train Your Dragon", "description": "Ever wonder how?", "body": "You have to believe", "tagList": ["dragons","training"] } }'`.
2. Read the response body; record `article.slug` as `$SLUG`.

**Expected result**
- `200 OK` (RealWorld returns 200 on create; **TO CONFIRM: whether the ported handler returns 200 or
  201 — must match the old backend, see TC-API-16**).
- Body top-level key `article` containing all article fields (per TC-API-01) plus the populated
  `author` object for User A.
- `article.slug` is derived from the title, lowercased and hyphenated, e.g.
  `how-to-train-your-dragon` (a trailing uniqueness suffix is acceptable).
- `article.tagList` equals `["dragons","training"]` (order-insensitive).
- `article.favorited` == `false`, `article.favoritesCount` == `0`.

**Pass/Fail criteria**: PASS if the article is created, slug is a correct slugified title, and
tagList round-trips. A wrong slug, missing tags, or missing fields is a FAIL.
**Cleanup**: `DELETE /api/articles/$SLUG` with `$TOKEN_A` (see TC-API-13).

---

### TC-API-07 — POST /api/articles slug generation for tricky titles (boundary)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-12 |
| **Type** | API (boundary) |
| **Priority** | P2 |
| **Preconditions** | User A authenticated |
| **Test data** | `$TOKEN_A`; titles below |

**Steps**
1. Create an article titled `Hello, World! & Friends (2026)` — record slug.
2. Create an article titled `  Leading   and   trailing  spaces  ` — record slug.
3. Create a second article with the SAME title as TC-API-06 (`How to Train Your Dragon`) — record slug.

**Expected result**
- Step 1: slug strips punctuation and collapses separators, e.g. `hello-world-friends-2026`
  (no commas, ampersands, parentheses, or double hyphens).
- Step 2: slug has no leading/trailing hyphens and no repeated hyphens, e.g.
  `leading-and-trailing-spaces`.
- Step 3: the duplicate-title article still gets a **unique** slug (e.g.
  `how-to-train-your-dragon-<suffix>`); the create succeeds with `200` and does NOT collide/500.
  **TO CONFIRM: the exact uniqueness strategy (random suffix vs sequence) — dev to confirm.**

**Pass/Fail criteria**: PASS if all three slugs are clean, well-formed, and the duplicate title
yields a distinct slug without error. A collision error, a 500, or a malformed slug is a FAIL.
**Cleanup**: DELETE each created article with `$TOKEN_A`.

---

### TC-API-08 — POST /api/articles rejects unauthenticated request (negative)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-17 |
| **Type** | API (negative / auth) |
| **Priority** | P1 |
| **Preconditions** | Local instance running |
| **Test data** | Valid payload, no token |

**Steps**
1. `curl -s -i -X POST http://localhost:3000/api/articles -H "Content-Type: application/json" -d '{ "article": { "title": "No auth", "description": "x", "body": "y" } }'`.

**Expected result**
- `401 Unauthorized`.
- No article is created (confirm with a subsequent `GET /api/articles?author=alice` — the "No auth"
  article is absent).

**Pass/Fail criteria**: PASS if 401 and nothing persisted. A 200/created article is a FAIL.
**Cleanup**: If an article was wrongly created, DELETE it (this is itself a defect).

---

### TC-API-09 — POST /api/articles rejects missing required fields (negative)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2, AC-5 / REQ-F-12 |
| **Type** | API (negative / bad payload) |
| **Priority** | P1 |
| **Preconditions** | User A authenticated |
| **Test data** | `$TOKEN_A`; payloads below |

**Steps**
1. POST with `{ "article": { "description": "x", "body": "y" } }` (no `title`).
2. POST with `{ "article": { "title": "T", "body": "y" } }` (no `description`).
3. POST with `{ "article": { "title": "T", "description": "x" } }` (no `body`).
4. POST with a completely empty body `{}`.

**Expected result**
- Each returns `422 Unprocessable Entity` (RealWorld validation convention).
- Body is exactly the standard error shape `{ "errors": { "body": [ "<message>" ] } }` with a
  non-empty message array naming the missing field(s).
- No article is created in any case.

**Pass/Fail criteria**: PASS if all four return 422 with the exact `{ errors: { body: [...] } }`
shape and nothing is persisted. A 200, a 500, or a differently-shaped error is a FAIL.
**Cleanup**: None (nothing should be created).

---

### TC-API-10 — GET /api/articles/:slug retrieves a single article (happy path)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-12 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | The TC-API-06 article exists (`$SLUG`) |
| **Test data** | `$SLUG`; optionally `$TOKEN_A` |

**Steps**
1. `curl -s -i http://localhost:3000/api/articles/$SLUG` (no auth).
2. Repeat with `-H "Authorization: Token $TOKEN_A"`.

**Expected result**
- Both return `200 OK` with top-level `article` and the full field set (per TC-API-01), including
  `tagList` and the populated `author`.
- Unauthenticated: `author.following` == `false`, `favorited` == `false`.
- Authenticated as author: fields reflect A's relationship (e.g. `favorited` per A's state).

**Pass/Fail criteria**: PASS if the correct single article is returned with full shape in both
modes. Wrong article, missing fields, or a non-200 is a FAIL.
**Cleanup**: None.

---

### TC-API-11 — GET /api/articles/:slug for a non-existent slug (negative)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2, AC-5 / REQ-F-12 |
| **Type** | API (negative) |
| **Priority** | P2 |
| **Preconditions** | Local instance running |
| **Test data** | A slug known not to exist, e.g. `this-slug-does-not-exist-zzz` |

**Steps**
1. `curl -s -i http://localhost:3000/api/articles/this-slug-does-not-exist-zzz`.

**Expected result**
- `404 Not Found`. **TO CONFIRM: the old backend's status for an unknown slug (404 vs 422) — verify
  parity in TC-API-16.**
- Body matches the old backend's error shape (standard `{ errors: { body: [...] } }` or empty).
- No 500.

**Pass/Fail criteria**: PASS if the status matches the old backend and it is not a 500. A 200 or a
500 is a FAIL.
**Cleanup**: None.

---

### TC-API-12 — PUT /api/articles/:slug updates fields + re-associates tags (happy path)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-12 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | TC-API-06 article exists (`$SLUG`), owned by User A |
| **Test data** | `$TOKEN_A` |

**Steps**
1. `curl -s -i -X PUT http://localhost:3000/api/articles/$SLUG -H "Authorization: Token $TOKEN_A" -H "Content-Type: application/json" -d '{ "article": { "title": "How to Train Your Dragon v2", "tagList": ["dragons","flying"] } }'`.
2. Read the response; note the new slug (if any) and tagList.
3. `GET` the article at its current slug and confirm the persisted state.

**Expected result**
- `200 OK`; `article.title` == `How to Train Your Dragon v2`.
- `article.description` and `article.body` are unchanged (partial update).
- `article.tagList` now equals `["dragons","flying"]` — `training` removed, `flying` added
  (tag re-association on update). **TO CONFIRM: whether a title change regenerates the slug on the
  ported handler — confirm with dev; if it does, subsequent GET must use the new slug.**
- The persisted GET in step 3 reflects the same values.

**Pass/Fail criteria**: PASS if the update persists, only the sent fields change, and tagList is
correctly re-associated. Overwriting untouched fields to null, or stale tags, is a FAIL.
**Cleanup**: DELETE the article with `$TOKEN_A`.

---

### TC-API-13 — DELETE /api/articles/:slug removes the article (happy path)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-12 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | An article owned by User A exists (`$SLUG`) |
| **Test data** | `$TOKEN_A` |

**Steps**
1. `curl -s -i -X DELETE http://localhost:3000/api/articles/$SLUG -H "Authorization: Token $TOKEN_A"`.
2. `curl -s -i http://localhost:3000/api/articles/$SLUG`.

**Expected result**
- Step 1: `200 OK` (or `204 No Content` — **TO CONFIRM: match the old backend, TC-API-16**).
- Step 2: `404 Not Found` — the article is gone.
- The article no longer appears in `GET /api/articles`.

**Pass/Fail criteria**: PASS if delete succeeds and the article is subsequently absent. A lingering
article is a FAIL.
**Cleanup**: None (delete is the cleanup).

---

### TC-API-14 — DELETE/PUT by a non-author is forbidden (negative / authz)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-17 |
| **Type** | API (negative / authz) |
| **Priority** | P1 |
| **Preconditions** | An article owned by User A exists (`$SLUG`); User B authenticated |
| **Test data** | `$TOKEN_B` |

**Steps**
1. `curl -s -i -X PUT http://localhost:3000/api/articles/$SLUG -H "Authorization: Token $TOKEN_B" -H "Content-Type: application/json" -d '{ "article": { "title": "Hijacked" } }'`.
2. `curl -s -i -X DELETE http://localhost:3000/api/articles/$SLUG -H "Authorization: Token $TOKEN_B"`.
3. `GET /api/articles/$SLUG` and confirm it is unchanged and still present.

**Expected result**
- Steps 1 and 2 return `403 Forbidden` (a non-author may not edit/delete). **TO CONFIRM: whether the
  old backend returns 403 or 401 for a non-author — verify parity; also cross-referenced by
  security-test-steps TC-SEC-03.**
- The article is unchanged (title still original) and still present after step 3.

**Pass/Fail criteria**: PASS if both attempts are rejected (403/401 as per old backend) and the
article is untouched. A successful edit/delete by B is a FAIL and a security defect.
**Cleanup**: Owner A deletes the article afterwards.

---

### TC-API-15 — GET /api/tags returns all tags (happy + shape)

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-F-14 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | Articles exist carrying at least tags `dragons` and `training` |
| **Test data** | None (public) |

**Steps**
1. `curl -s -i http://localhost:3000/api/tags`.
2. Create a new article with a brand-new tag `unicorns`, then re-run step 1.

**Expected result**
- Step 1: `200 OK`; body is exactly `{ "tags": [ "<string>", ... ] }` — a single top-level `tags`
  key whose value is an array of strings. Includes `dragons` and `training`.
- No auth required.
- Step 2: after adding an article tagged `unicorns`, the `tags` array now includes `unicorns`.
- Negative sub-check: send `POST /api/tags` — expect `405 Method Not Allowed` or `404`
  (tags is read-only). **TO CONFIRM: expected method-not-allowed behaviour.**

**Pass/Fail criteria**: PASS if the shape is `{ tags: [...] }` of strings and it reflects existing +
newly added tags. A wrapped/renamed key, wrong element type, or missing tags is a FAIL.
**Cleanup**: DELETE the `unicorns` article created in step 2.

---

### TC-API-16 — Old-vs-new response-shape parity across all operations (AC-5)

| Field | Value |
|-------|-------|
| **Traces to** | AC-5 / REQ-F-12, REQ-F-14 |
| **Type** | API (parity / regression) |
| **Priority** | P1 |
| **Preconditions** | BOTH the new Next.js app (`:3000`) AND the old Express backend (`:3001`) running against equivalent seeded data; the SAME user accounts exist in both |
| **Test data** | `$TOKEN_A`/`$TOKEN_B` obtained separately from each backend's `/users/login` |

**Steps**
For each operation below, call the OLD backend and the NEW backend with identical inputs, save each
JSON body to a file, and diff the normalized structure (sort keys; ignore volatile values like
`createdAt`/`updatedAt`/`token`/`slug` suffixes, compare the KEY SET and value TYPES):
1. List global feed: `GET /api/articles?limit=5` on both.
2. Personal feed: `GET /api/articles/feed` with each backend's token.
3. Create: `POST /api/articles` with the identical sample payload on both.
4. Read: `GET /api/articles/:slug` for the created article on both.
5. Update: `PUT /api/articles/:slug` with an identical patch on both.
6. Delete: `DELETE /api/articles/:slug` on both.
7. Tags: `GET /api/tags` on both.
8. Error: `POST /api/articles` with a missing-title payload on both.
9. Error: `GET /api/articles/does-not-exist` on both.

Suggested normalize+diff helper (run per pair):
`diff <(curl -s "OLD_URL" | jq -S 'del(.. | .createdAt?, .updatedAt?, .token?)') <(curl -s "NEW_URL" | jq -S 'del(.. | .createdAt?, .updatedAt?, .token?)')`

**Expected result**
- For every operation the **HTTP status code matches** old vs new.
- The **JSON key set and value types match** old vs new (top-level and nested `author`/`tagList`).
- The **error shape** for steps 8–9 is byte-for-byte the same envelope `{ "errors": { "body": [...] } }`
  in both backends (message text may differ; the structure must not).

**Pass/Fail criteria**: PASS only if status codes and structural shapes are identical across all 9
operations. Any status mismatch, extra/missing/renamed key, or differing error envelope is a FAIL
against AC-5.
**Cleanup**: DELETE any articles created during the parity run on both backends.
