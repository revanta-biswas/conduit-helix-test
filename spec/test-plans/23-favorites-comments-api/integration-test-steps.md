# Integration Test Plan — #23 Favorites & Comments API (Story 1.5)

**Purpose**: Verify boundaries between the API layer, the Article<->User favorite association, the
comment store, and the article-read path — i.e., that a mutation through one endpoint produces the
correct observable effect when read back through another endpoint (fresh count, fresh `favorited`
flag, comment appearing/disappearing). Black-box, derived from acceptance criteria only.

**Scope**: favorite/unfavorite reflected in the article response's `favoritesCount` + `favorited`
flag (AC-3); comment add/delete reflected in the comment list (AC-2). Cross-endpoint consistency
through PostgreSQL/Sequelize.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/nextjs-migration` |
| This story's merged PR | [PR #32](https://github.com/revanta-biswas/conduit-helix-test/pull/32) |
| Confirm the story is in the build | `git log --oneline \| grep -i "favorite\|comment"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING). This plan does not restate them. |
| Local base URL / port | `http://localhost:3000`, API under `/api/` |
| Local services that must be up | PostgreSQL (Sequelize-backed) |
| Test data / accounts to seed | **UserA** and **UserB** with valid JWTs; article `existing-slug`. |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

**How to read the article back**: use the single-article read endpoint. TO CONFIRM: exact article
read path (RealWorld convention `GET /api/articles/:slug`) — used below to observe `favoritesCount`
and `favorited`.

---

### TC-INT-01 — Favorite via endpoint is reflected in the article read (fresh count + flag)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-3 |
| **Type** | Integration |
| **Priority** | P1 (critical path) |
| **Preconditions** | `existing-slug` exists and is NOT favorited by UserA. |
| **Test data** | Slug: `existing-slug`; UserA JWT. |

**Steps**
1. `GET /api/articles/existing-slug` as UserA. Record `favoritesCount` (C0) and `favorited` (should be `false`).
2. `POST /api/articles/existing-slug/favorite` as UserA.
3. `GET /api/articles/existing-slug` AGAIN as UserA. Record `favoritesCount` (C1) and `favorited`.

**Expected result**
- After step 2, the article read at step 3 shows `favorited: true` and `C1 == C0 + 1`.
- The favorite mutation on one endpoint is fully visible through the separate read endpoint — confirming the association write persisted to PostgreSQL and the count is computed fresh, not cached (AC-3).

**Pass/Fail criteria**: PASS when the read-back reflects `favorited:true` and count +1; FAIL if the read is stale or unchanged.
**Cleanup**: `DELETE /api/articles/existing-slug/favorite` as UserA.

---

### TC-INT-02 — Unfavorite is reflected in the article read (fresh decrement)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-3 |
| **Type** | Integration |
| **Priority** | P1 |
| **Preconditions** | `existing-slug` currently favorited by UserA. |
| **Test data** | Slug: `existing-slug`; UserA JWT. |

**Steps**
1. `GET /api/articles/existing-slug` as UserA. Record `favoritesCount` (C0), `favorited` = true.
2. `DELETE /api/articles/existing-slug/favorite` as UserA.
3. `GET /api/articles/existing-slug` as UserA. Record `favoritesCount` (C1), `favorited`.

**Expected result**
- `favorited: false` and `C1 == C0 - 1` on the read-back.

**Pass/Fail criteria**: PASS when the read reflects the removed favorite and decremented count.
**Cleanup**: None.

---

### TC-INT-03 — favoritesCount is fresh across two users (no stale cached counter)

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 |
| **Type** | Integration |
| **Priority** | P1 |
| **Preconditions** | `existing-slug` exists, not favorited by UserA or UserB. |
| **Test data** | Slug: `existing-slug`; UserA JWT and UserB JWT. |

**Steps**
1. `GET /api/articles/existing-slug` (any user). Record baseline count C0.
2. `POST /api/articles/existing-slug/favorite` as **UserA**.
3. `POST /api/articles/existing-slug/favorite` as **UserB**.
4. `GET /api/articles/existing-slug` as **UserA** → record count Ca and `favorited` (should be true for UserA).
5. `GET /api/articles/existing-slug` as **UserB** → record count Cb and `favorited` (should be true for UserB).
6. `GET /api/articles/existing-slug` unauthenticated (or as a third viewer) → record count Cn and `favorited` (should be false — not favorited by that viewer).

**Expected result**
- `Ca == Cb == Cn == C0 + 2` — the count reflects BOTH favorites and is identical regardless of who reads it (computed fresh each response, AC-3).
- `favorited` is per-viewer: true for UserA and UserB, false for the anonymous/third viewer.

**Pass/Fail criteria**: PASS when the count equals C0+2 on every read and the `favorited` flag is correctly per-viewer; FAIL on any stale/inconsistent count.
**Cleanup**: `DELETE /api/articles/existing-slug/favorite` as UserA and as UserB.

---

### TC-INT-04 — Added comment appears in the comment list (cross-endpoint)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 |
| **Type** | Integration |
| **Priority** | P1 |
| **Preconditions** | `existing-slug` exists. UserA JWT. |
| **Test data** | Slug: `existing-slug`; Body: `{"comment":{"body":"integration TC-INT-04"}}` |

**Steps**
1. `POST /api/articles/existing-slug/comments` as UserA with the body above. Capture the returned `id`.
2. `GET /api/articles/existing-slug/comments` (separate read).

**Expected result**
- The created comment (matching `id` and body) is present in the list returned by the read endpoint, with `author` = UserA — confirming the write persisted and is visible through the read path.

**Pass/Fail criteria**: PASS when the added comment appears in the list; FAIL if the list is stale/missing it.
**Cleanup**: `DELETE /api/articles/existing-slug/comments/<id>` as UserA.

---

### TC-INT-05 — Deleted comment disappears from the comment list (cross-endpoint)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2, AC-4 |
| **Type** | Integration |
| **Priority** | P1 |
| **Preconditions** | A comment authored by UserA exists on `existing-slug` (`commentIdA`). |
| **Test data** | Slug: `existing-slug`; `commentIdA`; UserA JWT. |

**Steps**
1. `GET /api/articles/existing-slug/comments` — confirm `commentIdA` is present.
2. `DELETE /api/articles/existing-slug/comments/commentIdA` as UserA (author).
3. `GET /api/articles/existing-slug/comments` again.

**Expected result**
- After deletion, `commentIdA` is absent from the list — the delete propagated to the store and is visible through the read path.

**Pass/Fail criteria**: PASS when the comment is gone from the list post-delete; FAIL if it lingers.
**Cleanup**: None.
