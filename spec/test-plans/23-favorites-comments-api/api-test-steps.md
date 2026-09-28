# API Test Plan — #23 Favorites & Comments API (Story 1.5)

**Purpose**: Verify, from the outside, every favorites/comments endpoint added by this story — status
codes, response shapes, headers, auth enforcement, error paths and boundary values. Black-box:
derived only from the acceptance criteria, never from source.

**Scope**: `POST/DELETE /api/articles/:slug/favorite`, `GET/POST /api/articles/:slug/comments`,
`DELETE /api/articles/:slug/comments/:id`.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/nextjs-migration` |
| This story's merged PR | [PR #32](https://github.com/revanta-biswas/conduit-helix-test/pull/32) |
| Confirm the story is in the build | `git log --oneline \| grep -i "favorite\|comment"` (expect the Story 1.5 / PR #32 commit) |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING). This plan does not restate them. |
| Local base URL / port | `http://localhost:3000`, API under `/api/` |
| Local services that must be up | PostgreSQL (Sequelize-backed), reachable by the local app |
| Test data / accounts to seed | Two registered users: **UserA** and **UserB** (each with a valid JWT). At least one published article with a known `:slug` (referred to below as `existing-slug`). At least one comment authored by UserA on `existing-slug`. |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

**Auth convention used below**: authenticated requests send the Conduit-standard header
`Authorization: Token <JWT>`. **TO CONFIRM: exact auth scheme/header name** (`Token` vs `Bearer`) —
ask the dev; the RealWorld/Conduit convention is `Authorization: Token <jwt>`.

---

### TC-API-01 — Favorite an article (happy path)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-3 |
| **Type** | API |
| **Priority** | P1 (critical path) |
| **Preconditions** | Local instance running. `existing-slug` exists and is NOT yet favorited by UserA. UserA JWT available. |
| **Test data** | Slug: `existing-slug`; Header: `Authorization: Token <UserA-JWT>` |

**Steps**
1. Send `POST http://localhost:3000/api/articles/existing-slug/favorite` with UserA's auth header and no body.
2. Record the HTTP status and the response body.

**Expected result**
- HTTP `200` (TO CONFIRM: 200 vs 201 — RealWorld/Conduit convention is `200`).
- Response body contains an `article` object for `existing-slug` with `"favorited": true`.
- `article.favoritesCount` equals the article's prior count + 1 (compute fresh, not cached — AC-3).
- `Content-Type: application/json`.

**Pass/Fail criteria**: PASS when status is 200 and `favorited` is `true` and `favoritesCount` incremented by exactly 1; anything else FAIL.
**Cleanup**: Send `DELETE /api/articles/existing-slug/favorite` as UserA to restore the unfavorited state.

---

### TC-API-02 — Unfavorite an article (happy path)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-3 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | `existing-slug` IS currently favorited by UserA (run TC-API-01 first, or seed the favorite). |
| **Test data** | Slug: `existing-slug`; Header: `Authorization: Token <UserA-JWT>` |

**Steps**
1. Note the current `favoritesCount` (GET the article or read from TC-API-01's response).
2. Send `DELETE http://localhost:3000/api/articles/existing-slug/favorite` with UserA's auth header.
3. Record status and body.

**Expected result**
- HTTP `200`.
- Response `article.favorited` is `false`.
- `article.favoritesCount` equals the prior count − 1 (fresh, AC-3).

**Pass/Fail criteria**: PASS when status 200, `favorited` false, and count decremented by exactly 1.
**Cleanup**: None required (article left unfavorited).

---

### TC-API-03 — Double-favorite is idempotent (boundary)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-3 |
| **Type** | API |
| **Priority** | P2 |
| **Preconditions** | `existing-slug` not favorited by UserA at start. |
| **Test data** | Slug: `existing-slug`; Header: `Authorization: Token <UserA-JWT>` |

**Steps**
1. Send `POST /api/articles/existing-slug/favorite` (UserA). Record `favoritesCount` → call it C1.
2. Send `POST /api/articles/existing-slug/favorite` AGAIN (UserA). Record `favoritesCount` → C2.

**Expected result**
- Both responses return HTTP `200` with `favorited: true`.
- `C2 == C1` — favoriting twice does NOT double-count (the belongsToMany relationship is a set, not a multiset).
- TO CONFIRM: whether a second favorite returns 200 (idempotent) or a 4xx (already-favorited). Expected behaviour: idempotent 200 with unchanged count.

**Pass/Fail criteria**: PASS when the count does not increase on the second call and no 5xx occurs.
**Cleanup**: `DELETE /api/articles/existing-slug/favorite` (UserA).

---

### TC-API-04 — Favorite a non-existent slug returns 404 (negative)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | No article exists with slug `does-not-exist-zzz`. |
| **Test data** | Slug: `does-not-exist-zzz`; Header: `Authorization: Token <UserA-JWT>` |

**Steps**
1. Send `POST http://localhost:3000/api/articles/does-not-exist-zzz/favorite` with UserA's auth header.
2. Record status and body.

**Expected result**
- HTTP `404`.
- Response body is a JSON error (no favorite created, no article object with `favorited:true`).
- TO CONFIRM: exact 404 error body shape.

**Pass/Fail criteria**: PASS on 404 with no favorite side effect; FAIL on 200/500 or if a phantom favorite is created.
**Cleanup**: None.

---

### TC-API-05 — Unfavorite a non-existent slug returns 404 (negative)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 |
| **Type** | API |
| **Priority** | P2 |
| **Preconditions** | No article exists with slug `does-not-exist-zzz`. |
| **Test data** | Slug: `does-not-exist-zzz`; Header: `Authorization: Token <UserA-JWT>` |

**Steps**
1. Send `DELETE http://localhost:3000/api/articles/does-not-exist-zzz/favorite` (UserA auth).
2. Record status.

**Expected result**
- HTTP `404` (article not found).

**Pass/Fail criteria**: PASS on 404; FAIL on 200/500.
**Cleanup**: None.

---

### TC-API-06 — List comments for an article (happy path)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | `existing-slug` exists and has ≥1 comment authored by UserA. |
| **Test data** | Slug: `existing-slug`; no auth header required (TO CONFIRM: is GET comments public? RealWorld convention: public/optional-auth). |

**Steps**
1. Send `GET http://localhost:3000/api/articles/existing-slug/comments`.
2. Record status and body.

**Expected result**
- HTTP `200`.
- Response body contains a `comments` array; each element has at least `id`, `body`, `createdAt`, and an `author` object.
- The seeded UserA comment is present in the array.

**Pass/Fail criteria**: PASS when 200 and the array contains the seeded comment with the expected fields.
**Cleanup**: None.

---

### TC-API-07 — Add a comment (authenticated, happy path)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | `existing-slug` exists. UserA JWT available. |
| **Test data** | Slug: `existing-slug`; Header: `Authorization: Token <UserA-JWT>`; Body: `{"comment":{"body":"Great article, TC-API-07"}}` |

**Steps**
1. Send `POST http://localhost:3000/api/articles/existing-slug/comments` with UserA auth and the JSON body above.
2. Record status and body; capture the returned comment `id`.
3. Send `GET /api/articles/existing-slug/comments` and confirm the new comment appears.

**Expected result**
- POST returns HTTP `200` (TO CONFIRM: 200 vs 201) with a `comment` object echoing `body` = "Great article, TC-API-07" and an `author` = UserA.
- The subsequent GET includes the new comment.

**Pass/Fail criteria**: PASS when the comment is created and then listed; FAIL otherwise.
**Cleanup**: `DELETE /api/articles/existing-slug/comments/<new-id>` as UserA.

---

### TC-API-08 — Add a comment with empty/missing body (negative/boundary)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 |
| **Type** | API |
| **Priority** | P2 |
| **Preconditions** | `existing-slug` exists. UserA JWT available. |
| **Test data** | Slug: `existing-slug`; Header: `Authorization: Token <UserA-JWT>`; Body A: `{"comment":{"body":""}}`; Body B: `{}` |

**Steps**
1. Send `POST /api/articles/existing-slug/comments` (UserA auth) with Body A (empty body).
2. Record status. Repeat with Body B (missing `comment`).

**Expected result**
- HTTP `422` (validation error) or `400` for both. No comment created.
- TO CONFIRM: exact validation status (422 per RealWorld) and error body shape for empty comment body.

**Pass/Fail criteria**: PASS when a 4xx is returned and no comment is persisted; FAIL on 200/500 or a stored empty comment.
**Cleanup**: If a comment was erroneously created, delete it.

---

### TC-API-09 — Delete own comment (author-only, happy path)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2, AC-4 |
| **Type** | API |
| **Priority** | P1 |
| **Preconditions** | A comment authored by UserA exists on `existing-slug` (create one via TC-API-07 and capture its `id` = `commentIdA`). |
| **Test data** | Slug: `existing-slug`; `commentIdA`; Header: `Authorization: Token <UserA-JWT>` |

**Steps**
1. Send `DELETE http://localhost:3000/api/articles/existing-slug/comments/commentIdA` with UserA auth.
2. Record status.
3. Send `GET /api/articles/existing-slug/comments` and confirm the comment is gone.

**Expected result**
- DELETE returns HTTP `200` (TO CONFIRM: 200 vs 204).
- The subsequent GET no longer contains `commentIdA`.

**Pass/Fail criteria**: PASS when status is 2xx and the comment no longer appears in the list.
**Cleanup**: None (comment removed).

---

### TC-API-10 — Delete a non-existent comment id (negative/boundary)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 |
| **Type** | API |
| **Priority** | P2 |
| **Preconditions** | No comment with id `99999999` exists on `existing-slug`. |
| **Test data** | Slug: `existing-slug`; comment id `99999999`; Header: `Authorization: Token <UserA-JWT>` |

**Steps**
1. Send `DELETE /api/articles/existing-slug/comments/99999999` (UserA auth).
2. Record status.

**Expected result**
- HTTP `404` (comment not found).
- TO CONFIRM: 404 vs 403 when the comment id does not exist at all.

**Pass/Fail criteria**: PASS on 404 with no side effect; FAIL on 200/500.
**Cleanup**: None.
