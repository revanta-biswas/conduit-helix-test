# Accessibility Test Steps — #24 Auth Pages & Session (Login, Register, Settings)

**Purpose**: Verify the `/login`, `/register`, and `/settings` forms are accessible — keyboard
operable, correctly labelled, with a logical focus order, visible focus, announced errors, adequate
colour contrast, and usable at 200% zoom. Black-box, manual, against WCAG 2.1 AA.

**Scope**: The three auth-related UI forms delivered/changed by this story. Verified with keyboard,
a screen reader, browser zoom, and a contrast checker — never from source.

**Tooling**: Keyboard only; a screen reader (VoiceOver on macOS, NVDA on Windows); browser zoom;
a colour-contrast checker (e.g. the browser DevTools contrast readout or an axe-style extension).

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/nextjs-migration` |
| This story's merged PR | PR #33 — https://github.com/revanta-biswas/conduit-helix-test/pull/33 |
| Confirm the story is in the build | `git log --oneline \| grep -i "1.6"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING). This plan does not restate them. |
| Local base URL / port | http://localhost:3000 |
| Local services that must be up | PostgreSQL (via Sequelize); app server on :3000 |
| Test data / accounts to seed | A valid account for `/settings`; login/register use fresh or invalid inputs per case |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-A11Y-01 — Login form is fully keyboard operable with logical focus order

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-24 |
| **Type** | Accessibility |
| **Priority** | P1 |
| **WCAG** | 2.1.1 Keyboard (A); 2.4.3 Focus Order (A) |
| **Preconditions** | SUT running; `/login` open; mouse not used for the whole case |
| **Test data** | A valid account |

**Steps**
1. Navigate to http://localhost:3000/login. Place focus at the top (click the address bar, then Tab
   into the page — or reload and Tab from the start).
2. Using only Tab / Shift+Tab, move through every interactive element (email, password, submit, any
   links such as "Need an account?").
3. Note the order in which focus lands relative to the visual layout.
4. With focus on the submit button (or in the last field), activate it with Enter / Space and log in.

**Expected result**
- Every field and control is reachable and operable by keyboard alone; no control is skipped or traps focus.
- Focus order follows the visual/reading order (email -> password -> submit -> links).
- The form submits via the keyboard and login succeeds.

**Pass/Fail criteria**: PASS if all controls are keyboard-reachable in a logical order and the form
submits by keyboard. Any unreachable control, a focus trap, or an illogical order is a FAIL.
**Cleanup**: Log out.

---

### TC-A11Y-02 — All inputs have programmatic labels (login, register, settings)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-2 / REQ-F-24, REQ-F-25 |
| **Type** | Accessibility |
| **Priority** | P1 |
| **WCAG** | 1.3.1 Info and Relationships (A); 4.1.2 Name, Role, Value (A); 3.3.2 Labels or Instructions (A) |
| **Preconditions** | SUT running; screen reader enabled; a valid account for `/settings` |
| **Test data** | A valid account |

**Steps**
1. With the screen reader on, navigate to `/login` and Tab into each field.
2. Confirm the screen reader announces a meaningful name and role for each input (e.g.
   "Email, edit text"; "Password, edit text, secure").
3. Repeat on `/register` (username, email, password).
4. Log in and repeat on `/settings` (bio, image URL, email, and any others).

**Expected result**
- Every input has an associated, announced label (via `<label>`, `aria-label`, or `aria-labelledby`);
  no field is announced as just "edit text" with no name. Placeholder-only labelling is not sufficient.

**Pass/Fail criteria**: PASS if every input on all three pages exposes a programmatic name to the
screen reader. Any unlabeled/placeholder-only field is a FAIL.
**Cleanup**: Log out; disable screen reader.

---

### TC-A11Y-03 — Focus is visible on every interactive control

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-2 / REQ-F-24, REQ-F-25 |
| **Type** | Accessibility |
| **Priority** | P2 |
| **WCAG** | 2.4.7 Focus Visible (AA) |
| **Preconditions** | SUT running; keyboard only |
| **Test data** | None |

**Steps**
1. On `/login`, Tab through each control and observe whether the focused control shows a visible
   focus indicator (outline/ring/change).
2. Repeat on `/register` and (logged in) on `/settings`, including the submit and logout controls.

**Expected result**
- Every interactive control shows a clearly visible focus indicator when focused; the focus is never
  suppressed (no `outline: none` without a replacement).

**Pass/Fail criteria**: PASS if focus is visibly indicated on all controls across the three pages.
Any control with no visible focus is a FAIL.
**Cleanup**: None.

---

### TC-A11Y-04 — Validation errors are announced and associated with their field

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-2 / REQ-F-24, REQ-F-25 |
| **Type** | Accessibility (negative-path) |
| **Priority** | P1 |
| **WCAG** | 3.3.1 Error Identification (A); 4.1.3 Status Messages (AA) |
| **Preconditions** | SUT running; screen reader enabled |
| **Test data** | Login: correct email + wrong password. Register: an already-taken username/email. |

**Steps**
1. With the screen reader on, go to `/login`, enter a correct email + wrong password, and submit.
2. Observe whether the error message is announced by the screen reader without requiring the user to
   hunt for it, and whether it is associated with the relevant field / summarised at the top.
3. Repeat on `/register` submitting an already-taken username/email.
4. On `/settings` (logged in), submit an invalid image URL (`not-a-valid-url`) if validation applies,
   and observe error announcement. TO CONFIRM: whether image-URL validation errors are surfaced.

**Expected result**
- Each error is presented as text (not colour alone), is announced by the screen reader (e.g. via a
  live region / `role="alert"` or focus moved to the error), and identifies which field/what to fix.

**Pass/Fail criteria**: PASS if errors are perceivable and announced to assistive tech and identify
the problem. An error conveyed by colour only, or never announced, is a FAIL.
**Cleanup**: None.

---

### TC-A11Y-05 — Text and controls meet contrast requirements

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-2 / REQ-F-24, REQ-F-25 |
| **Type** | Accessibility |
| **Priority** | P2 |
| **WCAG** | 1.4.3 Contrast (Minimum) (AA); 1.4.11 Non-text Contrast (AA) |
| **Preconditions** | SUT running; a contrast checker available |
| **Test data** | None |

**Steps**
1. On `/login`, `/register`, and `/settings`, use the contrast checker to measure:
   field label text, body/help text, placeholder text, button text vs. button background, and error
   message text.
2. Also check the contrast of input borders and the focus indicator against their surroundings.

**Expected result**
- Normal body text >= 4.5:1; large text >= 3:1; UI component boundaries and focus indicators >= 3:1.

**Pass/Fail criteria**: PASS if all measured text and non-text elements meet their thresholds. Any
element below threshold is a FAIL (record the measured ratio).
**Cleanup**: None.

---

### TC-A11Y-06 — Pages remain usable at 200% zoom / reflow

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-2 / REQ-F-24, REQ-F-25 |
| **Type** | Accessibility |
| **Priority** | P2 |
| **WCAG** | 1.4.4 Resize Text (AA); 1.4.10 Reflow (AA) |
| **Preconditions** | SUT running |
| **Test data** | A valid account for `/settings` |

**Steps**
1. On `/login`, set the browser zoom to 200% (Ctrl/Cmd +).
2. Confirm all labels, fields, buttons, and error areas remain visible and usable with no loss of
   content or functionality and no horizontal scrolling for the form content (at a 1280px-wide viewport).
3. Repeat on `/register` and (logged in) `/settings`, including submitting a form at 200% zoom.

**Expected result**
- At 200% zoom, content reflows without clipping/overlap; every control is reachable and operable;
  forms can still be completed and submitted.

**Pass/Fail criteria**: PASS if all three pages stay fully usable at 200% zoom without content loss.
Clipped/overlapping/unreachable controls or lost content is a FAIL.
**Cleanup**: Reset zoom to 100%; log out.
