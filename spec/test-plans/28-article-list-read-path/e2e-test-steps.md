# E2E Test Steps — Story 1.10 Article List Read Path Under the Amended REQ-F-17

**Purpose**: Verify the user-visible journeys AC-5 implies — a reader browsing the home feed sees the
effect of their own and others' writes on the next view (REQ-F-17@v2).

**Scope**: Complete journeys through the running app: create/edit/favorite/delete, then view the list.
Observed through the UI where the page exists (Home and Profile pages shipped in Stories 1.7 and 1.8),
with the API response as the corroborating observation.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `cr-test/epic-nextjs-migration` (epic cycle) |
| This story's PR | Story 1.10's `[STORY]` PR — merged into the epic branch before execution |
| Confirm the story is in the build | `git log --oneline \| grep "Story 1.10"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING). This plan does not restate them. |
| Local base URL / port | `http://localhost:3000` |
| Local services that must be up | PostgreSQL (the instance the epic branch's `.env.local` points at) |
| Test data / accounts to seed | `alice`, `bob` — registered through the UI at the start of each journey |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-E2E-01 — An author publishes an article and sees it at the top of the home feed

| Field | Value |
|-------|-------|
| **Traces to** | AC-5, AC-3 / REQ-F-17@v2 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | Local instance running; browser at `http://localhost:3000` |
| **Test data** | `alice`; article "E2E Publish" with tags `e2e`, `publish` |

**Steps**
1. Register and log in as `alice` through the UI.
2. Navigate to the editor and publish "E2E Publish" with tags `e2e` and `publish`.
3. Navigate to the home page and select the global feed.

**Expected result**
- "E2E Publish" is the first article in the global feed.
- Its card shows the author `alice` and both tags `e2e` and `publish`.
- Its favorite count reads `0` and the favorite control is in the un-favorited state.

**Pass/Fail criteria**: PASS when the article appears at the top of the feed on first view, with author
and both tags rendered. An empty tag area, a missing author, or the article being absent until a
refresh or restart is a FAIL.
**Cleanup**: Delete the article through the UI.

---

### TC-E2E-02 — A reader favorites an article and the count updates on the feed

| Field | Value |
|-------|-------|
| **Traces to** | AC-5, AC-3 / REQ-F-17@v2 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | Local instance running; `alice` has published "E2E Favorite" |
| **Test data** | `bob` as the reader |

**Steps**
1. Register and log in as `bob` through the UI.
2. On the home page global feed, locate "E2E Favorite" and note its favorite count.
3. Click the favorite control on that article's card.
4. Navigate away to the profile page, then back to the home page global feed.

**Expected result**
- After step 3 the count increments by 1 and the control shows the favorited state.
- After step 4 the article still shows the favorited state and the incremented count — the state came
  back from the server, not only from client state.

**Pass/Fail criteria**: PASS when the favorited state and count survive the navigation away and back.
A count that reverts, or a favorite control that resets, is a FAIL.
**Cleanup**: Unfavorite the article; delete it as `alice`.

---

### TC-E2E-03 — An author edits an article's tags and the feed reflects the change

| Field | Value |
|-------|-------|
| **Traces to** | AC-5 / REQ-F-17@v2 |
| **Type** | E2E |
| **Priority** | P2 |
| **Preconditions** | Local instance running; `alice` logged in with "E2E Edit" published, tagged `before` |
| **Test data** | New tag `after` |

**Steps**
1. As `alice`, open "E2E Edit" and choose to edit it.
2. Replace the tag `before` with `after` and save.
3. Navigate to the home page global feed.
4. Filter the feed by the tag `after`, then by the tag `before`.

**Expected result**
- Step 3: the article's card shows `after` and not `before`.
- Step 4: filtering by `after` returns the article; filtering by `before` does not.

**Pass/Fail criteria**: PASS when the edited tags are rendered and both filters behave accordingly. The
old tag still shown or still matching its filter is a FAIL.
**Cleanup**: Delete the article.

---

### TC-E2E-04 — A deleted article disappears from the feed (negative)

| Field | Value |
|-------|-------|
| **Traces to** | AC-5 / REQ-F-17@v2 |
| **Type** | E2E (negative) |
| **Priority** | P1 |
| **Preconditions** | Local instance running; `alice` logged in with "E2E Delete" published |
| **Test data** | None beyond the article |

**Steps**
1. As `alice`, confirm "E2E Delete" appears in the home page global feed.
2. Open the article and delete it.
3. Return to the home page global feed.
4. Navigate directly to the deleted article's URL.

**Expected result**
- Step 3: "E2E Delete" is absent from the feed.
- Step 4: the article page reports the article as not found rather than rendering it.

**Pass/Fail criteria**: PASS when the article is gone from both the feed and its own URL. A card
remaining in the feed is a FAIL.
**Cleanup**: None.

---

### TC-E2E-05 — A reader's personal feed shows only followed authors, fully rendered

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-3 / REQ-F-17@v2 |
| **Type** | E2E |
| **Priority** | P1 |
| **Preconditions** | Local instance running; `alice` and `carol` each have a published article |
| **Test data** | `bob` follows `alice` only |

**Steps**
1. Log in as `bob` through the UI.
2. Visit `alice`'s profile and follow her. Do not follow `carol`.
3. Navigate to the home page and select the personal feed.

**Expected result**
- `alice`'s article is listed; `carol`'s is not.
- The listed card shows author, tags and favorite count, with nothing blank.

**Pass/Fail criteria**: PASS when only the followed author's article is listed and rendered complete.
An unfollowed author's article appearing, or a card with blank author or tags, is a FAIL.
**Cleanup**: Unfollow `alice`; delete both articles.
