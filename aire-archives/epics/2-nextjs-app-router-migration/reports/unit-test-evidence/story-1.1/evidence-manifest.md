# Unit Test & Coverage Evidence — Story 1.1

**Command**: `npx vitest run --config vitest.src.config.js --coverage`
**Result**: 16/16 tests passed (3 test files)
**Coverage on new code (`src/lib/**`)**: 94% statements, 93.87% lines — **above `unitTestCoverageMin` (90%)** ✅
**SH-LOOP-1**: exited successfully after 1 remediation attempt.

## Coverage breakdown

| File | % Stmts | % Lines |
|---|---|---|
| src/lib/db/config.js | 100 | 100 |
| src/lib/db/index.js | 94.11 | 94.11 |
| src/lib/db/models/User.js | (part of models 91.66) | |
| src/lib/db/models/Article.js | | |
| src/lib/db/models/Comment.js | 80 | 80 |
| src/lib/db/models/Tag.js | 75 | 75 |
| **All src/lib** | **94** | **93.87** |

Uncovered lines are unexercised `toJSON` redaction branches on Comment/Tag (lines 13, 17) and the
production-branch of the singleton (index.js:65) — non-critical; overall well above threshold.

## Test files
- `tests/unit/lib/db/models.test.js` — 7 tests: all 4 models defined, associations present (AC-2), toJSON redaction, eager-load smoke (AC-5)
- `tests/unit/lib/db/config.test.js` — 6 tests: DATABASE_URL precedence, discrete DB_*, legacy DEV_DB_*, no hardcoded creds (AC-4), parseLogging
- `tests/unit/lib/db/singleton.test.js` — 3 tests: same-instance across imports (AC-3), authenticate()+models exported, ARCH-05 no-unsafe-sync static guard

## SH-LOOP-1 attempt log
- **Attempt 1** — root causes: (a) ARCH-05 static-guard regex matched the literal `sync({ alter: true })` string inside index.js's own docstring comment → reworded the comment to "no auto-alter/force-sync" without the forbidden token sequence (guard still scans real code); (b) `resolveDbConfig` read `NODE_ENV` at module-load time via a top-level `const`, so the legacy-prefix test (which sets DEV_DB_* but runs under NODE_ENV=test) resolved TEST_DB_* → moved `env` resolution inside `resolveDbConfig()` so it is dynamic per call (genuine bug fix); (c) the legacy test also needed to set NODE_ENV=development to exercise the DEV_DB path → fixed the test. Re-verify: `npx vitest run --config vitest.src.config.js --coverage` → 16/16 pass, 94% coverage.

## Artifacts
- `unit-test-run.log` — raw runner output
- `coverage-report.lcov`, `coverage-report.json` — machine-readable coverage
- `coverage/src/lcov-report/` — HTML report
