# Security Test Plan — #23 Favorites & Comments API (Story 1.5)

**Purpose**: Verify authentication is required for mutating operations and that comment deletion is
restricted to the comment's own author (authorization / IDOR). Black-box, derived from acceptance
criteria only.

**Scope**: Auth enforcement on favorite/unfavorite and comment add/delete; author-only comment
deletion (403 for another user); absence of sensitive data leakage in error responses.

**Security Baseline mapping**: SECURITY-07 (Access Control / authorization enforcement) and the
authentication requirements of the baseline. TO CONFIRM: exact Security Baseline rule numbering with
the dev/security owner.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/nextjs-migration` |
| This story's merged PR | [PR #32](https://github.com/revanta-biswas/conduit-helix-test/pull/32) |
| Confirm the story is in the build | `git log --oneline \| grep -i "favorite\|comment"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING). This plan does not restate them. |
| Local base URL / port | `http://localhost:3000`, API under `/api/` |
| Local services that must be up | PostgreSQL (Sequelize-backed) |
| Test data / accounts to seed | **UserA** and **UserB**, each with a valid JWT. One article `existing-slug`. One comment on `existing-slug` authored by **UserA** (id = `commentIdA`). |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

**Auth convention**: `Authorization: Token <JWT>`. TO CONFIRM: exact header/scheme.

---

### TC-SEC-01 — Unauthenticated favorite is rejected (401)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 |
| **Type** | Security |
| **Priority** | P1 (critical path) |
| **Preconditions** | Local instance running. `existing-slug` exists. |
| **Test data** | Slug: `existing-slug`; NO `Authorization` header. |

**Steps**
1. Send `POST http://localhost:3000/api/articles/existing-slug/favorite` with **no** auth header.
2. Record status and body.
3. `GET /api/articles/existing-slug/comments` / inspect the article to confirm no favorite was created.

**Expected result**
- HTTP `401` (Unauthorized). TO CONFIRM: 401 vs 403 for a missing token.
- No favorite relationship is created; `favoritesCount` unchanged.

**Pass/Fail criteria**: PASS when a 401 (or documented auth-required status) is returned AND no state changed; FAIL if the favorite is applied or a 5xx is returned.
**Cleanup**: None (no state should have changed).

---

### TC-SEC-02 — Unauthenticated unfavorite is rejected (401)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 |
| **Type** | Security |
| **Priority** | P2 |
| **Preconditions** | `existing-slug` exists and is favorited by UserA. |
| **Test data** | Slug: `existing-slug`; NO auth header. |

**Steps**
1. Send `DELETE /api/articles/existing-slug/favorite` with no auth header.
2. Confirm UserA's favorite still exists afterward.

**Expected result**
- HTTP `401`; UserA's favorite is untouched.

**Pass/Fail criteria**: PASS on 401 with no state change.
**Cleanup**: None.

---

### TC-SEC-03 — Unauthenticated comment creation is rejected (401)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 |
| **Type** | Security |
| **Priority** | P1 |
| **Preconditions** | `existing-slug` exists. |
| **Test data** | Slug: `existing-slug`; NO auth header; Body: `{"comment":{"body":"anon comment"}}` |

**Steps**
1. Send `POST /api/articles/existing-slug/comments` with no auth header and the body above.
2. Record status.
3. `GET /api/articles/existing-slug/comments` and confirm "anon comment" is NOT present.

**Expected result**
- HTTP `401`; no comment created.

**Pass/Fail criteria**: PASS on 401 with no persisted comment; FAIL if the comment is created.
**Cleanup**: If a comment leaked in, delete it.

---

### TC-SEC-04 — Deleting another user's comment is forbidden (403 / IDOR)

| Field | Value |
|-------|-------|
| **Traces to** | AC-4, AC-2 |
| **Type** | Security |
| **Priority** | P1 (critical path) |
| **Preconditions** | `commentIdA` on `existing-slug` is authored by **UserA**. **UserB** holds a valid, different JWT. |
| **Test data** | Slug: `existing-slug`; comment id `commentIdA`; Header: `Authorization: Token <UserB-JWT>` |

**Steps**
1. Send `DELETE http://localhost:3000/api/articles/existing-slug/comments/commentIdA` authenticated as **UserB** (NOT the author).
2. Record status and body.
3. `GET /api/articles/existing-slug/comments` and confirm `commentIdA` STILL exists.

**Expected result**
- HTTP `403` (Forbidden), with a body matching the existing **ForbiddenError** shape used elsewhere in the API (AC-4). TO CONFIRM: exact ForbiddenError JSON shape (fields/keys) — compare to an existing 403 in the app.
- `commentIdA` is NOT deleted.

**Pass/Fail criteria**: PASS when status is 403, the body matches the ForbiddenError shape, and the comment remains; FAIL if UserB is able to delete it (IDOR) or any 2xx/5xx is returned.
**Cleanup**: None (comment should be untouched). If UserB somehow deleted it, this is a defect — raise it.

---

### TC-SEC-05 — Author CAN delete own comment (positive authorization control)

| Field | Value |
|-------|-------|
| **Traces to** | AC-4, AC-2 |
| **Type** | Security |
| **Priority** | P1 |
| **Preconditions** | A comment authored by **UserA** exists (`commentIdA`). |
| **Test data** | Slug: `existing-slug`; `commentIdA`; Header: `Authorization: Token <UserA-JWT>` |

**Steps**
1. Send `DELETE /api/articles/existing-slug/comments/commentIdA` authenticated as **UserA** (the author).
2. Record status; confirm the comment is gone via `GET .../comments`.

**Expected result**
- HTTP `2xx`; `commentIdA` no longer present. Confirms the author-only rule is scoped to the author and does not over-block.

**Pass/Fail criteria**: PASS when the author's own delete succeeds (2xx and comment removed).
**Cleanup**: None (comment removed by design).

---

### TC-SEC-06 — Invalid/expired token is rejected on favorite (401)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 |
| **Type** | Security |
| **Priority** | P2 |
| **Preconditions** | `existing-slug` exists. |
| **Test data** | Slug: `existing-slug`; Header: `Authorization: Token not-a-real-jwt.deadbeef.tampered` |

**Steps**
1. Send `POST /api/articles/existing-slug/favorite` with the malformed token above.
2. Record status and body.

**Expected result**
- HTTP `401`.
- Error body does NOT leak stack traces, JWT internals, DB errors, or secrets (generic auth error only).

**Pass/Fail criteria**: PASS on 401 with a non-leaking error body; FAIL on 500/stack trace or if the favorite is applied.
**Cleanup**: None.

---

### TC-SEC-07 — Comment delete by non-author leaks no sensitive data (info disclosure)

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 |
| **Type** | Security |
| **Priority** | P3 |
| **Preconditions** | Same as TC-SEC-04. |
| **Test data** | Slug: `existing-slug`; `commentIdA`; Header: `Authorization: Token <UserB-JWT>` |

**Steps**
1. Perform the forbidden delete from TC-SEC-04.
2. Inspect the 403 response body and any server-side log lines visible in the local console.

**Expected result**
- The 403 body contains no DB internals, no other user's PII (e.g., UserA's email), no stack trace.
- Local logs do not print the JWT or secrets.

**Pass/Fail criteria**: PASS when the response and logs contain no sensitive data; FAIL if internal/PII/secret data is exposed.
**Cleanup**: None.
