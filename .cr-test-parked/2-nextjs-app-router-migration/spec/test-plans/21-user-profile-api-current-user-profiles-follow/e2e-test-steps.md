# End-to-End (E2E) Test Plan — #21 User Profile API (Current User, Public Profiles & Follow)

**Purpose**: Verify, black-box, the complete API journeys this story implies as a single continuous
flow — a user authenticates, updates their profile, follows another user, sees the follow reflected,
then unfollows and sees it reverted. This exercises the endpoints in the sequence a real client would
use, across authentication and the follow/profile boundary. Derived from acceptance criteria only; no
application source code was read.

**Scope**: API-level end-to-end journeys (there is no UI in this story). Each journey is one continuous
sequence with a start state, a set of actions, and an observable end state.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/nextjs-migration` |
| This story's merged PR | [PR #30](https://github.com/revanta-biswas/conduit-helix-test/pull/30) |
| Confirm the story is in the build | `git log --oneline \| grep -i "#30"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING). This plan does not restate them. |
| Local base URL / port | `http://localhost:3000`, API under `http://localhost:3000/api` |
| Local services that must be up | PostgreSQL (via Sequelize) |
| Test data / accounts to seed | **alice**, **bob** (registered users, known passwords). The journey logs in via the Story 1.2 auth endpoint (TO CONFIRM: login route + credential transport) |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-E2E-01 — Authenticated user follows another and the profile reflects following=true, then reverts

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-2, AC-3, AC-4 / REQ-F-11, REQ-F-13 |
| **Type** | E2E |
| **Priority** | P1 (critical path) |
| **Preconditions** | SUT running; Postgres up; alice and bob seeded; alice does not follow bob at start |
| **Test data** | alice's login credentials; target bob |

**Steps**
1. Log in as alice via the Story 1.2 auth endpoint and capture the returned credential (token/cookie).
2. `GET http://localhost:3000/api/user` with the credential — confirm the current user is alice.
3. `PUT http://localhost:3000/api/user` with `{ "user": { "bio": "e2e journey bio" } }` — confirm `bio` updated.
4. `GET http://localhost:3000/api/profiles/bob` as alice — confirm `following:false` (start state).
5. `POST http://localhost:3000/api/profiles/bob/follow` as alice.
6. `GET http://localhost:3000/api/profiles/bob` as alice — confirm `following:true`.
7. `DELETE http://localhost:3000/api/profiles/bob/follow` as alice.
8. `GET http://localhost:3000/api/profiles/bob` as alice — confirm `following:false` (reverted).

**Expected result**
- Step 2: `200`, user is alice.
- Step 3: `200`, `bio` = "e2e journey bio".
- Step 4: `200`, `following:false`.
- Step 5: `200`, `following:true`.
- Step 6: `200`, `following:true` (follow observable on a fresh read).
- Step 7: `200`, `following:false`.
- Step 8: `200`, `following:false` (unfollow observable on a fresh read).

**Pass/Fail criteria**: PASS when the entire sequence completes with each step's expected status and the `following` flag correctly transitions false → true → false across the journey. Any step failing its expected outcome fails the journey.
**Cleanup**: Ensure alice no longer follows bob; restore alice's original `bio`.

---

### TC-E2E-02 — Anonymous user can view a public profile end-to-end but cannot mutate

| Field | Value |
|-------|-------|
| **Traces to** | AC-2, AC-4 / REQ-F-13 |
| **Type** | E2E |
| **Priority** | P2 |
| **Preconditions** | SUT running; bob seeded; no credential held |
| **Test data** | None (anonymous); target bob |

**Steps**
1. Without any credential, `GET http://localhost:3000/api/profiles/bob` — confirm the profile is viewable.
2. Without any credential, attempt `POST http://localhost:3000/api/profiles/bob/follow`.
3. Without any credential, attempt `GET http://localhost:3000/api/user`.

**Expected result**
- Step 1: `200`, public profile returned with `following:false`.
- Step 2: `401 Unauthorized` (or confirmed auth-failure status); no relationship created.
- Step 3: `401 Unauthorized`; no user data.

**Pass/Fail criteria**: PASS when an anonymous client can read the public profile (`following:false`) but every mutating/private call is rejected. A successful anonymous follow or a leaked `/api/user` response is a FAIL.
**Cleanup**: None.
