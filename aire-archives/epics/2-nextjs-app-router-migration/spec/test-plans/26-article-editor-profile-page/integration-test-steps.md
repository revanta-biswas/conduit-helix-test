# Integration Test Steps — #26 Article Editor & Profile Page

**Purpose**: Verify the boundaries this story crosses — the editor/profile **pages** driving the
Story 1.4 article Route Handlers and the profile API, and the resulting state changes surfacing in
OTHER views (global feed, profile My Articles / Favorited tabs, follow relationship). Each case
exercises one boundary from the outside and asserts the observable effect in a second surface. Black-box,
manual, executed against a locally built instance of the merged story.

**Scope**: page -> article API -> feed/profile reflection; page -> profile follow API -> follow
state reflection. Browser-observable and DevTools-Network-observable effects only — no source code read.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/nextjs-migration` |
| This story's merged PR | PR #34 — https://github.com/revanta-biswas/conduit-helix-test/pull/34 |
| Confirm the story is in the build | `git log --oneline \| grep -i "1.8"` (or search for the PR #34 merge commit) |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING). This plan does not restate them. |
| Local base URL / port | http://localhost:3000 |
| Local services that must be up | PostgreSQL (via Sequelize) reachable by the app; app server running on :3000 |
| Test data / accounts to seed | An "author" account and a "second user" account; ≥1 article to reflect across feed/profile |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-INT-01 — Editor create -> article API -> article visible in global feed

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-3 / REQ-F-22 |
| **Type** | Integration |
| **Priority** | P1 |
| **Preconditions** | SUT running; logged in as the author; DevTools Network panel open |
| **Test data** | Title: `INT Create Article`; Description: `integration test`; Body: `body text`; Tags: `int` |

**Steps**
1. Navigate to http://localhost:3000/editor and submit the Test data article.
2. In DevTools -> Network, capture the create request.
3. Navigate to the home page Global Feed and locate the article.

**Expected result**
- A POST to `/api/articles` is issued from the page and returns 2xx with a JSON body containing the
  created article (including its slug).
- The article created via the page is subsequently present in the global feed served by the feed API.

**Pass/Fail criteria**: PASS if the page's POST succeeds AND the article surfaces in the global feed.
No request, a non-2xx response, or absence from the feed is a FAIL.
**Cleanup**: Delete the created article.

---

### TC-INT-02 — Editor create -> article appears under the author's profile My Articles

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-F-22, REQ-F-23 |
| **Type** | Integration |
| **Priority** | P1 |
| **Preconditions** | SUT running; logged in as the author; an article just created via the editor |
| **Test data** | Author username: `e2e_author`; article title: `INT Create Article` |

**Steps**
1. After creating the article (TC-INT-01), navigate to http://localhost:3000/profile/e2e_author.
2. Ensure the My Articles tab is active.
3. In DevTools -> Network, capture the profile/articles request(s) the Server Component drives.

**Expected result**
- The profile page (Server Component) fetches the author's articles (e.g. `/api/articles?author=e2e_author`)
  and the newly created article is present in the My Articles list.

**Pass/Fail criteria**: PASS if the created article appears under the author's profile My Articles.
Absent, or the profile fetch failing, is a FAIL.
**Cleanup**: Delete the created article.

---

### TC-INT-03 — Editor edit -> article API update -> updated content reflected in feed and profile

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-F-22 |
| **Type** | Integration |
| **Priority** | P1 |
| **Preconditions** | SUT running; logged in as the author; an owned article with a known slug exists |
| **Test data** | Slug: `<owned-slug>`; New Title: `INT Edited Title` |

**Steps**
1. Open http://localhost:3000/editor/`<owned-slug>`, change the title, and submit.
2. In DevTools -> Network, capture the update request.
3. Navigate to the global feed and the author's profile My Articles; reload each once if needed.

**Expected result**
- A PUT to `/api/articles/<slug>` is issued and returns 2xx.
- After the update, the new title is reflected in the article view, the global feed listing, and the
  profile My Articles listing (allowing for a documented revalidation reload). TO CONFIRM: cache
  revalidation semantics on edit with the dev/BA.

**Pass/Fail criteria**: PASS if the page's PUT succeeds AND the change propagates to feed and profile.
A stale feed/profile after reload is a FAIL.
**Cleanup**: Restore the original title or delete the article.

---

### TC-INT-04 — Editor delete -> article API delete -> article removed from feed and profile

| Field | Value |
|-------|-------|
| **Traces to** | AC-5 / REQ-F-22, REQ-F-23 |
| **Type** | Integration |
| **Priority** | P1 |
| **Preconditions** | SUT running; logged in as the author; an owned article visible in feed and profile |
| **Test data** | Slug: `<owned-slug>` |

**Steps**
1. Trigger the Delete action for the owned article and confirm.
2. In DevTools -> Network, capture the delete request.
3. Navigate to the global feed and the author's profile My Articles; reload each once.
4. Open the article's old `/article/<slug>` URL directly.

**Expected result**
- A DELETE to `/api/articles/<slug>` is issued and returns 2xx.
- The article is absent from the global feed, absent from the author's profile My Articles, and its
  direct URL resolves to a not-found/empty state.

**Pass/Fail criteria**: PASS if the page's DELETE succeeds AND the article disappears from all three
surfaces. Remaining anywhere is a FAIL.
**Cleanup**: None (intentionally deleted).

---

### TC-INT-05 — Profile follow control -> profile API -> follow state persists and reflects

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-23 |
| **Type** | Integration |
| **Priority** | P1 |
| **Preconditions** | SUT running; logged in as the author; target user exists and is not currently followed |
| **Test data** | Target username: `e2e_second` |

**Steps**
1. Navigate to http://localhost:3000/profile/e2e_second.
2. With DevTools -> Network open, click Follow, then reload; then click Unfollow, then reload.

**Expected result**
- Follow issues a POST to `/api/profiles/e2e_second/follow` returning 2xx; the control shows followed
  state and persists across reload.
- Unfollow issues a DELETE to the same endpoint returning 2xx; the control returns to unfollowed and
  persists across reload.

**Pass/Fail criteria**: PASS if both requests succeed and the state persists per action. A control
that changes visually without a persisted API effect is a FAIL.
**Cleanup**: Leave the relationship unfollowed.

---

### TC-INT-06 — Favorited tab -> profile/articles API returns the user's favorited set only

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-23 |
| **Type** | Integration |
| **Priority** | P2 |
| **Preconditions** | SUT running; logged in as the author; the author has favorited ≥1 article authored by another user, and authored ≥1 of their own |
| **Test data** | Author username: `e2e_author` |

**Steps**
1. Navigate to http://localhost:3000/profile/e2e_author and switch to the Favorited Articles tab.
2. In DevTools -> Network, capture the request the tab triggers (e.g. `/api/articles?favorited=e2e_author`).

**Expected result**
- The favorited request returns 2xx and the list shown contains the author's favorited articles
  (authored by others), NOT their own authored articles.

**Pass/Fail criteria**: PASS if the Favorited tab shows only the favorited set from the API. Showing
authored articles under Favorited is a FAIL.
**Cleanup**: None.

---

### TC-INT-07 — Non-owner edit attempt -> article API rejects; feed/profile unchanged

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-4 / REQ-F-22 |
| **Type** | Integration (negative) |
| **Priority** | P1 |
| **Preconditions** | SUT running; logged in as the second user; a foreign article exists |
| **Test data** | Second-user session; foreign slug: `<author-owned-slug>` |

**Steps**
1. Log in as the second user; open http://localhost:3000/editor/`<foreign-slug>`.
2. If editable, attempt to submit a change; capture the request in DevTools -> Network.
3. Re-check the article as its owner in the feed/profile.

**Expected result**
- Any update request from a non-owner returns 401/403/422 (or no editable form is served), and the
  article content in the feed and owner's profile is unchanged.

**Pass/Fail criteria**: PASS if no non-owner change persists. Any accepted non-owner update is a FAIL.
**Cleanup**: Restore the article if it changed.
