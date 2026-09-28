# WORKFLOW: `epic-change-request <TICKET-ID | description | --from-requirements | --from-spec <path>>` (Mid-Epic Change Request — into the Epic Branch)

> **READ FIRST.** The six non-negotiables at the top of `workflows/dev-implement.md` bind this workflow
> too: every gate runs (no scope calls), the Gate Ledger is complete before the commit, the work-unit
> guard (`sh aire-workflow/templates/hooks/check-work-unit.sh --install <unit-key>` right after the story
> branch is cut) is installed and never bypassed, the claim (In Development + assignee) is made on the
> external tracker and recorded in the fragment's `## Claim` block, a disclosed gap is never shipped, and
> the run ends with this workflow's own handoff block verbatim — nothing else in that final message.

## WHAT THIS WORKFLOW IS

**A requirement changed while the epic cycle is open.** Not "make it do something new" and not "it is
broken" — the *agreement itself* was revised: a threshold moved, a rule was rewritten, a regulation
landed, a decision was reversed. This workflow makes that change visible in the cycle it arrives in,
versions the requirement, routes every story that promised the old text, and delivers the work as ONE
new story on the epic branch.

It is the **third mid-epic workflow**, a peer of the other two — not a variant of either:

| | trigger | its question |
|---|---|---|
| `epic-enhance` | **behaviour** | "make it do X" |
| `epic-bugfix` | **defect** | "it does X but shouldn't" |
| **`epic-change-request` (this)** | **requirement** | "we agreed X; now we agree Y" |

🔴 **This workflow is fully self-contained.** It stands on `workflows/dev-implement.md` and the shared
`common/*.md` contracts only. It never reads, cites or delegates to `epic-enhance.md` or
`epic-bugfix.md`, and deleting either of those files leaves this workflow fully executable.

| | `ticket-implement` → enhancement/bug cycle | **`epic-change-request` (this workflow)** |
|---|---|---|
| Branch | `enhancement/…` or `bug/…` from **base** | `story/…` from the **epic branch** |
| PR | `[ENH]` / `[BUG]` → base | **`[STORY]` → epic branch** |
| Cycle | Its own: requirements, design stages, STOP checkpoint, archive | **None** — the epic's state, specs, rubrics and CI are reused |
| Requirements | Its own scoped `requirements.md` | **The epic's `requirements.md`, amended and versioned in place** (`common/requirement-versioning.md`) |
| Documents | brief, requirements, impact analysis, design docs, plan | **ONE bundle** — `spec/plans/change-requests/CR-<n>/` |
| Earlier stories' tests | Not its concern | **Found, changed under authorization, and re-proven** |
| Questions | Several approvals | **ONE — the single gate (Phase 9)** |

---

## WHAT MAKES THIS DIFFERENT FROM EVERY OTHER WORKFLOW

1. **It starts from the requirement, not the code.** The primary walk is REQ-ID → `Covers` → story →
   AC → test (Phase 3). Starting from code would miss a changed requirement that **no story has built
   yet** — precisely the case a Change Request exists to catch.
2. **It versions requirements.** `REQ-F-03` becomes `REQ-F-03@v2`, prior text retained
   (`common/requirement-versioning.md`). Nothing else in the framework mints a version.
3. **It can be triggered by a document edit.** Entry Mode C diffs the operator's own uncommitted
   `requirements.md` edit against the epic branch — drift detection no other workflow performs.
4. **One gate, everything staged.** Nothing reaches disk until the operator answers Phase 9 (CR16).
5. **It is the most verbose workflow in the framework, deliberately** (CR13-V / V1–V9).

🔴 **The verbosity contract binds every phase below.** V1 announce each phase · V2 cite evidence on every
finding · V3 counts before lists before detail · V4 every decision with the alternative it rejected ·
V5 never summarise at the gate · V6 measured value against threshold per gate · **V7 fact-only — no
severity adjective, no advisory verb, in any output or artifact (CR14)** · **V8 ASCII-only diagrams,
equal-width box lines (`common/ascii-diagram-standards.md`); `├── └──` tree glyphs are the one carve-out**
· V9 audit parity. Full text: `common/change-request-rules.md` Section 3. The sample output blocks in
each phase show the required shape, not fixed wording.

---

## 🔴 THE ONLY QUESTION IS THE SINGLE GATE (Phase 9)

**The run asks exactly one thing: approve the staged Change Request.** It never asks a clarifying
question, never offers a menu of options, and never asks for a decision mid-run.

- **Input usually comes with the keyword** — `epic-change-request "<change>"`, a ticket ID,
  `--from-requirements` or `--from-spec <path>`. When it does, the entry mode is already known and the
  run goes **straight to analysis**: the gate stays the only question.
- **A bare `epic-change-request` gets a front door instead of a usage line** (Phase 0.5): a short
  welcome and a 4-way picker for *how you want to describe the change*. That is a **routing question**,
  not a clarifying one — it asks which input the user has, never what the change means. It is the only
  question that can precede the gate, it is asked **once**, and passing input with the keyword skips it
  entirely. 🔴 Everything after it stays unchanged: no clarifying questions, no mid-run decisions.
- **Where a decision is needed, the framework decides, and the bundle says so.** Every such decision is
  written into `change-request.md` Section 9 with its reason **and the alternative it rejected** (V4).
  The operator overrules any of them with **Request Changes** — that is the only channel, and it is enough.
- **Approval authorises everything the bundle lists**: the requirement amendments and version bumps, the
  new/CR-born/amended stories, the Test Change Authorization list, the tracker actions and links, the
  dependency edges, an `architecture.md` amendment, and the push.
- After approval the run is **fully automatic** through to the PR and the handoff.
- The sanctioned **halts** stay (they are not questions): a Phase 4 block, a CR12 dependency cycle, a
  Phase 8 pre-emission failure, SH-4 retry-limit exhaustion, and the Playwright agent-install restart pause.

---

## 🔴 SINGLE-SESSION EXECUTION — NO FORKS

`workflows/dev-implement.md` Step 1.7 applies to this whole workflow, unchanged: every step runs in the
session where the keyword was typed; nothing is delegated to a fork, subagent, Workflow-tool run,
background or remote agent, second session or `claude -p` subprocess. `agents/change-request-analyst.md`
executes **inline**. The only Agent-tool use is Playwright's own Planner/Generator/Healer inside the
Playwright UI gate, one call at a time, synchronously. A run inside a fork or subagent HALTS at Phase 0.

---

## MANDATORY: Rule Details Loading

Resolve `aire-workflow/` and load:
- **`common/change-request-rules.md`** — CR1–CR17 + CR13-V. 🔴 THE source of truth for this workflow's
  semantics; rule IDs below refer to it and are never restated inline.
- **`common/requirement-versioning.md`** — the `@vN` model and RV-1…RV-7.
- `common/process-overview.md`, `common/session-continuity.md`, `common/content-validation.md`,
  `common/audit-logging.md`, `common/tracker-sync.md`, `common/branching-strategy.md`,
  `common/requirements-traceability.md` (Rules 1–6 and **Rule 8**), `common/behavior-spec.md`,
  `common/eval-framework.md`, `common/directory-structure.md`, `common/parallel-work-state.md`,
  `common/work-unit-artifacts.md`, `common/self-heal-limit-guidance.md`,
  `common/ascii-diagram-standards.md`
- **`agents/change-request-analyst.md`** — the read-only analyst, executed inline at Phases 2–4.
- `workflows/dev-implement.md` **in full** — its Step 1.5 (branch + baselines), Steps 4.3/4.5, Part 2,
  Steps 6 → 6.8 and Sections A–F are executed **by reference** at Phase 10; its Self-Healing Retry
  Policy and Retry-Limit Report bind this workflow.
- `implementation/code-generation.md` (Guardrail — Generation Phase Rules),
  `workflows/code-review.md` + `implementation/code-review.md`, `workflows/remediate.md` +
  `implementation/remediate.md`
- When `## CI/CD Configuration` records `Enabled: Yes`: `common/ci-pipeline-generation.md` Sections
  4.0d, 4.0f, 4.0i and 6.6
- 🔴 The Playwright non-negotiables in `workflows/dev-implement.md` apply unchanged — earlier stories'
  Playwright specs change only through the `playwright-implement` skill's own subagents, never by hand.

---

## SELF-HEALING RETRY POLICY — INHERITED, PLUS ONE LOOP

SH-1 … SH-7 from `workflows/dev-implement.md` govern every loop here (3 attempts each, independent
counters, logged root cause per attempt, exhaustion HALTS with the Retry-Limit Report, stalls end the
budget early, no weakening).

At SH-4 the run emits the **Self-Heal Limit message** (`common/self-heal-limit-guidance.md` Section 2)
with **resume keyword = `epic-change-request`**, and records `HALTED —` in the story fragment's
`## Progress`. Typing `epic-change-request` again is a hand-back: the run finds the halted CR story and
follows the resume protocol (Section 4 of that file) instead of starting a new Change Request — **the
single gate is not asked again**.

The loops keep their `dev-implement` IDs, plus:

| ID | Loop | Defined in | Verification that must pass to exit |
|---|---|---|---|
| **SH-LOOP-15** | Test Impact Reconciliation | `common/self-heal-limit-guidance.md:123` (mechanics) · `common/eval-framework.md` Section 5 (`gates.testImpact`, local-only) | The test/spec diff matches the Test Change Authorization list exactly, every new or amended AC has ≥1 scenario and ≥1 test case, and every amended requirement has a story tracing to its new version |

---

## MANDATORY: Audit Entry Format

`workflows/dev-implement.md`'s format (`User Email`, `User Input`, `TRACKER ITEM`, `Epic Link`,
`AIRE VERSION`, `AI Response`, `Context`) **plus** one field on every entry:

```markdown
**CHANGE REQUEST**: "CR-<n> — <entry mode> — spec/plans/change-requests/CR-<n>/"
```

Append only; timestamps from one real clock command. 🔴 **V9 — audit parity**: what the operator saw is
what the audit records, never a shorter paraphrase.

---

## 🔴 PARALLEL-SAFE STATE — THIS RUN WRITES ONLY ITS OWN FRAGMENT (`common/parallel-work-state.md`)

Other developers build other stories of the same epic at the same time, and the Verification Engineer signs stories off on
the epic branch. So that none of their PRs conflict on the framework's bookkeeping, **the build path of
this workflow never writes the shared `runtime-artifacts/audit.md` or `runtime-artifacts/aire-state.md`**:

🔴 **Which writer this run is depends on the Phase 4 routing, and is decided there — not before.**
Phases 0–6 produce audit entries before that is known, so **hold them in memory** and write them to the
resolved destination once Phase 7 assigns the story number (or once the spec-only path is confirmed),
with their original timestamps. Never guess the destination early.

**Build path — a work-unit writer** (a CR story is created and built):
- Every audit entry goes to **`runtime-artifacts/stories/story-<N.M>/audit.md`** (same format plus
  `**Unit**: "story-<N.M>"`).
- The story's Story Tracker row, progress and SH counters go to
  **`runtime-artifacts/stories/story-<N.M>/state.md`**; the CR story's dependency-graph node goes to its
  `## Dependency Graph Additions` section (the shared `## Dependency Graph` is never edited), and the
  requirement deltas go to its `## Change Request Additions` section.
- 🔴 **It never writes the shared `runtime-artifacts/audit.md` or `aire-state.md`.**
- 🔴 **State Isolation Check before every commit** (`common/parallel-work-state.md` Section 5.5).

**Spec-only path — an integration-branch writer** (no story exists, so there is no fragment):
- It commits on the epic branch itself, so it **does** write the shared `runtime-artifacts/audit.md` and
  `aire-state.md`, pulling immediately before and pushing immediately after
  (`common/parallel-work-state.md` Section 6). No `runtime-artifacts/stories/…` folder is created.

Reads always use the **resolved view** (`common/parallel-work-state.md` Section 4).

🔴 **Unit key is `story-<N.M>`** — the same key `dev-implement` uses, so
`templates/hooks/check-work-unit.sh` and every evidence path work unchanged. `cr-<n>` is the bundle's
identifier, never a unit key.

---

## Phase 0 — 🔴 Single-Session Check + Preconditions

**Emit this first, verbatim, before any work:**

```
-------------------------------------------------------------------
  AIRE Change Request -- a requirement changed mid-epic
-------------------------------------------------------------------

  Something you already agreed has been revised. I work out what that
  touches -- which requirements move, which stories promised the old
  text, and which tests assert it -- then show you one report and ask
  you once.

  For each affected story I decide one of three things, and tell you why:

    ALREADY BUILT       its code is merged, so I do NOT edit it.
                        A new story replaces the part that changed.
    NOT STARTED YET     no code exists, so its spec is amended in place.
                        No new story needed.
    NOTHING COVERS IT   the requirement is new to the epic.
                        A new story is created for it.

  Two ground rules:
    - Nothing is written to disk until you approve.
    - A story being built right now, or with an open PR, stops me
      rather than having its contract changed under it.
```

Then work **quietly** through Phases 0–8 (V1), emitting only a progress note when a step takes real
time, and only a halt when something blocks. The findings surface once, at Phase 9.

---

## Phase 0.5 — Entry picker (ONLY when the keyword carried no input)

🔴 **Skip this phase entirely when the keyword carried a ticket ID, a description,
`--from-requirements` or `--from-spec <path>`** — the mode is already known, and the run goes straight
to Phase 1. This is a **routing** question (which input do you have), never a clarifying one (what does
your change mean); it is asked once and never re-asked.

```
  How do you want to describe the change?

  [1] Describe it in plain English
      -> "orders over 5000 need supervisor approval"
      -> I find which requirements and stories that affects.

  [2] I already edited spec/plans/requirements.md
      -> I diff your uncommitted edit against the epic branch
         and show you what it breaks. I will NOT rewrite your wording.

  [3] Point me at a separate spec or document
      -> I analyse it as a proposed amendment, without touching
         requirements.md yet.

  [4] It came from a ticket
      -> Give me the ID; I fetch it and use it as the change.

  [5] Exit -- do nothing.

  Type 1, 2, 3, 4 or 5:
```

Branch on the answer, then continue at Phase 1 with the mode already resolved:

| Answer | Next | Resolves to |
|---|---|---|
| **1** | `What's the change? Describe it in your own words.` — take the reply verbatim as the change statement | Mode A |
| **2** | continue immediately | Mode C |
| **3** | `Path to the spec or document? (relative to the project root)` — read it; if the path does not exist, say so and re-ask once, then exit | Mode D |
| **4** | `Which ticket? (<the configured tracker>'s ID)` — fetch it per `common/tracker-sync.md` Section 8 | Mode B |
| **5** | Exit with `Nothing was analysed and nothing was written.` | — |

🔴 **Answer 2 with a clean tree** is the one case worth catching early: say
`spec/plans/requirements.md has no uncommitted change — edit it first, or pick [1] to describe the
change instead.` and exit. It saves the user reaching Phase 0's CR2 check only to be told the same thing.

Log the picker and the raw answer.



**V1**: announce the phase, its inputs and its result. Print each precondition with its **resolved value**.

0. **▶ Hand-back first**: if the checked-out branch is a CR story's branch whose fragment
   (`runtime-artifacts/stories/story-<N.M>/state.md`) holds a `PAUSED —` record (Playwright agent install
   — continue at the step it names) or a `HALTED —` record, this invocation is the developer handing the
   work back after a manual fix — the keyword may be bare and the working tree dirty by design. Skip the
   rest of Phases 0–9 and follow `common/self-heal-limit-guidance.md` Section 4, then continue from the
   first code gate (Phase 10.4) or the halted gate. Otherwise continue with item 1.
1. **Fork check** — execute `workflows/dev-implement.md` **Step 1.7** (the framework-wide single-session
   rule), substituting `epic-change-request`. Inside a fork or subagent → HALT with that step's message,
   change nothing.
2. `runtime-artifacts/aire-state.md` exists with `## Branching` → `Epic Branch` recorded and no
   `Workflow Type: bug` / `Workflow Type: enhancement` in `## Tracker`. Otherwise → stop:
   `No open epic cycle here — a requirement change outside an epic cycle belongs to a base-branch cycle (ticket-implement).`
3. The keyword carries a ticket ID, a description, `--from-requirements`, or `--from-spec <path>`.
   Otherwise → stop with the usage line. Asks nothing.
4. **Working tree (CR2)** — modes A/B/D require `git status --porcelain` empty. **Mode C requires the
   operator's uncommitted `requirements.md` edit**, so there the rule narrows to: **`spec/plans/requirements.md`
   is the only modified path** (`git status --porcelain` lists it and nothing else). Anything else modified
   → stop, listing exactly which files, and say that Mode C analyses a requirements edit alone. Nothing
   modified at all → stop: `No uncommitted change to spec/plans/requirements.md — edit it first, or use
   epic-change-request "<description>".` 🔴 Never stash or discard for the operator.
5. `git fetch origin && git checkout <epic-branch> && git pull --ff-only`.
   **Mode C** carries the operator's uncommitted edit through this step — it is the input, and git
   preserves it. 🔴 **But the pull FAILS (and the branch stays stale) when the incoming commits also
   touched `spec/plans/requirements.md`** — git aborts with *"Your local changes would be overwritten"*
   rather than losing the edit. Detect it by checking the exit status of the pull, and **HALT** with:
   ```
   Cannot refresh <epic-branch>: incoming commits also changed spec/plans/requirements.md,
   and you have an uncommitted edit to it. Your edit has NOT been touched.
     1. Save your edit:        git stash push spec/plans/requirements.md
     2. Refresh the branch:    git pull --ff-only
     3. Re-apply and resolve:  git stash pop      (fix any conflict markers)
     4. Re-run:                epic-change-request --from-requirements
   ```
   🔴 Never run the diff against a stale branch — the requirement delta would be measured from the wrong
   baseline, which is worse than not running at all.
6. **The cycle is still open**: `spec/`, `spec/plans/requirements.md`, `spec/plans/stories.md` and the
   Story Tracker are present, and `aire-archives/epics/<EPIC-ID>-*/` does not exist. Archived → stop: the
   change belongs to a base-branch cycle after the Epic PR merges, or the operator reverts the archive
   commit first.
7. Read `## CI/CD Configuration`, `## Tracker`, `## Code Root`, `team_size` and the
   `tests/.evals/config.json` thresholds. Log the preconditions.

**Output (V1/V3)** — a checklist with the resolved value beside each item:

**Emits nothing on success** (V1) — the resolved values go to the audit trail and the report's header. A failed precondition is a **halt** and prints immediately: what was expected, what was found, and the exact command to fix it.

A failed precondition prints **what was expected, what was found, and the exact command to fix it**.

---

## Phase 1 — Entry Mode resolution

Resolve the mode from the argument shape. **Announce which mode was resolved and why** (V1/V4).

| Mode | Invocation | `snapshot-from` → `snapshot-to` |
|---|---|---|
| **A — Description** | `epic-change-request "orders over 5k need supervisor approval"` | current `requirements.md` → in-memory hypothetical amendment |
| **B — Ticket** | `epic-change-request PROJ-240` | ticket fetched per `common/tracker-sync.md` Section 8 (summary, description, ACs, labels, links); same as A thereafter |
| **C — Drift** | `epic-change-request --from-requirements` | `git show origin/<epic-branch>:spec/plans/requirements.md` → the working-tree file |
| **D — Spec file** | `epic-change-request --from-spec <path>` | current `requirements.md` → current + grafted content from `<path>` |

**Mode C is the only mode that reads an edit the operator already made.** Its consequence is recorded
once here and honoured at Phase 10: 🔴 **the workflow never rewrites the operator's requirement prose in
Mode C** — their working tree is the source of truth. It writes only the version annotations
(`common/change-request-rules.md` Section 4 bucket (b)).

In Modes A/B/D the amendment is **constructed in memory and never written to `requirements.md` before
the gate**; the analyst states plainly that the text does not yet exist on disk.

Where the capture leaves something open (a limit, a rule, a message text), **do not ask**: choose the
reading most consistent with the approved ACs, `requirements.md`, `architecture.md` and the existing
code, and record it as an assumption in `change-request.md` Section 9 **with the alternative not taken**.

Log the invocation and the capture verbatim.

**Emits nothing** (V1). The resolved mode, its reason and the snapshot pair are recorded and appear in the report header.

---

## Phase 2 — Requirement anchor-resolution diff (CR3)

Invoke `agents/change-request-analyst.md` **inline** (never as a subagent) with the snapshot pair.

Match **by REQ-ID**, never by line number, position or semantic similarity alone. Classify each
requirement AMENDED / ADDED / SUPERSEDED / UNCHANGED per `common/requirement-versioning.md` Section 2.

🔴 An ID that cannot be resolved is **reported as unresolved, never guessed at** — it fails predicate
CR3 and the run HALTS (a halt, not a question).

**Output (V2/V3)** — counts first, then the before/after for every changed requirement; unchanged
requirements are a count only:

**Emits nothing** beyond a progress note if the scan is slow (`Analysing <N> requirements…`). The classifications and before/after text go to `requirements-delta.md` and the report's REQUIREMENTS block. 🔴 An unresolved REQ-ID is a **halt** and prints immediately.

---

## Phase 3 — Impact ledger: REQ -> stories -> ACs -> tests (CR6)

The analyst performs five walks. 🔴 **No artifact is "affected" without a recorded reason.**

1. **REQ → stories (primary walk)** — every story whose `**Covers**:` names the changed REQ-ID.
   Normalise `@vN` from both sides before matching. Exact, not heuristic: Rule 2 makes `Covers`
   mandatory and non-empty. Cite the `Covers` line. **A changed REQ-ID with no covering story is
   reported explicitly** — it routes to a new story.
2. **Story → ACs** — the ACs implementing that requirement, each classified UNCHANGED / AMENDED /
   SUPERSEDED. Where `stories.md` has an AC-level `AC-n → REQ-ID` breakdown, use it; where it does not,
   every AC is a candidate and the ledger states which were judged in scope **and why**.
3. **Story → code (confirmation walk)** — three independent sources, recording which agree: manifest
   fragments `tests/.evals/ci-manifest.d/story-*.json`; epic-branch history
   (`git log --format='%H %s' origin/<base>..<epic-branch> -- <path>`, subjects carry
   `[Story N.M / TRACKER-ID]`); `git blame -w -M -C -L <range> -- <file>`. Agreement is reported as
   `n/3`. 🔴 Read the code — never infer relevance from a file's name.
4. **Story → tests and contracts** — `tests/unit/**`, `tests/api/**`, `tests/behavior/steps/**`,
   `tests/e2e/<story-slug>/**`, plus `spec/behavior/story-<N.M>.feature` scenarios,
   `spec/test-plans/<ID>-*/` cases and any `spec/behavior.feature` journey. This list is the input to
   the Test Change Authorization list (CR10).
5. **Concurrency scan** — every work unit `In Development` without a merged PR, and every open `ve/…`
   PR, whose diff touches the change surface (`gh pr diff <n> --name-only`).

Emit the impact tags (CR8): `affects_requirements`, `affects_stories`, `affects_shipped`,
`code_touched`, `doc_only`.

**Output (V2/V3)** — counts first, then the ledger with an evidence cell on **every** row, then the tags:

**Emits nothing** beyond a progress note (`Tracing <N> stories…`). The complete evidence chain — every citation, every agreeing source, every test path — is written to `impact-ledger.md`; the report shows one row per affected story and cites that file.

---

## Phase 4 — Routing (CR9)

Route every affected story on its **pre-run status** and its **live PR merge state**.

🔴 **Status is read from the git snapshot** — `git show origin/<epic-branch>:runtime-artifacts/aire-state.md`
plus the committed `runtime-artifacts/stories/*/state.md` fragments, resolved per
`common/parallel-work-state.md` Section 4 — **never from the working tree**, which the operator may have
edited. 🔴 **Merge state is confirmed live** (`gh pr view <branch> --json state,mergedAt`; for LOCAL,
`git branch --merged <epic-branch>`) and is the authority over any tracker label
(`common/behavior-spec.md` Section 6.1). Both are re-asserted immediately before the Phase 10 writes (TOCTOU).

| Story state (git snapshot) | PR state (live) | What the user is told | Route (internal) | Why |
|---|---|---|---|---|
| `Ready for Development` | — | **NOT STARTED YET** → its spec is amended in place; no new story | `spec-only` | No code exists, so the contract can be corrected directly |
| `In Development` | no PR yet | **BEING BUILT RIGHT NOW** → blocked | 🔴 **HALT** | Never change a spec under an in-flight build |
| `In Development` | PR open, unmerged | **HAS AN OPEN PR** → blocked | 🔴 **HALT** | Its code is not on the epic branch yet → comment on that PR and run `pr-fix <PR>`, or merge it and re-run |
| `In Development` | PR **merged** | **ALREADY BUILT** → a new story replaces the part that changed | `CR-born` | Code is merged; it is never edited in place |
| `Ready for Testing` | merged | **ALREADY BUILT, SIGNED OFF** → a new story replaces the part that changed; status **not** demoted | `CR-born` | The Verification Engineer already signed off; re-verification rides the CR story's test plan |
| no story `Covers` the REQ | — | **NOTHING COVERS IT** → a new story is created | `new` | A requirement new to the epic needs its own story |

🔴 **Say the outcome, then the internal term** (V3). The report leads with what happened and why —
`ALREADY BUILT (PR #31 merged) -> Story 1.10 replaces its contract for AC-4  [CR-born]` — so a reader
who has never opened `common/change-request-rules.md` understands it, while the bracketed term keeps
every row traceable to the CR9 rule that produced it.

- **Every affected story is `Ready for Development`** → the **spec-only path**: Phases 5–9 and 10.3 run,
  no CR story is created, nothing is built; Phase 10.3 ends with a direct commit on the epic branch.
- **Any block** → 🔴 **HALT before writing anything.** Emit it in the same plain language as the report,
  so the user knows what to do without reading a rule file:

```
  CANNOT PROCEED -- 1 story is mid-flight

  1.6  Auth Pages & Session
       BEING BUILT RIGHT NOW (claimed, no PR yet)
       Its contract cannot change while someone is building against it.

  What to do:
    - finish and merge Story 1.6, then run epic-change-request again, or
    - if it already has a PR open, put this change on that PR:  pr-fix <PR>

  Nothing was written.
```

Log it. (A halt, not a question.)

**Output (V4)** — per story: snapshot status **and its source**, live PR state, the chosen route, and
the rule that selected it:

**Emits nothing on success** — the routing table is the report's STORIES block. 🔴 A **block** prints immediately as a halt, naming every blocking story, its state, its PR and the exact way forward, and the run stops without writing anything.

When a story blocks, the block is named in full — story, state, PR, and the exact way forward — and the
run HALTS there without writing anything.

---

## Phase 5 — CR collision check (CR11)

Glob `spec/plans/change-requests/CR-*/change-request.md` and grep each affected story-id in their
`## 3. Impact` tables. An **open CR** is one whose story has no merged PR yet.

- **Collision found** → **APPEND** to that CR's affected-stories set rather than drafting a parallel CR
  over the same ground. Announce it and continue — a stated fact, not a question. The run then carries
  the **existing** `CR-<n>` number through every later phase.
- **No collision** → say so explicitly. 🔴 **Never silence** (V1).

**Emits nothing** — the result (a collision and its CR, or none) appears as one line in the report header.

---

## Phase 6 — Requirement versioning (CR4)

Apply `common/requirement-versioning.md`:

- **AMENDED** → `@v<N+1>`; prior text **retained**, struck through, annotated `Amended by CR-<n> on <date>`.
- **ADDED** → a new `REQ-F-<next>` / `REQ-NF-<next>`, **unversioned**. 🔴 Never `@v1` (RV-3).
- **SUPERSEDED** → retained and marked. 🔴 **Never deleted** — Rule 1 forbids reusing a removed ID, so
  the record must stay visible.
- **UNCHANGED** → byte-identical (RV-5).

Then re-point every covering story's `Covers` to the new version, or route that story as blocked
(CR5). A `Covers` naming an older version while a newer exists is a **stale trace** — a blocking gap of
the same class as Rule 3's gap A.

**Output (V3)**:

**Emits nothing** — version transitions appear in the report's REQUIREMENTS block and in full in `requirements-delta.md`.

---

## Phase 7 — Stage everything in memory (CR16 — nothing on disk yet)

🔴 **No file is written in this phase.** Everything is composed in memory and held for the gate.

### 7.1 Numbering (CR12b)

Read `CR-*` ids and the Story Tracker **from `origin/<epic-branch>` immediately before assigning**:
next CR id = `max(n) + 1` (per-epic, not zero-padded); next story number = the next free `N.M`. Both are
re-verified immediately before the push (Phase 10). On collision: renumber, rename the branch, announce.

### 7.2 The bundle

```
spec/plans/change-requests/CR-<n>/
├── change-request.md        # templates/change-request/change-request.TEMPLATE.md — 10 sections
├── requirements-delta.md    # templates/change-request/requirements-delta.TEMPLATE.md
├── impact-ledger.md         # templates/change-request/impact-ledger.TEMPLATE.md
└── README.md                # index + parallel-safety notes
```

🔴 **`change-request.md` Section 4 carries the machine-read build-unit marker**
`CR-BUILDS-STORY: <N.M>` — exactly one line, the story this CR **builds** (spec-only path:
`CR-BUILDS-STORY: none`). The work-unit guard reads it to require the `testImpact` gate from that story
and from no other; a story merely listed as affected in Section 3 must never match it. A missing or
malformed marker fails Phase 8 check (e).

**Before composing, read first** — without these the content is generic, and the depth rules are not
optional: the body of every story being superseded or amended; the changed requirements' full text
(both revisions); the code implementing the affected stories (from their `## Implementation steps` and
the Phase 3 ledger); the affected `.feature` files and test plans.

### 7.3 CR12 — dependency-cycle check

Walk the `requires` graph across every affected and proposed story (Tarjan SCC). An SCC of size > 1
intersecting the CR's scope means there is no safe ordering → 🔴 **ABORT**, print the cycle members,
write nothing. Cycles elsewhere are reported and do not block.

### 7.4 Staged spec edits

- **`spec/plans/requirements.md`** — the version annotations (Section 3 of the versioning file).
  🔴 **SKIPPED entirely in Entry Mode C** for the prose; only annotations are applied.
- **`spec/plans/stories.md`** — the CR story appended in the same format as every other story
  (`**Tracker ID**:`, `**Covers**:`, `**Requires**:`, `**Change Request**: spec/plans/change-requests/CR-<n>/`);
  every AMENDED / SUPERSEDED AC of earlier stories annotated **in place** —
  `AC-3 (amended by CR-<n>, <date>): <new text>`, old text struck through, **never deleted**; the
  `## Requirements Coverage Matrix` rebuilt (Rule 8 item 3).
- **`spec/behavior/story-<N.M>.feature`** — the CR story's contract per `common/behavior-spec.md`
  Section 2, one `@AC-n` scenario per AC, failure paths included; amended scenarios of earlier stories
  edited in place keeping their `@AC-n` tag and adding `@amended-by-cr-<n>`; a SUPERSEDED AC's scenario
  retired (removal recorded in the bundle; the AC stays in `stories.md`, marked).
- **`spec/behavior.feature`** — any cross-story journey the change alters.
- **`spec/test-plans/**`** — via the **`ve-implement` skill in WORKFLOW MODE** only
  (`implementation/specs-and-test-plans.md`): once for the CR story (its plan carries a
  "Re-verification of affected stories" section) and once per affected story, scoped to its AMENDED /
  SUPERSEDED ACs. 🔴 Never hand-edited.
- **`spec/plans/architecture.md`** — only when the change alters a design decision: amend, bump its
  version, and **regenerate** `tests/.evals/rubrics/architecture-rubric.json` from Section 10
  (`implementation/architecture-doc.md` Section 4). 🔴 Never hand-edit a rubric.
- **Dependency graph** — build path: the fragment's `## Dependency Graph Additions` only; spec-only
  path: `spec/plans/dependency-graph.yml` and the shared `## Dependency Graph` directly.
- **Rule 4 record** — `Requirements coverage verified post-design: [R]/[R] REQ-IDs — [timestamp] (re-verified after CR-<n>)`.

### 7.5 Coverage check (blocking, fixed silently)

Every CR-story AC and every AMENDED AC has ≥1 scenario and ≥1 test case; nothing remains for a
SUPERSEDED AC; every amended requirement has a story tracing to its new version.

**Output (V3)** — a file-by-file manifest of what **will** be written, grouped by CR16 allow-list
bucket, each with a line count, marked clearly as *staged, not written*:

**Emits nothing** — the manifest appears in the report as per-bucket counts (`CR bundle 4 · specs 2 · test plans 2 · …`), not as a file-by-file listing. 🔴 A CR12 dependency cycle is a **halt** and prints immediately.

---

## Phase 8 — Pre-emission validation (CR13)

Eight checks against the **in-memory** staging, **before** the preview. First failure HALTS — a
malformed bundle is never shown to the operator.

| # | Check |
|---|---|
| (a) | **Route coverage** — every affected REQ-ID is routed **exactly once** (CR-born, spec-only, or new story). Both → fail (over-counted). Neither → fail (uncovered). |
| (b) | **Supersede integrity** — every CR-born story names a real story in `supersedes`, and that story's PR is confirmed merged. |
| (c) | **Dependency inheritance** — every CR-born story's `requires` is a superset of the superseded story's, minus ids superseded in this same CR. |
| (d) | **Bundle inventory** — `change-request.md`, `requirements-delta.md`, `impact-ledger.md`, `README.md` all present. |
| (e) | **Section presence + build marker** — `change-request.md` carries all 10 `## ` sections in order (empty ones written as `(none — <reason>)`), **and exactly one `CR-BUILDS-STORY:` line** whose value is this run's story number, or `none` on the spec-only path. Zero, several, or a value that is not the story being built → fail. |
| (f) | **Fact-only scan (CR14)** — regex for severity adjectives and advisory verbs across every staged artifact; count must be 0. |
| (g) | **Coverage** — Phase 7.5's result; plus RV-1…RV-7 from `common/requirement-versioning.md`. |
| (h) | **One CR per run** — exactly one bundle is staged, unless this is a CR11 append (which stages zero new bundles and edits one existing). |

**Output (V1)** — all eight with **computed results**, never bare ticks:

**Emits nothing on success** — all eight results are computed, recorded in the audit trail, and summarised in the report as `pre-emission: 8/8 PASS`. 🔴 Any failure is a **halt**: it prints the failed check, the offending file and the remediation, and the report is never shown.

On failure: print the failed check, the offending file/section, the rule violated, and the remediation.
Do **not** proceed to Phase 9.

---

## Phase 9 — 🚦 THE SINGLE GATE (CR16 / V5)

**This is where the whole run surfaces.** Phases 0–8 worked quietly; everything they found is
presented **here, once**, as one scannable report — then the run halts for the only question it asks.

🔴 **Nothing has been written to disk at this point.**

**Shape (V3): counts → table → decisions.** Every number is real; the deep evidence is in the bundle
and is **cited, never pasted** (V2/V3/V5). The report fits on roughly one screen.

```
+-------------------------------------------------------------------+
|  CR-<n>  --  REVIEW BEFORE APPROVING                              |
|  Nothing has been written to disk.                                |
+-------------------------------------------------------------------+

  <one-line summary of the change, in the user's own words>

  Entry mode  : <A description | B ticket <ID> | C your requirements.md edit | D spec file>
  Epic branch : <epic-branch> @ <sha>          Tracker: <TYPE>
  Bundle      : spec/plans/change-requests/CR-<n>/     (staged, not written)
  Collision   : <none | appending to CR-<m>>           Pre-emission: 8/8 PASS

WHAT CHANGED IN THE AGREEMENT    <A> amended, <B> added, <C> withdrawn, <D> untouched
  <REQ-ID> -> @vN   <what differs, one line>

WHAT THAT MEANS FOR YOUR STORIES     Blocked: <none | N -- see below>
  <N.M>  <title>
         ALREADY BUILT (PR #<n> merged)
         -> Story <X.Y> replaces its contract for <AC-n>          [CR-born]
  <N.M>  <title>
         NOT STARTED YET
         -> its acceptance criteria and spec are amended in place  [spec-only]
  --     (nothing covers <REQ-ID>)
         -> new Story <X.Y>                                        [new]

  Nothing already built is edited in place. <X> new, <Y> amended, <Z> untouched.

TESTS          <n> may change; <m> stay as regression guards
  <file>  <test>  <action>  <- <AC-n> <class>
  ...  full list in the bundle

WRITES         <N> files, all inside the allow-list
  CR bundle <n> · requirements.md <n> · stories.md <n> · specs <n> · test plans <n>
  architecture+rubric <n> · state <n>        outside allow-list: 0

DECISIONS I MADE FOR YOU  (overrule any with Request Changes)
  1. <decision> -- <why>.  Rejected: <alternative>.
  2. ...

  Full detail: spec/plans/change-requests/CR-<n>/change-request.md
               (+ requirements-delta.md, impact-ledger.md -- open them to see every citation)

A) Request Changes -- tell me what to change
B) Approve & Build -- apply the bundle, then build, test and raise the
   [STORY] PR into <epic-branch>

[Answer]:
```

(Spec-only path: option B reads `Approve & Apply — amend the specs and commit them to <epic-branch>`.)

🔴 **What this report must NOT do**: paste the `change-request.md` body (it is staged and its path is
printed — re-printing it buries the decision); reprint the per-phase working state; or list every
citation when the ledger holds them. The user decides from this screen and opens the bundle when they
want the proof.

- **`A`** → revise the staging (a requested change to a Section 9 decision moves that row to "decided by
  the user" with their wording), add a Section 10 revision entry, re-run Phase 8, present again.
  🔴 Nothing has been written, so there is nothing to roll back.
- **`B`** → Phase 10.
- Any other answer → re-prompt: `Please answer A (Request Changes) or B (Approve & Build).`

Log the prompt and the complete raw answer.

---

## Phase 10 — Apply, then build

🔴 **Everything below happens only after the Phase 9 `B`.** Writes are ordered; a sub-step failure HALTS
with rollback instructions (`git status` + `git restore`) rather than leaving a partial apply (CR16).

### 10.1 Tracker actions and the claim (build path; spec-only skips to 10.3)

Runs on the refreshed epic-branch checkout, because the story branch name needs the tracker ID. Nothing
is committed here.

1. **Re-assert the Phase 4 snapshot statuses and live PR states** (TOCTOU). Any story that changed state
   since Phase 4 → HALT and re-run; never write against stale routing.
2. **Re-check the CR id and story number** against `origin/<epic-branch>` (CR12b); renumber if taken.
3. **Tracker item** (`common/tracker-sync.md`; LOCAL: local only, `Tracker ID` = `LOCAL`): no ticket →
   create a Story (Section 3 labels/fields, `Built with AIRE v[N]` footer) linked to the Parent Epic
   (Section 6); ticket given (Mode B) → use it and link it to the Parent Epic if not linked yet. Verify.
4. **Story Tracker row + claim** — in the fragment `runtime-artifacts/stories/story-<N.M>/state.md`,
   never the shared table: add Story `<N.M>` and claim it in the same step — `In Development`, `Start`
   and `Recorded` set, tracker transitioned to In Development, assignee = the operator, `aire-v[N]`
   label (`common/tracker-sync.md` Sections 4, 5, 9). Record the `## Claim` block.
5. **Epic sync**: Parent Epic already Ready for Testing → move it back to In Development (authorised by
   the gate), verify, log.
6. **Comment on every affected story's tracker item**:
   `Requirement amended by CR-<n> (<link>): <REQ-IDs@vN>. Delivered by Story <N.M>; re-verified under it.`

### 10.2 Branch and baselines (build path)

Execute `workflows/dev-implement.md` **Step 1.5** for Story `<N.M>`: the story branch
`story/<TRACKER-ID>-<N.M>-<kebab-title>` is cut from the refreshed epic branch (its dependency-merge
check re-confirms every `requires` is merged), the work-unit guard is installed
(`sh aire-workflow/templates/hooks/check-work-unit.sh --install story-<N.M>`), then the three baselines
are captured **before any edit** — full suite (Item 4.5), static D1–D7 with bootstrap (Item 4.6), full
Playwright E2E headless (Item 4.7). The uncommitted fragment from 10.1 carries onto the branch.

### 10.3 Write the bundle and the approved spec edits

In this order, each re-asserting the snapshot status immediately before it:

1. **The CR bundle** → `spec/plans/change-requests/CR-<n>/` (4 files).
2. **`spec/plans/requirements.md`** — version annotations. 🔴 **Mode C: annotations only**; the
   operator's prose is not rewritten.
3. **`spec/plans/stories.md`** — the CR story appended; every AMENDED / SUPERSEDED AC annotated in
   place, old text struck through, never deleted; the `## Requirements Coverage Matrix` rebuilt.
4. **Behaviour specs** — the CR story's `spec/behavior/story-<N.M>.feature`; amended scenarios of
   earlier stories edited in place (`@AC-n` kept, `@amended-by-cr-<n>` added); retired scenarios removed
   and recorded; `spec/behavior.feature` journeys amended.
5. **Test plans** — the `ve-implement` skill in **WORKFLOW MODE** (never re-implemented), once for the
   CR story and once per affected story scoped to its AMENDED / SUPERSEDED ACs.
6. **Architecture + rubric** — only when the bundle records a design change; the rubric is regenerated,
   never hand-edited.
7. **Dependency graph** — build path: the fragment's `## Dependency Graph Additions`; spec-only path:
   `spec/plans/dependency-graph.yml` + the shared `## Dependency Graph`.
8. **Rule 4 record** — refresh `Requirements coverage verified post-design: …(re-verified after CR-<n>)`.

**Spec-only path ends here**: update the amended stories' tracker items (AC text + a comment naming the
bundle), commit on the epic branch —
`[Spec] CR-<n>: amend <REQ-IDs@vN> and Story <X.Y>[, …]` with the `AIRE-Version: [N]` trailer — push,
emit the spec-only handoff (Phase 11), stop. **Build path**: these edits ride the CR story's own commit
(10.6) and are never pushed to the epic branch directly.

**Output (V1)**: per write, the path and its byte/line count.

### 10.4 Build — the COMPLETE gate chain

Execute `workflows/dev-implement.md` from **Step 4.3** (Playwright Readiness — frontend plans only) and
**Step 4.5** (behaviour-spec verification) through **Part 2 generation**, then **Steps 6 → 6.8**, with
these overrides and nothing else changed:

- **Plan**: `change-request.md` **Section 6 IS the code-generation plan** (it satisfies `dev-implement`
  Step 4.1); mark its checkboxes as steps complete. No separate plan file.
- **Generation order**: application change → the authorised test changes from Section 5b (update
  obsolete assertions, delete dead tests, each traced to its AC) → new tests (Section 5c).
- **Gate semantics with authorised changes**: in the full regression (Step 6.5), B2 (Step 6.1) and the
  Playwright E2E regression (Step 6.8), a test green at baseline and red now is a **regression to fix in
  the application code** — unless it is on the Test Change Authorization list, in which case it must
  already have been updated and must now pass. A red test the analysis missed may join the list **only**
  if it asserts an AC classified AMENDED or SUPERSEDED: add it to Section 5b with a Section 10 revision
  entry, announce it, continue. A red test tracing to an UNCHANGED AC is always a regression.
- Every gate keeps its SH-LOOP and 3-attempt budget; exhaustion → SH-4 HALT with the Retry-Limit Report.

🔴 **Executed by reference, never restated.** No gate, threshold, SH-LOOP ID or retry cap is redefined
in this file.

**Output (V6)**: per gate — name, command, measured value against its threshold, and
`PASS` / `FAIL` / `ERROR` / `N/A` (the closed vocabulary of `common/eval-framework.md`). Self-heal
attempts print `attempt n of 3` with the **root cause stated before the fix**:

```
PHASE 10.4  GATE CHAIN  (dev-implement Steps 6 -> 6.8, by reference)
  unitCoverage ....... npm test -- --coverage      changed-lines 94.1% >= 90%   PASS
  behaviorB1 ......... run.sh b1                   6/6 scenarios, 4/4 @AC tags  PASS
  behaviorB2 ......... run.sh b2                   31/31 other scenarios        PASS
  behaviorB3 ......... --                          not the last unit (2.4 open) N/A
  apiContract ........ npm run test:api            12/12, 401+403 covered       PASS
  regression ......... npm test                    0 new failures vs baseline   PASS
  D1_lint ............ eslint --format json        0 new > delta 0              PASS
  ...
  SH-LOOP-1 attempt 1 of 3 -- root cause: new branch in approveOver() uncovered
                              fix: added rules.test.ts "routes at exactly 5000"
                              re-run: 94.1%  PASS
```

### 10.5 Test Impact Reconciliation (SH-LOOP-15)

A deterministic check, after 10.4 and before the review. Mechanics:
`common/self-heal-limit-guidance.md:123`; gate: `common/eval-framework.md` Section 5
(`gates.testImpact`, local-only).

1. `git diff --name-status $(git merge-base origin/<epic-branch> HEAD) -- tests/ spec/behavior/ spec/behavior.feature spec/test-plans/`
2. Every **modified or deleted** test file or test case maps to a Section 5b row (or is one of the CR
   story's own new files). A modified or deleted test not on the list → **violation**: restore it from
   the merge-base and fix the application code instead.
3. Every Section 5b row is done (an `update` row whose test was left untouched and now fails is a gate
   failure, not a skip).
4. Every CR-story AC and every AMENDED AC has ≥1 scenario that executed in B1/B2 and ≥1 test case; no
   scenario remains for a SUPERSEDED AC.
5. **CR-specific**: every amended requirement has ≥1 story whose `Covers` names its **new** version
   (CR5 — no stale traces).

Write the result to `reports/eval-evidence/story-<N.M>/test-impact-reconciliation.md` and into
`eval.json` `gates.testImpact`. A failure → fix → re-run the affected 10.4 gates (continuing their
counters) → re-check; one cycle = one SH-LOOP-15 attempt; cap 3; exhaustion → SH-4.

### 10.6 Review, commit, preflight, PR, attestation, PR review

1. **Code Review** — `workflows/dev-implement.md` **Sections A → B → C**, with the AC scope set to the
   CR story's ACs **plus every AMENDED AC of the affected stories** (as amended) and the `Covers`
   REQ-IDs of both, read at the **version each story traces to**
   (`common/requirements-traceability.md` Rule 6). The security pass stays diff-scoped; J1/J2 are
   blocking. The report adds a **Change Impact Verification** table: each affected story → amended ACs →
   Met / Partially Met / Not Met with `file:line`.
2. **Sections D and E** unchanged — including **Section D Step 1.2's Artifact Completeness Check**
   (SH-LOOP-16, `common/work-unit-artifacts.md` Section 5), which for this unit also requires the
   `testImpact` evidence (the work-unit guard detects the CR bundle's plan — see
   `templates/hooks/check-work-unit.sh`). Section D runs it in its own place; it is never run twice or
   lifted out of Section D. With:
   - the State Isolation Check, then the commit including 10.3's spec edits, the CR bundle, the
     reconciliation evidence and the fragment `runtime-artifacts/stories/story-<N.M>/` (never the shared
     `audit.md` / `aire-state.md`) — `[Story <N.M> / <TRACKER-ID>] CR-<n>: <summary>` +
     `AIRE-Version: [N]`;
   - **CR12b re-verification** of the CR id and story number immediately before the push;
   - `pr-generator` in **WORKFLOW MODE**, target = the epic branch, `[STORY]` prefix; the PR body also
     carries a `## Change Request` section (the requirement deltas with version transitions, affected
     stories and amended ACs, the Test Change Authorization list) — **read the body back and verify** it
     landed;
   - CI preflight and attestation only when `Enabled: Yes`;
   - `pr-review` in **AUTO MODE**.

### 10.7 CR13 self-verification

Print the Section 2 predicates of `common/change-request-rules.md` with **computed results** — CR3, CR4,
CR5, CR6, CR8, CR9, CR10, CR11, CR12, CR12b, CR14, CR16, CR13-V — plus RV-1…RV-7. A predicate that could
not be computed counts as **fail**.

---

## Phase 11 — Handoff (verbatim, the last output)

**Build path**:

```
 CR-<n> APPLIED — STORY <N.M> PR RAISED, NOT MERGED. Story <N.M> stays In Development until it merges.
   PR: <PR URL>  →  target `<epic-branch>`   Bundle: spec/plans/change-requests/CR-<n>/
   Requirements: <REQ-F-03 → @v2, REQ-F-11 added, REQ-F-07 superseded>
   Affected stories: <X.Y (AMENDED AC-n), …> — their specs, test plans and tests were updated in this PR.
   Gates: all PASS / N/A, including Test Impact Reconciliation — scorecard in the PR body.

NEXT ACTIONS:
   1.  Review, approve and MERGE the PR into `<epic-branch>` yourself — the framework never merges.
       Rejected instead? Leave comments on the PR, then type: pr-fix <PR URL>
   2.  After it merges, the Verification Engineer runs ve-list-work on `<epic-branch>` — Story <N.M>'s test plan includes the
       re-verification cases for the affected stories.
   3.  More stories to build? type: dev-implement

Type the keywords EXACTLY as shown — any other phrasing is not a framework trigger.
```

**Spec-only path**:

```
 CR-<n> APPLIED — SPECS AMENDED, no code existed yet, so nothing was built.
   Requirements: <REQ-F-03 → @v2, …>   Bundle: spec/plans/change-requests/CR-<n>/
   Amended: <Story X.Y AC-n, …> in stories.md, their .feature scenarios and test plans; tracker updated.
   Commit <sha> pushed to `<epic-branch>`.

NEXT: the amended stories are built as usual — type: dev-implement
```

Log which variant was shown.

---

## Edge cases — every one resolved without a question

| # | Situation | Handling (default recorded in `change-request.md` Section 9 where it is a decision) |
|---|---|---|
| E1 | Affected story not started (`Ready for Development`) | Spec-only amendment of its ACs, scenarios and test cases; `requires` edge onto the CR story if its code builds on the change |
| E2 | Affected story being built right now (`In Development`, no PR) | **HALT — blocked**: never change a spec under an in-flight build; finish it, then `pr-fix` (open PR) or re-run (merged) |
| E3 | Affected story has an OPEN, unmerged PR | **HALT — blocked**: comment the change on that PR and run `pr-fix <PR>`, or merge it and re-run |
| E4 | Affected story merged, awaiting the Verification Engineer | CR-born story; its test plan is amended in the same PR |
| E5 | Affected story already `Ready for Testing` | Not demoted; tracker comment; re-verification cases live in the CR story's plan |
| E6 | Parent Epic already Ready for Testing | Moved back to In Development — stated in Section 7, authorised by the gate, verified |
| E7 | Epic already archived | Stop — the change belongs to a base-branch cycle (`ticket-implement`) after the Epic PR merges, or the operator reverts the archive commit |
| E8 | A changed requirement has NO covering story | **New story** (CR9). This is the case only a requirement-first walk finds; it is reported, never silently dropped |
| E9 | The amendment would violate the Security Baseline | **Default**: the CR story is shaped to comply (adds the missing authorisation / validation); Section 9 records what was reshaped and why |
| E10 | Requirement SUPERSEDED (behaviour withdrawn) | ACs marked superseded (kept); scenarios/test cases retired; dead tests deleted via the authorization list; dead code removed; requirement retained and marked, never deleted |
| E11 | Mode C: operator edited a requirement the epic has no story for | Classified ADDED; routes to a new story (E8) |
| E12 | Mode C: operator also modified files outside the watched sources | **Stop** listing them (CR2) — never stash or discard their work |
| E13 | Two clones mint the same `CR-<n>` or story number | Re-read from `origin/<epic-branch>` right before assignment and again before the push; on collision renumber, rename the branch, announce (CR12b) |
| E14 | Story already belongs to an open CR | **Append** to that CR (CR11), never a parallel bundle |
| E15 | Dependency cycle among affected/proposed stories | **ABORT** (CR12), print the SCC, write nothing |
| E16 | LOCAL tracker | Everything stays in `stories.md` and the Story Tracker; no external calls |
| E17 | CI/CD disabled | Manifest reconciliation, preflight and attestation skipped, as in `dev-implement` |
| E18 | The CR story becomes the last unit | B3 runs on it when every other unit's PR is merged (live merge state, `dev-implement` Step 6.1) |
| E19 | A test outside the authorization list goes red | Regression — fix the code; it joins the list only if it asserts an AMENDED/SUPERSEDED AC (announced, revision-logged) |
| E20 | Another story merges into the epic branch during the run | The PR shows it; if it conflicts, `pr-fix` merges the epic branch in and re-runs every gate |
| E21 | The capture is ambiguous (a limit, a rule, a message text) | **Default**: the reading most consistent with approved ACs, requirements, architecture and existing code; Section 9 records the assumption and the alternative |
| E22 | CR story PR rejected | `pr-fix <PR>` — it detects the change document and also re-runs 10.5 |
| E23 | It is not a requirement change at all — behaviour or a defect | Out of this flow: new/changed behaviour with no requirement change is `epic-enhance`; a defect is `epic-bugfix`. The run stops with that pointer **before writing anything** |
| E24 | An unversioned `Covers` after its requirement reached `@v2` | **Stale trace** — a blocking gap (CR5); the story is re-pointed or routed |

---

## Critical Rules

- 🔴 **THE GATE IS THE ONLY DECISION QUESTION.** No clarifying questions, no option menus mid-run, no
  decisions asked of the user after analysis starts. Decisions the framework makes are written into
  Section 9 **with their rejected alternative** and overruled only via Request Changes. The single
  exception is the **Phase 0.5 entry picker**, shown only when the keyword carried no input — it routes
  on which input the user has, never on what the change means, and is skipped whenever input was given.
  Blocks, cycles, pre-emission failures and retry limits are halts, not questions.
- 🔴 **NOTHING ON DISK BEFORE THE GATE** (CR1 / CR16). Everything is staged in memory; every written path
  falls inside the `common/change-request-rules.md` Section 4 allow-list.
- 🔴 **REQUIREMENTS ARE VERSIONED, NEVER RENUMBERED OR DELETED** (CR4). AMENDED → `@v<N+1>` with prior
  text retained; ADDED → unversioned; SUPERSEDED → retained and marked.
- 🔴 **STATE FROM THE GIT SNAPSHOT, MERGE STATE LIVE** (CR9), re-asserted immediately before writing.
- 🔴 **NEVER CHANGE WORK IN FLIGHT.** A story being built, or with an open PR, blocks the change.
- 🔴 **ONLY AUTHORISED TESTS CHANGE** (CR10). Every other red test is a regression fixed in the code.
- 🔴 **CONTRACTS MOVE TOGETHER.** An amended AC moves its `stories.md` text, scenario, test case, tests
  and (UI) Playwright spec in the same PR; scenarios and plans are never rewritten to match code, and
  Playwright specs only through the `playwright-implement` subagents.
- 🔴 **NEVER FEWER GATES.** Every `dev-implement` gate runs on the CR story, plus Test Impact
  Reconciliation. "One bundle" means less ceremony only.
- 🔴 **NO STATUS DEMOTION, NO MERGING.** Statuses move only as `dev-implement` and `ve-list-work` define;
  the framework never merges a PR.
- 🔴 **INTO THE EPIC, AS A STORY.** Branch from the epic branch, `[STORY]` PR into the epic branch, Story
  Tracker row, dependency-graph node — never a base-branch cycle, never a new `Workflow Type`, never a
  change to `## Tracker`'s Parent Epic.
- 🔴 **SELF-CONTAINED.** This workflow never reads, cites or delegates to `epic-enhance.md` or
  `epic-bugfix.md`.
- 🔴 **VERBOSE BY CONTRACT** (CR13-V / V1–V9). No quiet mode, no verbosity flag, no summarising the
  bundle at the gate.
- 🔴 **SINGLE SESSION, BOUNDED LOOPS, FULL AUDIT.** No forks (Phase 0); 3 attempts per loop; every audit
  entry carries the `dev-implement` fields plus `CHANGE REQUEST`; every commit carries `AIRE-Version: [N]`.
