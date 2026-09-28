# End-to-End (E2E) Test Plan — #23 Favorites & Comments API (Story 1.5)

**Purpose**: Verify complete user-visible API journeys that this story enables end to end — a full
favorite/unfavorite lifecycle with the count moving correctly, and a full comment lifecycle
(add → list → delete). Black-box, derived from acceptance criteria only.

**Scope**: This story is an API slice; the "user-visible workflow" is the API journey a client
performs. E2E here means the whole sequence executed against the running local instance, asserting
on each observable step. (UI-driven E2E is out of scope for this API-only story — TO CONFIRM whether
a UI surface exists for these actions in this cycle.)

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/nextjs-migration` |
| This story's merged PR | [PR #32](https://github.com/revanta-biswas/conduit-helix-test/pull/32) |
| Confirm the story is in the build | `git log --oneline \| grep -i "favorite\|comment"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING). This plan does not restate them. |
| Local base URL / port | `http://localhost:3000`, API under `/api/` |
| Local services that must be up | PostgreSQL (Sequelize-backed) |
| Test data / accounts to seed | **UserA** with a valid JWT; article `existing-slug`. |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

**Auth convention**: `Authorization: Token <JWT>`. TO CONFIRM: exact scheme. Article read path
assumed `GET /api/articles/:slug` (TO CONFIRM).

---

### TC-E2E-01 — Favorite lifecycle: count increments then decrements

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-3 |
| **Type** | E2E |
| **Priority** | P1 (critical path) |
| **Preconditions** | Local instance running. `existing-slug` exists and is NOT favorited by UserA. UserA JWT available. |
| **Test data** | Slug: `existing-slug`; Header: `Authorization: Token <UserA-JWT>` |

**Steps**
1. `GET /api/articles/existing-slug` as UserA — record starting `favoritesCount` (C0) and `favorited` (expect `false`).
2. `POST /api/articles/existing-slug/favorite` as UserA — expect `favorited:true`, count `C0+1`.
3. `GET /api/articles/existing-slug` as UserA — confirm `favorited:true`, count `C0+1`.
4. `DELETE /api/articles/existing-slug/favorite` as UserA — expect `favorited:false`, count `C0`.
5. `GET /api/articles/existing-slug` as UserA — confirm `favorited:false`, count back to `C0`.

**Expected result**
- The count travels C0 → C0+1 → C0 across the journey and the `favorited` flag tracks true → false. Every read reflects the live state (AC-3), and the full round-trip returns to the original count with no drift.

**Pass/Fail criteria**: PASS when the count returns exactly to C0 after unfavoriting and the flag flips correctly at each step; FAIL on any drift, stale value, or wrong flag.
**Cleanup**: State is restored by step 4; verify `existing-slug` is unfavorited by UserA.

---

### TC-E2E-02 — Comment lifecycle: add → list → delete → list

| Field | Value |
|-------|-------|
| **Traces to** | AC-2, AC-4 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | `existing-slug` exists. UserA JWT available. |
| **Test data** | Slug: `existing-slug`; Body: `{"comment":{"body":"E2E lifecycle comment"}}`; UserA JWT. |

**Steps**
1. `GET /api/articles/existing-slug/comments` — record the initial comment count (N).
2. `POST /api/articles/existing-slug/comments` as UserA with the body above — capture new `id`.
3. `GET /api/articles/existing-slug/comments` — confirm count is `N+1` and the new comment (author UserA) is present.
4. `DELETE /api/articles/existing-slug/comments/<id>` as UserA (author) — expect 2xx.
5. `GET /api/articles/existing-slug/comments` — confirm count is back to `N` and the comment is gone.

**Expected result**
- The comment is created, becomes visible in the list, is removable by its author, and disappears from the list — the full add/list/delete journey behaves consistently, count returning to N.

**Pass/Fail criteria**: PASS when the list count moves N → N+1 → N and the specific comment appears then disappears; FAIL otherwise.
**Cleanup**: State restored by step 4.

---

### TC-E2E-03 — Blocked journey: unauthenticated user cannot favorite or comment (negative journey)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-2 |
| **Type** | E2E |
| **Priority** | P2 |
| **Preconditions** | `existing-slug` exists. No auth token used. |
| **Test data** | Slug: `existing-slug`; NO `Authorization` header. |

**Steps**
1. `GET /api/articles/existing-slug` (no auth) — record `favoritesCount` (C0).
2. `POST /api/articles/existing-slug/favorite` (no auth) — expect `401`.
3. `POST /api/articles/existing-slug/comments` (no auth) with `{"comment":{"body":"blocked"}}` — expect `401`.
4. `GET /api/articles/existing-slug` (no auth) — confirm count still `C0`.
5. `GET /api/articles/existing-slug/comments` — confirm "blocked" comment absent.

**Expected result**
- Both mutating attempts return `401` and produce NO state change: the favorite count is unchanged and no comment was created. The negative journey confirms the auth boundary holds end to end.

**Pass/Fail criteria**: PASS when both mutations are rejected with 401 and no state changed; FAIL if any mutation succeeds anonymously.
**Cleanup**: None (nothing should have changed).
