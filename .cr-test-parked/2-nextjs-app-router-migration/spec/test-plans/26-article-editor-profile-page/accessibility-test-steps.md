# Accessibility Test Steps — #26 Article Editor & Profile Page

**Purpose**: Verify the editor form and profile UI delivered by this story are accessible — keyboard
operability, programmatic labels, correct semantics for the profile tabs, visible focus, colour
contrast, error announcement, and usability at 200% zoom. Black-box, manual, executed against a
locally built instance of the merged story. Each case references the relevant WCAG 2.1 success criterion.

**Scope**: `/editor`, `/editor/[slug]` (article form) and `/profile/[username]` (profile header,
follow control, My Articles / Favorited tabs). Observable behaviour only — no source code read. Tools:
keyboard only, a screen reader (VoiceOver on macOS or NVDA on Windows), and a contrast checker /
browser DevTools.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/nextjs-migration` |
| This story's merged PR | PR #34 — https://github.com/revanta-biswas/conduit-helix-test/pull/34 |
| Confirm the story is in the build | `git log --oneline \| grep -i "1.8"` (or search for the PR #34 merge commit) |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING). This plan does not restate them. |
| Local base URL / port | http://localhost:3000 |
| Local services that must be up | PostgreSQL (via Sequelize) reachable by the app; app server running on :3000 |
| Test data / accounts to seed | An author account with ≥1 authored + ≥1 favorited article; a second user to view/follow |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-A11Y-01 — Editor form is fully keyboard operable

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-22 |
| **Type** | Accessibility |
| **Priority** | P1 |
| **WCAG** | 2.1.1 Keyboard (A); 2.4.3 Focus Order (A) |
| **Preconditions** | SUT running; logged in as the author; on http://localhost:3000/editor; mouse not used |
| **Test data** | Title: `A11y Keyboard Article`; Description: `x`; Body: `y`; Tag: `a11y` |

**Steps**
1. Using only Tab / Shift+Tab / Enter / Space / arrow keys, move focus through the form.
2. Enter values into Title, Description, Body, and add a tag, all via keyboard.
3. Submit the form using the keyboard (Enter on the submit button).

**Expected result**
- Every field, the tag entry, and the submit button are reachable and operable by keyboard.
- Focus order follows a logical, left-to-right/top-to-bottom sequence matching the visual layout.
- The article is created via keyboard alone (no keyboard trap encountered).

**Pass/Fail criteria**: PASS if the whole create flow completes by keyboard with a logical focus
order and no trap. Any unreachable control or trap is a FAIL.
**Cleanup**: Delete the created article.

---

### TC-A11Y-02 — Editor form fields have programmatically associated labels

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-22 |
| **Type** | Accessibility |
| **Priority** | P1 |
| **WCAG** | 1.3.1 Info and Relationships (A); 4.1.2 Name, Role, Value (A); 3.3.2 Labels or Instructions (A) |
| **Preconditions** | SUT running; logged in; on `/editor`; screen reader active |
| **Test data** | None |

**Steps**
1. With the screen reader running, focus each form control in turn.
2. Note the name/role announced for Title, Description, Body, Tags, and the submit button.

**Expected result**
- Each control is announced with a meaningful accessible name and correct role (e.g. "Article Title,
  edit text"). No control announces as unlabeled/blank. TO CONFIRM: exact field labels/placeholders
  used, with the dev/BA (placeholder-only labels do NOT satisfy 3.3.2).

**Pass/Fail criteria**: PASS if every control has a programmatic, meaningful name and correct role.
Any unlabeled control, or placeholder used as the only label, is a FAIL.
**Cleanup**: None.

---

### TC-A11Y-03 — Profile tabs use correct tab semantics and keyboard interaction

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-23 |
| **Type** | Accessibility |
| **Priority** | P1 |
| **WCAG** | 4.1.2 Name, Role, Value (A); 2.1.1 Keyboard (A); 1.3.1 Info and Relationships (A) |
| **Preconditions** | SUT running; on http://localhost:3000/profile/e2e_author; screen reader active |
| **Test data** | Author username: `e2e_author` |

**Steps**
1. Locate the "My Articles" / "Favorited Articles" tab control with the screen reader.
2. Note how each tab is announced (role, selected state).
3. Move focus to the tabs by keyboard and switch between them (Tab/Enter, and arrow keys if it is an ARIA tablist).
4. Confirm the article list below updates to match the selected tab.

**Expected result**
- The tabs expose a recognizable tab semantics — either native controls (links/buttons) with clear
  names and an indicated current selection, or an ARIA `tablist`/`tab`/`tabpanel` pattern with
  `aria-selected` and arrow-key navigation. TO CONFIRM: whether the tabs are ARIA tabs or nav links,
  with the dev/BA.
- The selected tab is programmatically indicated (announced as selected/current), operable by
  keyboard, and switching updates the associated content region.

**Pass/Fail criteria**: PASS if tabs are keyboard-operable, announce role and selected state, and
control the list. Tabs that are mouse-only or announce no selected state are a FAIL.
**Cleanup**: None.

---

### TC-A11Y-04 — Follow/unfollow control has an accessible name and state

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-23 |
| **Type** | Accessibility |
| **Priority** | P2 |
| **WCAG** | 4.1.2 Name, Role, Value (A); 2.1.1 Keyboard (A) |
| **Preconditions** | SUT running; logged in as the author; viewing http://localhost:3000/profile/e2e_second; screen reader active |
| **Test data** | Target username: `e2e_second` |

**Steps**
1. Focus the Follow control by keyboard; note the announced name/role.
2. Activate it by keyboard; note whether the changed state (Following/Unfollow) is announced/reflected.
3. Activate again to unfollow.

**Expected result**
- The control is a button/link with a meaningful accessible name (e.g. "Follow e2e_second"), operable
  by keyboard, and its state change is reflected in the accessible name/state after activation.

**Pass/Fail criteria**: PASS if the control is keyboard-operable with a clear name and its state
change is perceivable non-visually. An icon-only control with no name is a FAIL.
**Cleanup**: Leave the relationship unfollowed.

---

### TC-A11Y-05 — Focus is visible throughout the editor and profile

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-2 / REQ-F-22, REQ-F-23 |
| **Type** | Accessibility |
| **Priority** | P2 |
| **WCAG** | 2.4.7 Focus Visible (AA) |
| **Preconditions** | SUT running; logged in; keyboard only |
| **Test data** | None |

**Steps**
1. Tab through every interactive element on `/editor` and on a profile page.
2. Observe whether a visible focus indicator is present on each focused element.

**Expected result**
- Every interactive element shows a clearly visible focus indicator when focused; no element receives
  focus invisibly.

**Pass/Fail criteria**: PASS if focus is visible on all interactive elements. Any element that can
hold focus without a visible indicator is a FAIL.
**Cleanup**: None.

---

### TC-A11Y-06 — Text and control contrast meet AA

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-2 / REQ-F-22, REQ-F-23 |
| **Type** | Accessibility |
| **Priority** | P2 |
| **WCAG** | 1.4.3 Contrast (Minimum) (AA); 1.4.11 Non-text Contrast (AA) |
| **Preconditions** | SUT running; a contrast checker or browser DevTools available |
| **Test data** | None |

**Steps**
1. On `/editor`, measure contrast of field labels, entered text, placeholder text, and the submit button text.
2. On a profile page, measure contrast of the tab labels (selected and unselected), the follow button, and article list text.
3. Measure the contrast of focus indicators and control borders against their background.

**Expected result**
- Normal text meets ≥ 4.5:1 and large text ≥ 3:1 (1.4.3); UI component boundaries and focus
  indicators meet ≥ 3:1 (1.4.11).

**Pass/Fail criteria**: PASS if all measured foreground/background pairs meet their AA threshold. Any
pair below threshold is a FAIL (record the measured ratio).
**Cleanup**: None.

---

### TC-A11Y-07 — Editor validation errors are perceivable and announced

| Field | Value |
|-------|-------|
| **Traces to** | AC-1 / REQ-F-22 |
| **Type** | Accessibility (negative) |
| **Priority** | P2 |
| **WCAG** | 3.3.1 Error Identification (A); 3.3.3 Error Suggestion (AA); 4.1.3 Status Messages (AA) |
| **Preconditions** | SUT running; logged in; on `/editor`; screen reader active |
| **Test data** | Title: (empty); Body: (empty) — to trigger validation |

**Steps**
1. Submit the editor form with an empty title (per TC-E2E-03).
2. Observe how the error is presented visually and whether the screen reader announces it.

**Expected result**
- A validation error is shown in text (not colour alone), identifies the field in error, and is
  announced by the screen reader (e.g. via a live region / focus move to the error). TO CONFIRM:
  error-presentation mechanism (inline vs. summary, aria-live) with the dev/BA.

**Pass/Fail criteria**: PASS if the error is text-identified, tied to the field, and announced to a
screen reader. An error conveyed by colour only, or silent to a screen reader, is a FAIL.
**Cleanup**: None.

---

### TC-A11Y-08 — Editor and profile remain usable at 200% zoom

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-2 / REQ-F-22, REQ-F-23 |
| **Type** | Accessibility (boundary) |
| **Priority** | P2 |
| **WCAG** | 1.4.4 Resize Text (AA); 1.4.10 Reflow (AA) |
| **Preconditions** | SUT running; desktop browser |
| **Test data** | None |

**Steps**
1. Set browser zoom to 200% on `/editor`.
2. Verify all form fields, labels, and the submit button are present, readable, and operable without
   horizontal scrolling of the page as a whole (content reflows).
3. Repeat on a profile page (header, tabs, article list).

**Expected result**
- At 200% zoom all content and controls remain visible and operable; text is not clipped and content
  reflows to a single column without requiring two-dimensional scrolling (per 1.4.10).

**Pass/Fail criteria**: PASS if both pages remain fully usable and readable at 200% zoom. Clipped
text, lost controls, or forced horizontal scrolling is a FAIL.
**Cleanup**: Reset zoom to 100%.
