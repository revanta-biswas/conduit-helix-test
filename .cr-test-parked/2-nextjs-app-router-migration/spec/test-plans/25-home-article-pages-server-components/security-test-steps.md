# Security Test Steps — #25 Home & Article Pages (Server Components)

**Purpose**: Light, story-scoped security verification. The security surface of this story is
**session-state isolation**: an anonymous visitor (or any visitor) must never see another user's
favorited/following state, and the pages must not expose sensitive session data. Black-box; derived
from AC-4 and the Security Baseline (data isolation / no sensitive-data leakage).

**Scope**: Session-scoped rendering of favorited/following on `/` and `/article/[slug]`. Auth-token
handling and the underlying APIs are covered in Stories 1.4/1.5 — out of scope here except as they
surface on these pages.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/nextjs-migration` |
| This story's merged PR | [PR #35](https://github.com/revanta-biswas/conduit-helix-test/pull/35) |
| Confirm the story is in the build | `git log --oneline \| grep -i "1.7\|#25\|home.*article"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | `http://localhost:3000` |
| Local services that must be up | PostgreSQL (via Sequelize) |
| Test data / accounts to seed | Bob (follows Alice, favorited one Alice article `<known-slug>`); a third user "Carol" who does NOT follow Alice and has favorited nothing |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-SEC-01 — No cross-user leakage: Carol does not see Bob's favorited/following state (negative)

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-F-29 |
| **Type** | Security |
| **Priority** | P1 |
| **Security Baseline** | Access control / data isolation (a user sees only their own session-scoped state) |
| **Preconditions** | SUT running; `<known-slug>` is favorited by Bob; Carol has no relationship to it |
| **Test data** | Carol's credentials; `<known-slug>` |

**Steps**
1. Log in as Carol.
2. Navigate to `http://localhost:3000/article/<known-slug>` (the article Bob favorited and whose author Bob follows).
3. Observe Carol's favorite control and follow-author control.

**Expected result**
- Carol sees **favorited = false** and **following = false** for this article/author — Bob's state does not leak into Carol's session.
- The state reflects Carol's own (empty) relationships only.

**Pass/Fail criteria**: PASS only if both controls are false for Carol. FAIL if either shows Bob's true state (a cross-user data-isolation defect).
**Cleanup**: Log out. Do not modify any favorite/follow relationship.

---

### TC-SEC-02 — Anonymous visitor is treated as an unauthenticated session (favorited/following false)

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-F-29 |
| **Type** | Security |
| **Priority** | P1 |
| **Security Baseline** | Access control / no privileged state for anonymous |
| **Preconditions** | SUT running; no session cookie present; `<known-slug>` favorited by Bob |
| **Test data** | `<known-slug>` |

**Steps**
1. In a fresh/incognito window with no session, navigate to `http://localhost:3000/article/<known-slug>`.
2. Observe both controls.
3. Also open `http://localhost:3000/` and observe the personal/global feed toggle behaviour for an anonymous user.

**Expected result**
- Anonymous visitor sees favorited = false and following = false everywhere.
- Attempting the personal ("Your Feed") view as anonymous does not silently show another user's feed; it either hides the personal option or shows an empty/global result. TO CONFIRM: expected anonymous behaviour for the personal-feed URL — confirm with dev/BA.

**Pass/Fail criteria**: PASS if anonymous state is uniformly false and no personal feed of any user is exposed. FAIL if anonymous shows any true state or another user's personal feed.
**Cleanup**: None.

---

### TC-SEC-03 — Page markup/response does not leak another user's session or sensitive tokens (negative)

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-F-29 |
| **Type** | Security |
| **Priority** | P2 |
| **Security Baseline** | No sensitive-data leakage in responses |
| **Preconditions** | SUT running; logged in as Bob |
| **Test data** | `<known-slug>` |

**Steps**
1. Log in as Bob and open `http://localhost:3000/article/<known-slug>`.
2. View the page source / document response (browser "View Source" and dev-tools Network → document response body).
3. Search the served HTML for: raw JWTs / session tokens, password hashes, other users' email addresses, and any user's data other than what is shown on screen.

**Expected result**
- The rendered HTML contains only the data needed to display the page (public article + comment content + Bob's own favorited/following flags).
- No raw auth token, password hash, or another user's private data is embedded in the served HTML/serialized props.

**Pass/Fail criteria**: PASS if no sensitive data or other-user data is present in the response. FAIL if a token, hash, or unrelated user's data is found in the served markup.
**Cleanup**: Log out.

---

### TC-SEC-04 — Tag/offset search params are handled safely (injection-style input) (boundary/negative)

| Field | Value |
|-------|-------|
| **Traces to** | AC-3, AC-5 / REQ-F-20 |
| **Type** | Security |
| **Priority** | P2 |
| **Security Baseline** | Input validation / injection resistance |
| **Preconditions** | SUT running |
| **Test data** | `?tag=<script>alert(1)</script>`, `?offset=-1`, `?offset=abc`, `?offset=999999999` |

**Steps**
1. Navigate to `http://localhost:3000/?tag=%3Cscript%3Ealert(1)%3C/script%3E` and observe the page.
2. Navigate to `http://localhost:3000/?offset=-1`, then `?offset=abc`, then `?offset=999999999`.
3. Watch for any script execution (alert popup), server error, or exposed stack trace.

**Expected result**
- The malicious `tag` value is treated as data — no script executes; the page either shows an empty/no-match feed or the value reflected safely encoded, never as live HTML/JS.
- Invalid/negative/non-numeric/huge `offset` values do not crash the page — the page falls back gracefully (e.g. treats as offset 0 or an empty last page) with no 500 or stack trace.

**Pass/Fail criteria**: PASS if no script executes and no unhandled server error/stack trace appears for any of the inputs. FAIL on any XSS execution, 500 page, or leaked stack trace.
**Cleanup**: None.
