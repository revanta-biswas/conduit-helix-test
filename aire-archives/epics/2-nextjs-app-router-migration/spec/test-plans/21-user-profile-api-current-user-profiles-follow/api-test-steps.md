# API Test Plan — #21 User Profile API (Current User, Public Profiles & Follow)

**Purpose**: Verify, black-box, the contract-visible behaviour of the five Route Handlers this story
delivers — `GET /api/user`, `PUT /api/user`, `GET /api/profiles/:username`,
`POST /api/profiles/:username/follow`, `DELETE /api/profiles/:username/follow` — for status code,
response shape and headers. Every case is derived from the acceptance criteria only; no application
source code was read.

**Scope**: One case set per endpoint — happy path, documented error paths, auth present/absent, bad
payload, and boundary values. Response-shape parity with the existing Conduit spec (AC-5) is exercised
here and again as an explicit old-vs-new comparison case.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/nextjs-migration` |
| This story's merged PR | [PR #30](https://github.com/revanta-biswas/conduit-helix-test/pull/30) |
| Confirm the story is in the build | `git log --oneline \| grep -i "#30"` (or grep the merge commit for story 1.3) |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING). This plan does not restate them. |
| Local base URL / port | `http://localhost:3000`, API under `http://localhost:3000/api` |
| Local services that must be up | PostgreSQL (via Sequelize), reachable by the app |
| Reference backend for AC-5 parity | Existing Conduit backend at `http://localhost:3001/api` (TO CONFIRM: exact base URL/port of the legacy backend and that it is running against comparable seed data) |
| Test data / accounts to seed | Two registered users — **alice** (`alice@example.com`) and **bob** (`bob@example.com`), each with a known password; alice's profile has a non-empty `bio` and `image`. Obtain each user's auth token by logging in via the Story 1.2 auth endpoint (TO CONFIRM: exact login route + token/cookie mechanism from Story 1.2 — e.g. `POST /api/users/login` returning a JWT, and whether auth is sent as `Authorization: Token <jwt>` header or a session cookie) |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

> **Auth convention note (applies to every case below)**: The story says authentication is enforced
> "via Story 1.2 auth middleware". The exact transport is **TO CONFIRM** from Story 1.2. Throughout
> this plan, "authenticate as alice" means "attach alice's valid credential in whatever form Story 1.2
> defines (header token or session cookie)". Where a case says "no auth", send the request with **no**
> `Authorization` header and **no** session cookie.

---

### TC-API-01 — GET /api/user returns the authenticated user

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-11 |
| **Type** | API |
| **Priority** | P1 (critical path) |
| **Preconditions** | SUT running; alice seeded and logged in with a valid credential |
| **Test data** | alice's valid auth credential |

**Steps**
1. Send `GET http://localhost:3000/api/user` with alice's valid auth credential attached.
2. Record the HTTP status code, the `Content-Type` header, and the full JSON body.

**Expected result**
- Status `200 OK`.
- `Content-Type` is `application/json` (allow a `; charset=utf-8` suffix).
- Body is a JSON object shaped `{ "user": { "email": "...", "username": "...", "token": "...", "bio": ..., "image": ... } }` matching the Conduit spec — i.e. a top-level `user` key whose value carries `email`, `username`, `bio`, `image` and a `token`.
- `user.email` equals `alice@example.com` and `user.username` equals alice's username.

**Pass/Fail criteria**: PASS when status is 200 and the body is the `{ "user": {...} }` shape with alice's own email/username. Any other status, a missing `user` wrapper, or another user's data is a FAIL.
**Cleanup**: None (read-only).

---

### TC-API-02 — GET /api/user without authentication is rejected

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-4 / REQ-F-11 |
| **Type** | API |
| **Priority** | P1 (critical path) |
| **Preconditions** | SUT running |
| **Test data** | None (no credential) |

**Steps**
1. Send `GET http://localhost:3000/api/user` with **no** auth header and **no** session cookie.
2. Record the status code and body.

**Expected result**
- Status `401 Unauthorized` (TO CONFIRM: whether Story 1.2 middleware returns 401 vs 403 for missing auth — Conduit convention is 401).
- No user data (no `email`, `token`, etc.) is returned in the body.

**Pass/Fail criteria**: PASS when unauthenticated request is rejected with 401 (or the confirmed auth-failure status) and no user data leaks. A 200 with user data is a FAIL.
**Cleanup**: None.

---

### TC-API-03 — PUT /api/user updates the authenticated user's fields

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-11 |
| **Type** | API |
| **Priority** | P1 (critical path) |
| **Preconditions** | SUT running; alice seeded and logged in |
| **Test data** | alice's credential; body `{ "user": { "bio": "Updated bio for alice", "image": "https://example.com/alice.png" } }` |

**Steps**
1. Send `PUT http://localhost:3000/api/user` with alice's credential and `Content-Type: application/json`, body as in Test data.
2. Record status and body.
3. Send `GET http://localhost:3000/api/user` with alice's credential and record the body.

**Expected result**
- Step 1: status `200 OK`; body is `{ "user": {...} }` reflecting `bio` = "Updated bio for alice" and `image` = the supplied URL, with `email`/`username`/`token` still present.
- Step 3: the GET reflects the same updated `bio` and `image` (change persisted).

**Pass/Fail criteria**: PASS when the update returns 200 with the new values and the subsequent GET shows them persisted. A non-200, unpersisted change, or altered `email`/`username` not requested is a FAIL.
**Cleanup**: `PUT /api/user` again restoring alice's original `bio`/`image` (non-empty bio, original image URL).

---

### TC-API-04 — PUT /api/user with no auth / malformed payload is rejected

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-4 / REQ-F-11 |
| **Type** | API |
| **Priority** | P2 |
| **Preconditions** | SUT running; alice seeded |
| **Test data** | (a) no credential + valid body; (b) alice credential + malformed body `{ "user": { "email": 12345 } }` and non-JSON body `not-json` |

**Steps**
1. Send `PUT http://localhost:3000/api/user` with **no** auth and body `{ "user": { "bio": "x" } }`. Record status.
2. Send `PUT http://localhost:3000/api/user` with alice's credential, `Content-Type: application/json`, and body `not-json` (invalid JSON). Record status and body.
3. Send `PUT http://localhost:3000/api/user` with alice's credential and body `{ "user": { "email": 12345 } }` (wrong type). Record status and body.

**Expected result**
- Step 1: `401 Unauthorized` (or confirmed auth-failure status); no update applied.
- Step 2: a client-error status `400` (TO CONFIRM: exact status/body the handler returns for invalid JSON — Conduit typically returns `422` with `{ "errors": {...} }` for validation, `400` for unparseable JSON).
- Step 3: a client-error status `422`/`400` with an error body; alice's real email unchanged (verify via TC-API-01).

**Pass/Fail criteria**: PASS when unauthenticated update is rejected 401, and malformed/invalid payloads are rejected with a 4xx and no corrupt persistence. A 200 or a 5xx crash is a FAIL.
**Cleanup**: If any change slipped through, restore alice's original fields via TC-API-03 cleanup.

---

### TC-API-05 — GET /api/profiles/:username returns a public profile (authenticated requester)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-13 |
| **Type** | API |
| **Priority** | P1 (critical path) |
| **Preconditions** | SUT running; alice and bob seeded; alice logged in; alice does NOT follow bob yet |
| **Test data** | alice's credential; target username = bob |

**Steps**
1. Ensure alice does not follow bob (run TC-API-09 DELETE first if unsure).
2. Send `GET http://localhost:3000/api/profiles/bob` with alice's credential.
3. Record status and body.

**Expected result**
- Status `200 OK`.
- Body shaped `{ "profile": { "username": "bob", "bio": ..., "image": ..., "following": false } }` — top-level `profile` key carrying `username`, `bio`, `image` and a boolean `following`.
- `following` is `false` (alice does not follow bob).

**Pass/Fail criteria**: PASS when status 200, body is the `{ "profile": {...} }` shape with `following:false`. A wrong shape, missing `following`, or `following:true` is a FAIL.
**Cleanup**: None (read-only).

---

### TC-API-06 — GET /api/profiles/:username works for anonymous requester with following:false

| Field | Value |
|-------|-------|
| **Traces to** | AC-2, AC-4 / REQ-F-13 |
| **Type** | API |
| **Priority** | P1 (critical path) |
| **Preconditions** | SUT running; bob seeded |
| **Test data** | No credential; target username = bob |

**Steps**
1. Send `GET http://localhost:3000/api/profiles/bob` with **no** auth header and **no** session cookie.
2. Record status and body.

**Expected result**
- Status `200 OK` (this endpoint is the one exception that permits anonymous access, per AC-4).
- Body is `{ "profile": { "username": "bob", "bio": ..., "image": ..., "following": false } }`.
- `following` is `false` for the anonymous requester (no relationship exists).

**Pass/Fail criteria**: PASS when an anonymous request returns 200 with `following:false`. A 401/403 rejection, or `following:true`/omitted, is a FAIL.
**Cleanup**: None.

---

### TC-API-07 — GET /api/profiles/:username for a nonexistent user returns 404

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-13 |
| **Type** | API |
| **Priority** | P2 |
| **Preconditions** | SUT running; no user named `ghost_user_xyz` exists |
| **Test data** | alice's credential (and, in a second pass, no credential); target username = `ghost_user_xyz` |

**Steps**
1. Send `GET http://localhost:3000/api/profiles/ghost_user_xyz` with alice's credential. Record status and body.
2. Repeat with **no** credential. Record status and body.

**Expected result**
- Both requests: status `404 Not Found` (TO CONFIRM: exact status/body for an unknown profile — Conduit convention is 404, sometimes `422` with `{ "errors": {...} }`).
- No `profile` object is returned; an error body may be present.

**Pass/Fail criteria**: PASS when an unknown username returns 404 (or the confirmed not-found status) for both authenticated and anonymous requests, with no fabricated profile. A 200 with an empty/invented profile is a FAIL.
**Cleanup**: None.

---

### TC-API-08 — POST /api/profiles/:username/follow follows a user (happy path)

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-F-13 |
| **Type** | API |
| **Priority** | P1 (critical path) |
| **Preconditions** | SUT running; alice and bob seeded; alice logged in; alice does NOT currently follow bob |
| **Test data** | alice's credential; target username = bob |

**Steps**
1. Ensure alice does not follow bob (TC-API-09 first if needed).
2. Send `POST http://localhost:3000/api/profiles/bob/follow` with alice's credential (empty/no body).
3. Record status and body.
4. Send `GET http://localhost:3000/api/profiles/bob` with alice's credential and record `following`.

**Expected result**
- Step 2: status `200 OK`; body `{ "profile": { "username": "bob", "bio": ..., "image": ..., "following": true } }`.
- Step 4: the profile GET now shows `following: true` (relationship persisted).

**Pass/Fail criteria**: PASS when the follow returns 200 with `following:true` and the subsequent profile GET confirms `following:true`. A non-200 or `following` not becoming true is a FAIL.
**Cleanup**: Run TC-API-09 to unfollow, restoring the no-follow baseline.

---

### TC-API-09 — DELETE /api/profiles/:username/follow unfollows a user (happy path)

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-F-13 |
| **Type** | API |
| **Priority** | P1 (critical path) |
| **Preconditions** | SUT running; alice logged in; alice currently FOLLOWS bob (run TC-API-08 first) |
| **Test data** | alice's credential; target username = bob |

**Steps**
1. Ensure alice follows bob (TC-API-08 first).
2. Send `DELETE http://localhost:3000/api/profiles/bob/follow` with alice's credential.
3. Record status and body.
4. Send `GET http://localhost:3000/api/profiles/bob` with alice's credential and record `following`.

**Expected result**
- Step 2: status `200 OK`; body `{ "profile": { ... "following": false } }`.
- Step 4: profile GET shows `following: false` (relationship removed).

**Pass/Fail criteria**: PASS when unfollow returns 200 with `following:false` and the profile GET confirms `following:false`. Otherwise FAIL.
**Cleanup**: None (this restores the no-follow baseline).

---

### TC-API-10 — Follow/unfollow require authentication; nonexistent target 404; idempotency boundary

| Field | Value |
|-------|-------|
| **Traces to** | AC-3, AC-4 / REQ-F-13 |
| **Type** | API |
| **Priority** | P2 |
| **Preconditions** | SUT running; alice and bob seeded; alice logged in |
| **Test data** | (a) no credential; (b) alice credential + target `ghost_user_xyz`; (c) alice credential + repeat follow/unfollow |

**Steps**
1. Send `POST http://localhost:3000/api/profiles/bob/follow` with **no** auth. Record status.
2. Send `DELETE http://localhost:3000/api/profiles/bob/follow` with **no** auth. Record status.
3. Send `POST http://localhost:3000/api/profiles/ghost_user_xyz/follow` with alice's credential. Record status.
4. With alice authenticated: send `POST .../bob/follow` twice in a row; then `DELETE .../bob/follow` twice in a row. Record each status and the final `following` value via a profile GET.

**Expected result**
- Steps 1–2: `401 Unauthorized` (or confirmed auth-failure status); no relationship change.
- Step 3: `404 Not Found` (TO CONFIRM: not-found status/body for follow on unknown user).
- Step 4: repeated follow leaves `following:true` (no error / no duplicate relationship); repeated unfollow leaves `following:false` (TO CONFIRM: whether a duplicate follow or an unfollow-when-not-following returns 200 idempotently vs a 4xx — behaviour not fixed by AC). Final state must be `following:false`.

**Pass/Fail criteria**: PASS when unauthenticated follow/unfollow are rejected 401, follow on an unknown user returns 404, and repeated calls converge to a single, correct relationship state. A 5xx crash, duplicate relationships, or unauthenticated mutation is a FAIL.
**Cleanup**: Ensure alice no longer follows bob (final DELETE if needed).

---

### TC-API-11 — Response-shape parity with the existing Conduit backend (AC-5, old vs new)

| Field | Value |
|-------|-------|
| **Traces to** | AC-5 / REQ-F-11, REQ-F-13 |
| **Type** | API |
| **Priority** | P1 (critical path) |
| **Preconditions** | SUT (new) running at `http://localhost:3000`; the existing Conduit backend running at `http://localhost:3001` with equivalent seed users (alice, bob) and equivalent follow state (TO CONFIRM: legacy backend base URL/port and that its data mirrors the new instance) |
| **Test data** | alice's credential on **each** backend (log in separately against each); bob as target |

**Steps**
1. For each request below, issue it against BOTH `:3000` (new) and `:3001` (old), authenticating as alice on each:
   a. `GET /api/user`
   b. `PUT /api/user` with `{ "user": { "bio": "parity-check bio" } }`
   c. `GET /api/profiles/bob` (alice not following bob)
   d. `POST /api/profiles/bob/follow`
   e. `GET /api/profiles/bob` (now following)
   f. `DELETE /api/profiles/bob/follow`
2. For each pair, compare: HTTP status code, top-level JSON key(s) (`user` / `profile` / `errors`), the set of field names inside, and the field value types (string/boolean/null). Ignore values that are legitimately instance-specific (the `token` string, timestamps, absolute image URLs).
3. Record any structural difference (missing field, extra field, renamed key, changed type, different status) in the parity table below.

**Expected result**
- For every request pair, the new backend's status code and JSON structure (keys, nested field names, types, and the `following` boolean semantics) match the old backend's exactly.
- No field present in the old response is missing from the new one, and the new response introduces no contract-visible extra field.

**Pass/Fail criteria**: PASS when every compared response is structurally identical to the legacy backend (per the ignore-list in step 2). Any status-code mismatch, missing/renamed/extra field, or type change is a FAIL and should be raised as a defect.
**Cleanup**: Restore alice's `bio` on both backends; ensure alice does not follow bob on either.

**Parity record**
| Request | New status | Old status | Structural diff found? | Notes |
|---------|-----------|-----------|------------------------|-------|
| GET /api/user | | | | |
| PUT /api/user | | | | |
| GET /api/profiles/bob (not following) | | | | |
| POST /api/profiles/bob/follow | | | | |
| GET /api/profiles/bob (following) | | | | |
| DELETE /api/profiles/bob/follow | | | | |
