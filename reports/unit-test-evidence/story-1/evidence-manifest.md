# Unit Test & Coverage Evidence — Story 1: Next.js application scaffold

**Command**: `npx vitest run tests/unit/conduit-next/ --coverage --reporter=verbose`
**Test runner**: Vitest 4.1.11 (root `vitest.config.js`, shared with `frontend/`)
**Coverage tool**: `@vitest/coverage-v8` (V8 provider), reporters: text, lcov, json-summary

## Result

- **Tests**: 3/3 passing (`tests/unit/conduit-next/scaffold.test.js`)
  - `starts without throwing or exiting non-zero (AC-2)`
  - `listens on port 3002 and serves a successful response (AC-2)`
  - `serves the App Router home page content (AC-1)`
- **Coverage**: `0/0` statements — see the documented exception below. `unit-test-run.log` and
  `coverage-report/` (`lcov.info`, `coverage-summary.json`) are attached as required, even though the
  coverage tool reports no instrumentable statements for this story's diff.

## Documented, surfaced exception to the `unitTestCoverageMin` (90%) gate

Story 1 is a pure scaffold (`create-next-app@15`, plain JavaScript, App Router, REQ-NF-06 — no
TypeScript). Its only new "code" is:

- `conduit-next/app/page.js`, `conduit-next/app/layout.js` — Next.js's own generated App Router
  files. These are **plain `.js` files containing JSX**, a combination Next.js's own SWC/Turbopack
  build pipeline accepts, but this repo's shared Vitest transform (`@vitejs/plugin-react-swc` via Vite
  esbuild, the same config `frontend/`'s tests already use) does **not** auto-detect as JSX — esbuild
  only treats `.jsx`/`.tsx` as JSX by default, and `vite:import-analysis` runs its own syntax check
  ahead of any esbuild loader override, so even an explicit `esbuild.loader`/`optimizeDeps` override
  could not make Vite import these files directly. **Renaming them is not an option**: Next.js's App
  Router requires the exact filenames `page.js`/`layout.js` to route at all — a `.jsx` rename would
  break AC-1's own "running Next.js 15 with the App Router" requirement.
- `conduit-next/next.config.mjs` — the generated config is an empty object (`const nextConfig = {};`),
  with no statements or branches to meaningfully instrument.

**What was tried, and why it was rejected, before accepting this exception**:
1. Import `app/page.js` directly and render it with `@testing-library/react` inside Vitest (in-process,
   would have been instrumentable). **Rejected**: fails at Vite's import-analysis stage with
   `Failed to parse source... contains invalid JS syntax` — confirmed by direct reproduction.
2. Add an `esbuild.loader`/`optimizeDeps.esbuildOptions` override to force `.js` under `conduit-next/`
   to parse as JSX. **Rejected**: `vite:import-analysis` performs its own syntax validation before the
   esbuild transform/loader override is consulted, so the same parse error persists — confirmed by
   direct reproduction with the override in place (then removed again, since it added complexity for
   no effect and does not need to ship).
3. Import a plain, non-JSX file for coverage (`next.config.mjs`). **Rejected**: zero statements/branches
   exist in the generated config — instrumenting it would report a misleading "100%" over nothing.

**What was NOT done, and why**: writing extra, artificial custom logic into `conduit-next/` (e.g. an
unused helper module) purely to have something to cover would be padding invented to satisfy a metric,
not real functionality this story's ACs or REQ-F-01 call for — explicitly against the spirit of the
coverage gate and against `common/eval-framework.md`'s "recommended presets, never engineered to pass."

**Chosen approach instead**: `tests/unit/conduit-next/scaffold.test.js` spawns the REAL
`next dev --turbopack -p 3002` process (the literal command AC-2 names) as a child process and asserts
against its real, observable behaviour over real HTTP — proving AC-1 (App Router serves real content)
and AC-2 (starts without error, listens on 3002, responds 200) more strongly than an in-process
component render would, at the cost of the V8 coverage instrumentator not seeing code that executed in
a separate child process. This is the same reasoning `common/behavior-spec.md` uses for its own B1/B2
Gherkin tiers on public-surface behaviour rather than internals.

**Conclusion**: `unitTestCoverageMin` (90%) is recorded as **N/A for this story's diff**, with this
exact reason — not silently, not as a fabricated percentage, and not by weakening the threshold in
`tests/.evals/config.json` (which remains 90.0, unchanged, for every other/future story). The 0/0
coverage-report files are still attached per the gate's evidence requirement. This exception is
narrowly scoped to Story 1's own generated-scaffold files; the first story that adds real custom logic
to `conduit-next/` (Story 2 onward) is measured against the 90% threshold exactly as normal.

## Full Regression Gate (Step 6.5) — vs baseline-regression.log

**Baseline** (Step 1.5 Item 4.5, before any code generated): suite could not execute at all --
`MISSING DEPENDENCY jsdom`, `MISSING DEPENDENCY @vitest/coverage-v8`. 0 test files ran, 0 tests ran.

**Post-change** (this step, after Story 1's implementation): `npm test -- --coverage --passWithNoTests`
-> **4 test files passed (4), 15 tests passed (15)**, 0 failures. The pre-existing baseline gap
(jsdom/@vitest/coverage-v8 missing from package.json) was fixed as part of this story's own Unit Test
& Coverage step (Story 1's own new test genuinely needed jsdom to run) -- this is a net improvement,
not a regression: the 3 pre-existing test files (backend/helper/helpers.test.js,
frontend/src/helpers/dateFormatter.test.js, frontend/src/helpers/errorHandler.test.js) that could not
run AT ALL at baseline now run and pass, alongside this story's own new
tests/unit/conduit-next/scaffold.test.js (3 tests).

**Diff result**: **zero NEW failures.** There is nothing to regress against, since baseline had zero
passing tests to begin with (the whole suite was non-executable). Every test that can now run, does,
and passes. Full regression gate: CLEAN.
