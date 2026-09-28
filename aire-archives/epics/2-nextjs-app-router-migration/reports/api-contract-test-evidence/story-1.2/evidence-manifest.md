# API & Contract Test Evidence — Story 1.2

**Endpoints tested**: POST /api/users (register), POST /api/users/login
**Result**: 7/7 tests pass. SH-LOOP-2: passed first run.

## Per-endpoint checklist
| Check | register | login |
|---|---|---|
| Functional / happy path | ✅ 201 | ✅ 200 |
| Response-code validation | ✅ 201/422 | ✅ 200/422/404 |
| Role-based authz (401/403) | N/A — register/login are intentionally public endpoints (auth's requireSessionUser 401 is unit-tested separately) | N/A |
| Error-response contract `{errors:{body:[]}}` | ✅ | ✅ |
| Request validation (missing/invalid) | ✅ bad email, missing fields, dup email | ✅ wrong password, unknown email |
| Response contract/schema (`{user:{email,username,token}}`, no password, httpOnly cookie) | ✅ | ✅ |

Artifacts: api-contract-test-run.log, api-contract-test-report.json
