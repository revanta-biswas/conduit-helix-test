# Code Generation Plan — Story 1.3: User Profile API (Current User, Public Profiles & Follow)

**Tracker**: [#21](https://github.com/revanta-biswas/conduit-helix-test/issues/21) | **Epic**: Milestone #2 | **Branch**: story/1.3-user-profile-api
**Covers**: REQ-F-11, REQ-F-13

**Grounding**: story ACs (#1.3), requirements.md, architecture.md (ARCH-01 handlers->service, ARCH-02
no N+1, ARCH-04 contract parity), application-design.md (User Service, Profiles Service),
functional-design.md (self-follow prevention, idempotent toggle), plus backend/controllers/{user,profiles}.js.

## Plan Steps
- [x] **S1 — User service** (REQ-F-11) — `src/lib/services/user.js`: `getCurrent(user)` (returns the user
  with email + token echoed), `update(user, changes)` (bio/image/email/username/password; bcrypt-hash a
  new password; never write undefined). Auth enforced in the handler via requireSessionUser.
- [x] **S2 — Profiles service** (REQ-F-13) — `src/lib/services/profiles.js`: `getProfile(username, viewer)`
  -> `{ username, bio, image, following, followersCount }`; `toggleFollow(username, viewer, follow)`.
  🔴 following/followersCount computed via a single `count`/`has` query pair (ARCH-02 — NOT the legacy
  appendFollowers loop). Self-follow -> ValidationError (functional-design.md). Idempotent toggle.
- [x] **S3 — Route Handlers** (ARCH-01, ARCH-04):
  - `src/app/api/user/route.js` — GET (currentUser), PUT (update). requireSessionUser.
  - `src/app/api/profiles/[username]/route.js` — GET (public profile; soft auth for the following flag).
  - `src/app/api/profiles/[username]/follow/route.js` — POST (follow) / DELETE (unfollow). requireSessionUser.
- [x] **S4 — Unit tests (SH-LOOP-1, >=90%)** — user + profiles services (getCurrent, update, getProfile,
  follow/unfollow, self-follow rejection, idempotency).
- [x] **S5 — API & Contract tests** — the 4 endpoints: GET/PUT /api/user (200, 401 unauth), GET
  /api/profiles/:username (200, 404), POST/DELETE follow (200, 401, 404).
- [x] **S6 — Gherkin step defs (B1)** — tests/behavior/steps/story-1.3_steps.js.

## REQ/AC Trace
| Step | ACs | REQ-IDs |
|---|---|---|
| S1 | AC-1, AC-4 | REQ-F-11 |
| S2 | AC-2, AC-3 | REQ-F-13 |
| S3 | AC-1..4 | REQ-F-11, REQ-F-13 |
| S4/S5 | AC-1..4 | REQ-NF-06 |
| S6 | AC-1..4 | contract |

Trace complete (REQ-F-11,13 + AC-1..4 each in >=1 step).

## Notes
- API layer present -> API & Contract gate applies.
- following/followersCount use count+has queries, NOT the deferred appendFollowers loop (ARCH-02).
- Self-follow prevention is a NEW tightened rule (functional-design.md), added consistently with the
  "tighten validation" decision.
