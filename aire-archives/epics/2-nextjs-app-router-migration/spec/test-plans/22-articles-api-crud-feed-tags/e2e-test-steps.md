# End-to-End Test Steps — #22 Articles API — CRUD, Feed & Tags

**Purpose**: Verify the API journeys the story implies work end to end across multiple endpoints:
create an article, see it surface in the global feed, filter it by tag, update it, and delete it —
each step's observable effect confirmed via a subsequent call. These are **API-level journeys** (this
story delivers Route Handlers, not UI).

**Scope**: create → list → filter-by-tag → update → delete lifecycle; personal-feed follow journey.
Black-box, chaining real HTTP calls.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/nextjs-migration` (story #22 merged via PR #31) |
| This story's merged PR | https://github.com/revanta-biswas/conduit-helix-test/pull/31 |
| Confirm the story is in the build | `git log --oneline \| grep -i "1.4\|#22\|articles"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING). This plan does not restate them. |
| Local base URL / port | `http://localhost:3000`, API under `/api/` |
| Local services that must be up | PostgreSQL (via Sequelize) |
| Test data / accounts to seed | User A `alice`, User B `bob` (see api-test-steps Common test data) |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-E2E-01 — Full article lifecycle: create → appears in global feed → filter by tag → update → delete

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-2, AC-3, AC-4 / REQ-F-12, REQ-F-14 |
| **Type** | E2E (API journey) |
| **Priority** | P1 |
| **Preconditions** | User A authenticated; DB in a known state |
| **Test data** | `$TOKEN_A`; unique tag `e2etag-<timestamp>` to isolate this run |

**Steps**
1. `POST /api/articles` (auth A) with title `E2E Lifecycle Article`, body/description set, and
   `tagList: ["e2etag-<ts>"]`. Record `$SLUG`.
2. `GET /api/articles` (no auth) and confirm the new article appears (search the returned list for
   `$SLUG`).
3. `GET /api/articles?tag=e2etag-<ts>` and confirm the article is returned and its `tagList` includes
   the tag.
4. `GET /api/tags` and confirm `e2etag-<ts>` is present.
5. `PUT /api/articles/$SLUG` (auth A) changing the title to `E2E Lifecycle Article (edited)` and
   `tagList: ["e2etag-<ts>","edited"]`.
6. `GET /api/articles/$SLUG` (using the current slug) and confirm the edited title and new tag.
7. `DELETE /api/articles/$SLUG` (auth A).
8. `GET /api/articles?tag=e2etag-<ts>` and confirm the article is gone.

**Expected result**
- Step 1: `200`, article created with correct slug and tag.
- Step 2: the article is present in the global feed with full shape (author, tagList, counts).
- Step 3: tag filter returns exactly the article; other articles without the tag are excluded.
- Step 4: the new tag is globally listed.
- Step 5–6: the edit persists; new tag associated, and the title reflects the change.
- Step 7: delete succeeds.
- Step 8: the article no longer surfaces under its tag; `articlesCount` for that tag is `0`.

**Pass/Fail criteria**: PASS only if every step's observable effect is confirmed in the following
step (create is visible, filter narrows correctly, edit persists, delete removes). Any broken link in
the chain is a FAIL.
**Cleanup**: If the run aborts mid-way, DELETE `$SLUG` with `$TOKEN_A`.

---

### TC-E2E-02 — Personal feed journey: follow author → their new article appears in /feed, others don't

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-12, REQ-F-17 |
| **Type** | E2E (API journey) |
| **Priority** | P1 |
| **Preconditions** | User A and User B exist; A initially does NOT follow B; a third author (`carol`) exists with an article. `TO CONFIRM: whether the follow endpoint (POST /api/profiles/:username/follow) is available in this build — it belongs to another story; if not present, seed the follow relationship in the DB.` |
| **Test data** | `$TOKEN_A`, `$TOKEN_B` |

**Steps**
1. As A, `GET /api/articles/feed` — record whether B's articles are present (they should NOT be yet).
2. Establish A-follows-B (via the follow endpoint if available, else DB seed).
3. As B, `POST /api/articles` creating a new article `Feed Visibility Test`.
4. As A, `GET /api/articles/feed` again.
5. Confirm carol's (unfollowed) article is NOT in A's feed.

**Expected result**
- Step 1: B's article absent from A's feed before following.
- Step 4: after following, B's new article IS present in A's personal feed, with `author.following`
  == `true`.
- Step 5: the unfollowed author's article never appears in A's feed.

**Pass/Fail criteria**: PASS if the personal feed reflects the follow relationship (followed authors
in, unfollowed authors out). B's article missing after following, or carol's article leaking in, is a
FAIL.
**Cleanup**: DELETE the article B created; unfollow / revert the seeded follow relationship.
