# Security Test Steps — #22 Articles API — CRUD, Feed & Tags

**Purpose**: Verify authentication and authorization on the Articles endpoints (REQ-F-17): writes
require a valid token, and only the article's author may edit or delete it. Also verify injection-style
inputs are handled safely and no sensitive data leaks in responses.

**Scope**: Auth-required checks on `POST/PUT/DELETE /api/articles`, IDOR/ownership checks
(non-author edit/delete → forbidden), injection-style payloads, sensitive-data-in-response checks.
Maps to AIRE Security Baseline access-control and input-validation rules where applicable.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/nextjs-migration` (story #22 merged via PR #31) |
| This story's merged PR | https://github.com/revanta-biswas/conduit-helix-test/pull/31 |
| Confirm the story is in the build | `git log --oneline \| grep -i "1.4\|#22\|articles"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING). This plan does not restate them. |
| Local base URL / port | `http://localhost:3000`, API under `/api/` |
| Local services that must be up | PostgreSQL (via Sequelize) |
| Test data / accounts to seed | User A `alice` (author), User B `bob` (attacker/other) — see api-test-steps Common test data |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-SEC-01 — Write endpoints require authentication (no token → 401)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-17 (Security Baseline: access control) |
| **Type** | Security (authentication) |
| **Priority** | P1 |
| **Preconditions** | An article owned by A exists (`$SLUG`) for the PUT/DELETE cases |
| **Test data** | No `Authorization` header |

**Steps**
1. `POST /api/articles` with a valid body, no token.
2. `PUT /api/articles/$SLUG` with a valid body, no token.
3. `DELETE /api/articles/$SLUG`, no token.
4. `GET /api/articles/feed`, no token.

**Expected result**
- All four return `401 Unauthorized`.
- No state change occurs (the article is unchanged and still present after; no new article created).
- No article/feed data is returned in any 401 body.

**Pass/Fail criteria**: PASS if every write and the personal feed is refused without a token and
nothing is mutated. Any `200`/`2xx` without a token is a FAIL and a security defect.
**Cleanup**: None (nothing should change).

---

### TC-SEC-02 — Invalid / expired / tampered token is rejected

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-17 (Security Baseline: JWT security) |
| **Type** | Security (authentication) |
| **Priority** | P1 |
| **Preconditions** | Local instance running |
| **Test data** | (a) garbage `Authorization: Token abc.def.ghi`; (b) a valid JWT from A with its last character altered; (c) `TO CONFIRM: an expired token — ask dev how to mint one, or note as unverifiable if not feasible` |

**Steps**
1. `POST /api/articles` (valid body) with header `Authorization: Token abc.def.ghi`.
2. `POST /api/articles` (valid body) with a valid `$TOKEN_A` whose signature byte was flipped.
3. If an expired token is obtainable, repeat with it.

**Expected result**
- Every request returns `401 Unauthorized`; the tampered-signature token is NOT accepted.
- No article is created; no server error (500) and no stack trace in the body.

**Pass/Fail criteria**: PASS if all malformed/tampered tokens yield 401 and no article is created.
Accepting a tampered token, or a 500 revealing internals, is a FAIL.
**Cleanup**: Remove any wrongly-created article (itself a defect).

---

### TC-SEC-03 — Non-author cannot edit or delete another user's article (IDOR / ownership)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-17 (Security Baseline: access control / broken object-level authorization) |
| **Type** | Security (authorization) |
| **Priority** | P1 |
| **Preconditions** | An article owned by User A exists (`$SLUG`); User B is authenticated and is NOT the author |
| **Test data** | `$TOKEN_B` |

**Steps**
1. `PUT /api/articles/$SLUG` with `$TOKEN_B` and body `{ "article": { "body": "hijacked by bob" } }`.
2. `DELETE /api/articles/$SLUG` with `$TOKEN_B`.
3. As User A (owner), `GET /api/articles/$SLUG` and confirm it is unchanged and present.

**Expected result**
- Steps 1 and 2 return `403 Forbidden` (authenticated but not authorized). `TO CONFIRM: confirm old
  backend uses 403 (not 401) for a non-author — parity handled in api-test-steps TC-API-16.`
- The article's `body` in step 3 is still the original (not "hijacked by bob") and the article still
  exists.

**Pass/Fail criteria**: PASS if both attempts are forbidden and the article is untouched. A
successful edit or delete by a non-author is a critical FAIL (broken object-level authorization).
**Cleanup**: Owner A deletes the article afterwards.

---

### TC-SEC-04 — Injection-style inputs are stored/escaped safely, not executed

| Field | Value |
|-------|-------|
| **Traces to** | AC-2, AC-5 / REQ-F-17 (Security Baseline: input validation / injection) |
| **Type** | Security (injection) |
| **Priority** | P2 |
| **Preconditions** | User A authenticated |
| **Test data** | `$TOKEN_A`; malicious strings below |

**Steps**
1. `POST /api/articles` (auth A) with
   `title = "'; DROP TABLE articles;--"`, `description = "<script>alert(1)</script>"`,
   `body = "normal"`, `tagList = ["<img src=x onerror=alert(1)>"]`.
2. Read the create response.
3. `GET /api/articles` and `GET /api/articles/:slug` to read the stored values back.
4. `GET /api/tags`.
5. `GET /api/articles?tag=<img src=x onerror=alert(1)>` (URL-encoded).

**Expected result**
- The create succeeds or is validation-rejected with `422 { errors: { body: [...] } }` — but the DB
  is intact: the `articles` table still exists and `GET /api/articles` still works after step 1
  (SQL injection did not execute — confirms parameterized queries via Sequelize).
- The stored `title`/`description`/`tagList` are returned as **inert data** (the exact string, JSON-
  encoded), never interpreted; the API returns JSON with `Content-Type: application/json` so the
  `<script>` is not executed by the API.
- No `500`, no SQL error text, no stack trace in any response body.

**Pass/Fail criteria**: PASS if the DB survives, values round-trip as inert data, and no server/SQL
error leaks. A dropped table, an SQL error message, or a 500 is a critical FAIL.
**Cleanup**: DELETE the created article (if it was created).

---

### TC-SEC-05 — Responses and error bodies do not leak sensitive data

| Field | Value |
|-------|-------|
| **Traces to** | AC-5 / REQ-F-17 (Security Baseline: error handling / sensitive data exposure) |
| **Type** | Security (information disclosure) |
| **Priority** | P2 |
| **Preconditions** | An article by A exists; User A authenticated |
| **Test data** | `$TOKEN_A` |

**Steps**
1. `GET /api/articles` and `GET /api/articles/:slug` — inspect the `author` object.
2. Trigger an error: `POST /api/articles` (auth A) with a missing-title payload; inspect the 422 body.
3. Trigger a not-found: `GET /api/articles/does-not-exist`; inspect the body.

**Expected result**
- The embedded `author` object contains ONLY public profile fields (`username`, `bio`, `image`,
  `following`) — never `email`, `password`, `hash`, `salt`, or a JWT.
- Error responses (steps 2–3) contain only the `{ errors: { body: [...] } }` envelope — no stack
  trace, no file paths, no SQL, no framework internals.

**Pass/Fail criteria**: PASS if no sensitive field appears anywhere and errors are clean envelopes.
Any leaked credential/PII field or stack trace is a FAIL.
**Cleanup**: None.
