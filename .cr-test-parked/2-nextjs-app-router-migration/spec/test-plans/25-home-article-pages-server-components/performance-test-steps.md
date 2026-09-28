# Performance Test Steps — #25 Home & Article Pages (Server Components)

**Purpose**: Verify the Server-Component rendering delivers the "fast initial loads" intent behind
REQ-F-29 — measure server-side initial render (TTFB) and full initial paint for the home and article
pages, and verify the pages render **without hydration errors** (a Server-Component correctness
property that directly affects perceived performance and correctness). Black-box; measured from the
browser/HTTP client only.

**Scope**: Initial load of `/` and `/article/[slug]` as Server Components.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/nextjs-migration` |
| This story's merged PR | [PR #35](https://github.com/revanta-biswas/conduit-helix-test/pull/35) |
| Confirm the story is in the build | `git log --oneline \| grep -i "1.7\|#25\|home.*article"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. Run the app in the mode the project documents for representative performance (a production build if the docs provide one — dev-mode numbers are indicative only). TO CONFIRM: which run mode ve should measure. |
| Local base URL / port | `http://localhost:3000` |
| Local services that must be up | PostgreSQL (via Sequelize) |
| Test data / accounts to seed | Home feed with a representative page of articles (~10) and popular tags; one article `<known-slug>` with body + ≥ 2 comments |

> **No performance target is defined in the acceptance criteria or the inputs provided.** REQ-F-29
> states the intent ("fast initial loads") but not a number. Every threshold below is marked
> **TO CONFIRM** and must be agreed with the BA/architect before a PASS/FAIL is asserted. Until then
> these cases **record and report** measurements rather than gate on them.

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-PERF-01 — Home page server initial render (TTFB) and initial paint

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-29 |
| **Type** | Performance |
| **Priority** | P2 |
| **Preconditions** | SUT running in the documented representative mode; seed data present; no other heavy load on the machine |
| **Test data** | None |

**Steps**
1. Open browser dev-tools → Network tab; enable "Disable cache".
2. Navigate to `http://localhost:3000/`.
3. Record for the top-level document request: **TTFB** (time to first byte) and the document response time.
4. Record **First Contentful Paint (FCP)** and **DOMContentLoaded** from the Performance/Lighthouse panel.
5. Repeat 5 times (hard reload each time) and record all runs in the table below.

**Record the numbers**

| Run | TTFB (ms) | FCP (ms) | DOMContentLoaded (ms) |
|-----|-----------|----------|-----------------------|
| 1 | | | |
| 2 | | | |
| 3 | | | |
| 4 | | | |
| 5 | | | |
| Median | | | |

**Expected result**
- The document is served from the server already containing the feed HTML (Server Component SSR), i.e. content is present at first byte, not fetched client-side after load.
- Median TTFB ≤ **TO CONFIRM: [target ms]**; median FCP ≤ **TO CONFIRM: [target ms]**.

**Pass/Fail criteria**: Until targets are confirmed, PASS = measurements recorded AND content is present in the server-rendered document (verifiable via "View Source" showing feed articles in the HTML). Once targets are set, median must meet them.
**Cleanup**: None.

---

### TC-PERF-02 — Article page server initial render (TTFB) and initial paint

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-29 |
| **Type** | Performance |
| **Priority** | P2 |
| **Preconditions** | SUT running; `<known-slug>` present with body + comments |
| **Test data** | `<known-slug>` |

**Steps**
1. Dev-tools Network → "Disable cache".
2. Navigate to `http://localhost:3000/article/<known-slug>`.
3. Record TTFB, document response time, FCP, DOMContentLoaded.
4. Confirm via "View Source" that the article body and comments are present in the server-rendered HTML (not injected client-side).
5. Repeat 5 times; record in a table identical to TC-PERF-01.

**Expected result**
- Article body + comments are present in the initial server-rendered HTML.
- Median TTFB/FCP meet **TO CONFIRM: [targets]**.

**Pass/Fail criteria**: Same convention as TC-PERF-01 — record + SSR-content-present until targets confirmed, then gate on medians.
**Cleanup**: None.

---

### TC-PERF-03 — Both pages render with ZERO hydration errors in the browser console (boundary / correctness-affecting)

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-F-29 |
| **Type** | Performance |
| **Priority** | P1 |
| **Preconditions** | SUT running; seed data present; test once anonymous and once logged in as Bob |
| **Test data** | `<known-slug>`; Bob's session |

**Steps**
1. Open browser dev-tools → Console; clear it; keep it open.
2. Navigate to `http://localhost:3000/` (anonymous). Watch the console during and just after load.
3. Navigate to `http://localhost:3000/article/<known-slug>` (anonymous). Watch the console.
4. Log in as Bob and repeat steps 2–3 while logged in.
5. Record any console message mentioning "hydration", "did not match", "Text content does not match", "Hydration failed", or React warning/error.

**Expected result**
- **Zero hydration errors or mismatch warnings** in the console on either page, in both the anonymous and logged-in sessions. The server-rendered markup matches what the client expects, including the session-dependent favorited/following state (which is false for anonymous and correct for Bob).

**Pass/Fail criteria**: PASS only if the console shows no hydration errors/mismatch warnings on either page in either session. FAIL if any hydration mismatch appears (this is a direct AC-4 defect: the pages must render without hydration errors).
**Cleanup**: None.

---

### TC-PERF-04 — Feed/tag switch via URL is a fresh server navigation, not a heavy full client re-fetch loop (boundary)

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-F-29 |
| **Type** | Performance |
| **Priority** | P3 |
| **Preconditions** | SUT running; seed data with ≥ 2 tags |
| **Test data** | `<known-tag>` |

**Steps**
1. Dev-tools Network tab open; navigate to `http://localhost:3000/`.
2. Switch to a tag feed (click a popular tag) and observe the network requests triggered.
3. Confirm the switch is driven by a navigation to the tag URL (server-rendered result) rather than an ad-hoc chain of many client fetches.
4. Record the time from click to the updated feed being visible.

**Expected result**
- Switching feed/tag results in a server-driven navigation to the new URL with the new feed content; the transition completes in a reasonable time (**TO CONFIRM: [target ms]**) without a visibly janky multi-request client refetch.

**Pass/Fail criteria**: Record the transition time and confirm URL-driven navigation. Gate on a confirmed target once provided.
**Cleanup**: None.
