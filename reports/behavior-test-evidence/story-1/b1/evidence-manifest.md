# Behavioural Test Evidence — B1 (Story 1: Next.js application scaffold)

**Tier**: B1 — this work unit's own `spec/behavior/story-1.feature`
**Containerised**: true
**Image**: `localhost/aire-behavior:local`
**Image ID (digest)**: `sha256:89cc4183c3600c79389967ae78a8c84603d593e06ba8e49678e508d553ee0c5e`
**Command**: `podman run --rm --timeout 60 -v "$PWD:/work:Z" -w /work -e AIRE_STORY_KEY=story-1 aire-behavior:local "bash tests/.evals/behavior/run.sh b1"`
**AIRE_STORY_KEY**: `story-1` (resolves to `spec/behavior/story-1.feature`)

## Result

- **4 scenarios, 4 passed** (0 failed)
- **24 steps, 24 passed** (0 failed, 0 skipped)
- Duration: 8.1s
- Every `@AC-n` tag executed: `@AC-1`, `@AC-2` (x2 — the port-listen assertion and the port-collision
  assertion are both under the same AC-2 scenario), `@AC-3`, `@AC-4` — all 4 acceptance criteria
  covered by an executed scenario.

## Scenario-by-scenario

| Scenario | Tag | Result |
|---|---|---|
| conduit-next is a registered npm workspace member running Next.js 15 App Router | @AC-1 | PASS |
| The conduit-next dev server starts without errors on a non-colliding port | @AC-2 | PASS |
| ESLint and Prettier are configured for conduit-next in plain JavaScript | @AC-3 | PASS |
| backend and frontend are unmodified by this story | @AC-4 | PASS |

## Files

- `behavior-test-run.log` — raw progress-format output from the actual `run.sh b1` gate invocation.
- `behavior-test-report.json` — machine-readable Cucumber JSON report, captured via a second,
  identical invocation of the same underlying command (`run.sh`'s own marked runner block uses
  `--format progress` only, template-locked; `--format json:<path>` was added as an EXTRA output
  format on a supplementary run of the exact same command, purely to satisfy the mandatory
  machine-readable evidence requirement — it does not alter run.sh or the gate's pass/fail path,
  which already passed on the unmodified `run.sh b1` invocation above).

## Fixes required to make this tier runnable (bootstrap, this story's own responsibility since it is
the first to reach this gate)

1. **`@cucumber/cucumber` installed as a root devDependency** (`^11.3.0`) — `run.sh`'s runner
   invocation (`npx --prefix frontend cucumber-js`) resolves it via npm workspace hoisting from the
   root install; `frontend/package.json` itself was NOT modified (verified — AC-4 preserved for the
   Gherkin tooling too).
2. **`git` added to `tests/.evals/behavior/Containerfile`** — the `node:20-slim` base image ships
   without it, and this story's own AC-4 step definition needs `git diff --stat`. Added as a single
   `apt-get install` line OUTSIDE the template's marked `STACK-RESOLVED BEHAVIOUR DEPS` block (that
   block is reserved for the Gherkin-runner-specific dependency only).
3. **`git config --global --add safe.directory /work`** inside the AC-4 step definition — the
   bind-mounted repo is owned by a different UID inside the container, which git refuses to operate on
   by default ("detected dubious ownership").
4. **`next dev`'s child process spawned `detached: true`, killed via `process.kill(-pid, ...)`** —
   Turbopack spawns its own worker subprocesses; killing only the direct child left orphans running,
   which kept the container's PID 1 blocked and the container never exited on its own (observed:
   containers still `Up` 27-36 minutes after cucumber-js itself had already finished and reported all
   green). Fixed in `tests/behavior/steps/story-1.steps.js` — confirmed the container now exits cleanly
   with `EXIT=0` on its own, no manual `podman rm -f` required.

None of these are suppressions of a finding — they are genuine environment/tooling setup, consistent
with `common/eval-framework.md` Section 2.3's bootstrap-before-measurement discipline.
