# Behavioural Test Evidence — Story 1.1

## B1 — Unit scope (this story's own feature)
- **Feature file**: `spec/behavior/story-1.1.feature` (5 scenarios, @AC-1..5)
- **Containerised**: YES (Podman)
- **Image**: `aire-behavior:local` · digest `sha256:19799b21265b9ed128fe58f96cb290393c0fb863ec8ff899482f7be543fb4b7e`
- **Command**: `podman run --rm -v <source dirs> -w /src -e AIRE_STORY_KEY=story-1.1 aire-behavior:local b1`
  (source dirs mounted individually — src/, tests/, spec/, cucumber.mjs, backend/ro, frontend/ro, eslint/prettier — so the container's own Linux-compiled sqlite3 native binding is used, not the host's macOS binary)
- **Result**: **5 scenarios passed, 27 steps passed** — every @AC-n tag executed ✅
- **Scenarios**:
  - @AC-1 Next.js scaffold exists, legacy untouched — PASS
  - @AC-2 all four models ported with associations — PASS
  - @AC-3 Sequelize singleton across repeated loads — PASS
  - @AC-4 config read from env, no hardcoded creds — PASS
  - @AC-5 boot, authenticate, eager-load smoke query — PASS

## B2 — Cumulative scope (every OTHER feature file)
- **Result: N/A** — `spec/behavior/story-1.1.feature` is the ONLY feature file in the repo (this is the first story of the cycle). No other feature files exist to run.

## B3 — Epic scope (last work unit only)
- **Result: N/A — deferred.** This is NOT the last work unit: 8 other stories (1.2-1.9) have no merged PR yet (verified: none raised). B3 runs only on the last work unit of the cycle, detected by PR-merge state.

## Infrastructure created this story (create-if-missing, committed on the story branch)
- `tests/.evals/behavior/Containerfile` (node:22, sqlite3 built from source)
- `tests/.evals/behavior/run.sh` (tier dispatcher b1|b2|b3)
- `cucumber.mjs` (config; AIRE_STORY_KEY selects the B1 feature)
- `tests/behavior/steps/story-1.1_steps.js` (step definitions bound to the DB-layer public surface)

## SH-LOOP-7 attempt log (B1)
- **Attempt 1** — root causes: (a) Cucumber Expressions treat `/` as an alternative separator and `(...)` as optional text, so string step definitions containing `backend/`, `src/`, and `(or DB_* variables)` did not match → converted the affected step definitions to regex patterns; (b) the container's node:20 base was below cucumber-js 13's Node floor (22/24/26) → bumped the Containerfile to node:22; (c) the host's macOS-compiled sqlite3 native binding failed to load in the Linux container when the whole `$PWD` (incl. node_modules) was bind-mounted → switched to node:22 full image building sqlite3 from source, and mounted only source dirs so the container's own binding is used. Re-verify: `podman run ... b1` → 5/5 scenarios, 27/27 steps pass. Loop exited successfully.
