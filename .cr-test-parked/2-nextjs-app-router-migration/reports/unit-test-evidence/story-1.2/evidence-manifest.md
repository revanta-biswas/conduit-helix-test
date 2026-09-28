# Unit Test & Coverage Evidence — Story 1.2

**Command**: `npx vitest run --config vitest.src.config.js --coverage`
**Result**: 42/42 tests passed (6 test files: errors, auth, users service, helpers + inherited 1.1 db tests)
**Coverage on src/lib**: 95.41% statements, 96.55% lines — **above unitTestCoverageMin (90%)** ✅
**SH-LOOP-1**: passed on the first run (attempt 0), no remediation needed.

## New test files this story
- `tests/unit/lib/errors.test.js` — hierarchy, statusFor (401/403/404/422/500), toErrorResponse
- `tests/unit/lib/auth.test.js` — sign/verify JWT, hash/compare bcrypt, cookie httpOnly, readCookie, getSessionUser soft-auth, requireSessionUser throw
- `tests/unit/lib/services/users.test.js` — register (tightened validation: username len/format, email format, password min, dup email, dup username), login (success, wrong password, unknown email)
- `tests/unit/lib/helpers.test.js` — slugify

## Artifacts
- `unit-test-run.log`, `coverage-report.lcov`, `coverage-report.json`
