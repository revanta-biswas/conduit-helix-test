# Integration Test Plan — #21 User Profile API (Current User, Public Profiles & Follow)

**Purpose**: Verify, black-box, that the Route Handlers and the PostgreSQL datastore (via Sequelize)
integrate correctly across the request boundary — that a follow written through one endpoint is
persisted and surfaced by a different endpoint, that the self-referential `belongsToMany` association
records the relationship, and that a profile update travels through to the datastore and back. Derived
from acceptance criteria only; no application source code was read.

**Scope**: The boundary between the API layer and the Postgres datastore, and the boundary between the
follow endpoints and the profile-read endpoint (state written by one, observed by another). Requester
identity is a second integration boundary — the follow state a profile reports must reflect the
authenticated caller.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/nextjs-migration` |
| This story's merged PR | [PR #30](https://github.com/revanta-biswas/conduit-helix-test/pull/30) |
| Confirm the story is in the build | `git log --oneline \| grep -i "#30"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING). This plan does not restate them. |
| Local base URL / port | `http://localhost:3000`, API under `http://localhost:3000/api` |
| Local services that must be up | PostgreSQL (via Sequelize), migrated and reachable by the app |
| Test data / accounts to seed | **alice**, **bob**, **carol** (registered users, known passwords); log in via Story 1.2 to obtain each credential (TO CONFIRM: login route + credential transport) |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-INT-01 — Follow written via POST is persisted and surfaced by the profile-read endpoint

| Field | Value |
|-------|-------|
| **Traces to** | AC-3, AC-2 / REQ-F-13 |
| **Type** | Integration |
| **Priority** | P1 (critical path) |
| **Preconditions** | SUT running; Postgres up; alice, bob seeded and alice logged in; alice does not follow bob |
| **Test data** | alice's credential; target bob |

**Steps**
1. As alice, `GET http://localhost:3000/api/profiles/bob` — confirm `following:false` (baseline read boundary).
2. As alice, `POST http://localhost:3000/api/profiles/bob/follow` — the write boundary (API → Postgres via the `belongsToMany` join table).
3. As alice, `GET http://localhost:3000/api/profiles/bob` again — the read boundary reflects the write.

**Expected result**
- Step 1: `following:false`.
- Step 2: `200 OK`, `following:true`.
- Step 3: `following:true` — the relationship written by the POST handler is read back through the separate GET handler, proving both endpoints share the same persisted join-table state.

**Pass/Fail criteria**: PASS when the follow written by POST is observable by a subsequent GET. If the GET still shows `following:false` after a successful POST, the write did not persist to the shared store — FAIL.
**Cleanup**: As alice, `DELETE /api/profiles/bob/follow`.

---

### TC-INT-02 — Follow relationship survives independent requests (persistence across the boundary)

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-F-13 |
| **Type** | Integration |
| **Priority** | P1 (critical path) |
| **Preconditions** | SUT running; Postgres up; alice, bob seeded; alice logged in |
| **Test data** | alice's credential; target bob |

**Steps**
1. As alice, `POST http://localhost:3000/api/profiles/bob/follow`.
2. Wait, then issue a brand-new authenticated request `GET http://localhost:3000/api/profiles/bob` as alice (fresh request, not a cached response — add a unique query string or disable client cache).
3. (If feasible) restart the app process while leaving Postgres running, then repeat the GET as alice.

**Expected result**
- The follow persists across independent requests (step 2 shows `following:true`).
- After an app restart with the datastore intact (step 3), the relationship is still `following:true` — confirming it lives in Postgres, not process memory. (TO CONFIRM: whether an app restart is practical in the local setup; if not, mark step 3 skipped and rely on step 2.)

**Pass/Fail criteria**: PASS when the relationship is durable across separate requests (and across a restart if tested). A relationship that disappears between requests or after restart is a FAIL.
**Cleanup**: As alice, `DELETE /api/profiles/bob/follow`.

---

### TC-INT-03 — DELETE removes the relationship from the shared store

| Field | Value |
|-------|-------|
| **Traces to** | AC-3, AC-2 / REQ-F-13 |
| **Type** | Integration |
| **Priority** | P1 (critical path) |
| **Preconditions** | SUT running; Postgres up; alice follows bob (run TC-INT-01 steps 1–2 first) |
| **Test data** | alice's credential; target bob |

**Steps**
1. Establish alice→bob follow (`POST .../bob/follow`); confirm `following:true` via GET.
2. As alice, `DELETE http://localhost:3000/api/profiles/bob/follow`.
3. As alice, `GET http://localhost:3000/api/profiles/bob`.

**Expected result**
- Step 2: `200 OK`, `following:false`.
- Step 3: `following:false` — the join-table row is removed and the read endpoint reflects it.

**Pass/Fail criteria**: PASS when the DELETE removes the relationship and the subsequent GET reports `following:false`. A lingering `following:true` after a successful DELETE is a FAIL.
**Cleanup**: None (baseline restored).

---

### TC-INT-04 — Follow state is per-requester (identity boundary)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2, AC-3 / REQ-F-13 |
| **Type** | Integration |
| **Priority** | P1 (critical path) |
| **Preconditions** | SUT running; Postgres up; alice, bob, carol seeded and all logged in |
| **Test data** | alice's, bob's, carol's credentials; target carol |

**Steps**
1. As alice, `POST http://localhost:3000/api/profiles/carol/follow` (alice follows carol; bob does not).
2. As alice, `GET http://localhost:3000/api/profiles/carol` — note `following`.
3. As bob, `GET http://localhost:3000/api/profiles/carol` — note `following`.
4. Anonymous (no credential), `GET http://localhost:3000/api/profiles/carol` — note `following`.

**Expected result**
- Step 2 (alice): `following:true`.
- Step 3 (bob): `following:false` (bob has no relationship to carol).
- Step 4 (anonymous): `following:false`.
- The SAME profile record yields a `following` value computed relative to each distinct requester identity — proving the read endpoint joins the profile against the caller's relationship, not a global flag.

**Pass/Fail criteria**: PASS when `following` differs correctly by requester (true for alice, false for bob and anonymous) for the same target. A shared/global `following` value across requesters is a FAIL.
**Cleanup**: As alice, `DELETE /api/profiles/carol/follow`.

---

### TC-INT-05 — Profile update propagates through the datastore to the public read endpoint

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-2 / REQ-F-11, REQ-F-13 |
| **Type** | Integration |
| **Priority** | P2 |
| **Preconditions** | SUT running; Postgres up; bob seeded and logged in |
| **Test data** | bob's credential; body `{ "user": { "bio": "integration-check bio", "image": "https://example.com/bob-new.png" } }` |

**Steps**
1. As bob, `PUT http://localhost:3000/api/user` with the body above (write boundary: API → Postgres).
2. As alice (a different requester), `GET http://localhost:3000/api/profiles/bob` (read boundary from another user's perspective).

**Expected result**
- Step 1: `200 OK` with the new `bio`/`image` echoed.
- Step 2: bob's public profile shows the updated `bio` = "integration-check bio" and `image` = the new URL — the update written via `PUT /api/user` is visible through the separate `GET /api/profiles/:username` endpoint, confirming both endpoints operate on the same persisted user record.

**Pass/Fail criteria**: PASS when the update made through the user endpoint is observable through the profile endpoint. A stale `bio`/`image` on the profile read is a FAIL.
**Cleanup**: As bob, `PUT /api/user` restoring bob's original `bio`/`image`.
