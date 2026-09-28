# Security Test Plan — #21 User Profile API (Current User, Public Profiles & Follow)

**Purpose**: Verify, black-box, that authentication is enforced on the protected endpoints, that a
user cannot act as or mutate another user (IDOR), that the one anonymous-allowed endpoint leaks no
private state, and that injection-style inputs are handled safely. Derived from acceptance criteria
only; no application source code was read.

**Scope**: AuthN required (AC-4), authZ / IDOR on update and follow, anonymous access boundary on the
public profile, and input-handling robustness on the `:username` path segment and the update payload.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/nextjs-migration` |
| This story's merged PR | [PR #30](https://github.com/revanta-biswas/conduit-helix-test/pull/30) |
| Confirm the story is in the build | `git log --oneline \| grep -i "#30"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING). This plan does not restate them. |
| Local base URL / port | `http://localhost:3000`, API under `http://localhost:3000/api` |
| Local services that must be up | PostgreSQL (via Sequelize) |
| Test data / accounts to seed | **alice** and **bob** (registered users, known passwords); alice's `bio`/`image` non-empty. Log in via the Story 1.2 auth endpoint to obtain each user's credential (TO CONFIRM: exact login route + credential transport — JWT header `Authorization: Token <jwt>` vs session cookie) |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

> **Auth convention note**: "authenticate as X" = attach X's valid Story-1.2 credential; "no auth" =
> omit both the `Authorization` header and any session cookie. Exact transport is TO CONFIRM.

---

### TC-SEC-01 — All protected endpoints reject requests with no credential

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-F-11, REQ-F-13 |
| **Type** | Security |
| **Priority** | P1 (critical path) |
| **Security Baseline** | Access control / authentication enforced |
| **Preconditions** | SUT running; bob seeded |
| **Test data** | No credential |

**Steps**
1. Send each of the following with **no** auth header and **no** session cookie, recording the status of each:
   a. `GET http://localhost:3000/api/user`
   b. `PUT http://localhost:3000/api/user` (body `{ "user": { "bio": "x" } }`)
   c. `POST http://localhost:3000/api/profiles/bob/follow`
   d. `DELETE http://localhost:3000/api/profiles/bob/follow`

**Expected result**
- Every one of (a)–(d) returns `401 Unauthorized` (TO CONFIRM: 401 vs 403 for missing auth — Conduit uses 401).
- No user data is returned and no follow relationship is created/removed (verify follow state unchanged via an authenticated profile GET afterward).

**Pass/Fail criteria**: PASS only when all four protected endpoints reject the credential-less request and no state changes. Any 200 (or any successful mutation) on a credential-less request is a FAIL.
**Cleanup**: None.

---

### TC-SEC-02 — Protected endpoints reject a tampered / invalid credential

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-F-11, REQ-F-13 |
| **Type** | Security |
| **Priority** | P1 (critical path) |
| **Security Baseline** | JWT/session integrity |
| **Preconditions** | SUT running; alice seeded and logged in (to obtain a real credential to tamper) |
| **Test data** | (a) a syntactically-valid-looking but forged token, e.g. `Authorization: Token eyJhbGciOiJIUzI1NiJ9.tampered.signature`; (b) alice's real token with its last 5 characters altered; (c) an expired token if one is obtainable (TO CONFIRM: token expiry from Story 1.2) |

**Steps**
1. Send `GET http://localhost:3000/api/user` with credential (a). Record status.
2. Send `GET http://localhost:3000/api/user` with credential (b) (alice's token, signature corrupted). Record status.
3. If (c) is available, send `GET http://localhost:3000/api/user` with the expired token. Record status.

**Expected result**
- All three return `401 Unauthorized`; no user data returned.
- A corrupted-signature token is NOT accepted as alice.

**Pass/Fail criteria**: PASS when forged, tampered, and expired credentials are all rejected 401 with no data leak. Accepting any of them (200 with user data) is a FAIL and a serious defect.
**Cleanup**: None.

---

### TC-SEC-03 — IDOR: PUT /api/user only ever updates the caller's own record

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-4 / REQ-F-11 |
| **Type** | Security |
| **Priority** | P1 (critical path) |
| **Security Baseline** | Access control (IDOR / broken object-level authorization) |
| **Preconditions** | SUT running; alice and bob seeded and both logged in |
| **Test data** | alice's credential; a payload that attempts to target bob, e.g. `{ "user": { "username": "bob", "email": "bob@example.com", "bio": "hijacked by alice" } }` |

**Steps**
1. Note bob's current `bio` (GET `/api/profiles/bob`).
2. Authenticated as **alice**, send `PUT http://localhost:3000/api/user` with the bob-targeting payload above. Record status and body.
3. GET `/api/profiles/bob` (any requester) and note bob's `bio`.
4. Authenticated as alice, GET `/api/user` and note whose record changed.

**Expected result**
- The update applies ONLY to alice's own record — bob's `bio` in step 3 is unchanged.
- The server does not let alice overwrite bob's account by supplying bob's identifiers. (TO CONFIRM: whether the API rejects a username/email that collides with another user with a `422`, or silently ignores the identity fields and updates only alice — either is acceptable so long as bob is untouched and alice is not duplicated.)
- No error exposes internal identifiers or stack traces.

**Pass/Fail criteria**: PASS when bob's record is provably unchanged and alice cannot assume bob's identity. Any change to bob's data, or alice's record being merged with bob's, is a critical FAIL.
**Cleanup**: Restore alice's original `bio`/`email`/`username` if altered.

---

### TC-SEC-04 — IDOR / self-target: follow is attributed to the caller, not spoofable

| Field | Value |
|-------|-------|
| **Traces to** | AC-3, AC-4 / REQ-F-13 |
| **Type** | Security |
| **Priority** | P1 (critical path) |
| **Security Baseline** | Access control (the follower is bound to the authenticated identity) |
| **Preconditions** | SUT running; alice and bob seeded and logged in |
| **Test data** | alice's credential; bob's credential; usernames alice, bob |

**Steps**
1. Authenticated as **alice**, `POST http://localhost:3000/api/profiles/bob/follow`.
2. Authenticated as **bob** (a different account), `GET http://localhost:3000/api/profiles/alice` and note `following`.
3. Authenticated as **bob**, `GET http://localhost:3000/api/profiles/bob` (self).
4. Attempt to have alice follow herself: authenticated as alice, `POST http://localhost:3000/api/profiles/alice/follow`; record status and the resulting `following` on `GET /api/profiles/alice` as alice.

**Expected result**
- Step 1 creates only the alice→bob relationship. In step 2, bob viewing alice shows `following:false` (alice following bob does NOT make bob follow alice — the relationship is directional and tied to the caller).
- Step 3: bob viewing his own profile — `following` is `false` (TO CONFIRM: expected `following` value when viewing your own profile; Conduit convention is `false`).
- Step 4 (follow self): TO CONFIRM whether self-follow is rejected (`4xx`/`422`) or silently ignored. It must NOT produce a `following:true` self-relationship that misrepresents the graph, and must not 5xx.

**Pass/Fail criteria**: PASS when follow is strictly directional and bound to the authenticated caller, cross-account viewing is correct, and self-follow does not corrupt state or crash. A follow that appears on the wrong account, or a 5xx, is a FAIL.
**Cleanup**: Alice unfollows bob; remove any self-follow created in step 4.

---

### TC-SEC-05 — Anonymous public-profile access leaks no private/relationship data

| Field | Value |
|-------|-------|
| **Traces to** | AC-2, AC-4 / REQ-F-13 |
| **Type** | Security |
| **Priority** | P2 |
| **Security Baseline** | Access control / information disclosure |
| **Preconditions** | SUT running; bob seeded |
| **Test data** | No credential; target bob |

**Steps**
1. Send `GET http://localhost:3000/api/profiles/bob` with no credential.
2. Inspect the full response body and headers.

**Expected result**
- Status `200 OK`; body limited to the public profile shape (`username`, `bio`, `image`, `following:false`).
- The response does NOT include bob's `email`, password hash, token, internal database id, or any follower list.
- `following` is `false` for an anonymous requester (no relationship context available).

**Pass/Fail criteria**: PASS when the anonymous profile response contains only public fields with `following:false`. Presence of email, hash, token, internal id, or a non-false `following` is a FAIL.
**Cleanup**: None.

---

### TC-SEC-06 — Injection-style and malformed inputs are handled safely

| Field | Value |
|-------|-------|
| **Traces to** | AC-2, AC-3 / REQ-F-13 |
| **Type** | Security |
| **Priority** | P2 |
| **Security Baseline** | Input validation / injection resistance |
| **Preconditions** | SUT running; alice seeded and logged in |
| **Test data** | Malicious `:username` values and a script-bearing bio |

**Steps**
1. Send `GET http://localhost:3000/api/profiles/` + each of these URL-encoded usernames, authenticated as alice, recording status/body for each:
   a. `' OR '1'='1` (SQL-injection style)
   b. `%3Cscript%3Ealert(1)%3C/script%3E` (`<script>alert(1)</script>`)
   c. `../../etc/passwd` (path traversal style)
   d. a 512-character random string (over-long boundary)
2. Authenticated as alice, `PUT http://localhost:3000/api/user` with `{ "user": { "bio": "<script>alert('xss')</script>" } }`; then `GET /api/user` and inspect how `bio` is returned.

**Expected result**
- Step 1a–1d: each returns a well-formed `404 Not Found` (or `400`/`422`) — never a `500` server error, never a SQL error string, never contents of a filesystem path, never an unhandled exception/stack trace. No SQL error leakage confirms parameterized queries (Sequelize).
- Step 2: the script-bearing `bio` is stored/returned as an inert JSON string value (the API returns data, not HTML); it is not executed and no error is thrown. (TO CONFIRM: whether the API sanitizes/escapes bio on write or defers escaping to the UI layer — for an API, returning it as a plain JSON string is acceptable.)

**Pass/Fail criteria**: PASS when all malicious inputs yield safe 4xx/inert responses with no `5xx`, no SQL/stack-trace leakage, and no filesystem disclosure. Any `500` with an error string, SQL error, or path contents is a FAIL.
**Cleanup**: Restore alice's original `bio`.

---

### TC-SEC-07 — Wrong HTTP method / unsupported verb is rejected cleanly

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-3 / REQ-F-11, REQ-F-13 |
| **Type** | Security |
| **Priority** | P3 |
| **Security Baseline** | Error handling (no unhandled routes / method surface) |
| **Preconditions** | SUT running; alice seeded and logged in |
| **Test data** | alice's credential |

**Steps**
1. Send `DELETE http://localhost:3000/api/user` (unsupported verb; only GET/PUT are defined) with alice's credential. Record status.
2. Send `GET http://localhost:3000/api/profiles/bob/follow` (unsupported verb; only POST/DELETE defined) with alice's credential. Record status.

**Expected result**
- Each returns `405 Method Not Allowed` or `404 Not Found` (TO CONFIRM: which the Next.js Route Handlers return for an undefined method — either is acceptable), never a `500` and never a body that silently succeeds.

**Pass/Fail criteria**: PASS when unsupported verbs return a clean 404/405 with no side effect and no 5xx. A crash or an unintended state change is a FAIL.
**Cleanup**: None.
