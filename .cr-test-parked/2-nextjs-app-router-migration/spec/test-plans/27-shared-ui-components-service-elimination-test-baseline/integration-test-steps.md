# Integration Test Steps — #27 Shared UI Components, Service Layer Elimination & Test Baseline

**Purpose**: Verify the boundaries this story asserts — (a) ported UI components consume real data
that flows from the datastore through Next.js Server Components / Server Actions to the rendered page
(the *no-Axios* data path, observed end to end), and (b) the code-structural acceptance criteria
(no Axios / no React-Router in `src/`, the Vitest+RTL test baseline exists and passes, no TypeScript,
no Prisma, `backend/`+`frontend/` retained). The structural criteria are checked as
**repository-inspection** steps: documented `grep` / `find` / test-run commands a tester executes from
outside the running system, asserting on their **observable output only** — never by reading and
comprehending application logic.

**Scope**: Component-to-datastore data flow via `fetch`/Server Actions (AC-1, AC-2), and the
repository-inspection verification of AC-2, AC-3, AC-4, AC-5.

## System Under Test
| Item | Value |
|------|-------|
| Branch | `epic/nextjs-migration` |
| This story's merged PR | [PR #36](https://github.com/revanta-biswas/conduit-helix-test/pull/36) (plus runtime-fix follow-up [PR #37](https://github.com/revanta-biswas/conduit-helix-test/pull/37)) |
| Confirm the story is in the build | `git log --oneline \| grep -iE "1\.9\|#27\|#36\|#37\|shared.*component\|service.*elimination"` |
| How to build & run it | **Follow the project's own build docs** (README / CONTRIBUTING / Makefile). This plan does not restate them. |
| Local base URL / port | `http://localhost:3000` |
| Local services that must be up | PostgreSQL (via Sequelize) — reachable with the connection settings the project's build docs specify |
| Repository checkout | A local clone of the repo at the merged `epic/nextjs-migration` branch. All repository-inspection commands are run from the repository root; they inspect files only and do NOT require reading or understanding application logic. |
| Test data / accounts to seed | Same as `e2e-test-steps.md`: user "Alice" with >= 12 articles, "Bob" following Alice, an article `<known-slug>` with comments. |

> If the build or local run fails, that is a **blocker on the dev team** — report it and do not log
> functional failures against a system that never started.

---

### TC-INT-01 — Ported components render live datastore data via the Next.js data path (happy)

| Field | Value |
|-------|-------|
| **Traces to** | AC-1, AC-2 / REQ-F-26, REQ-F-27 |
| **Type** | Integration |
| **Priority** | P1 (critical path) |
| **Preconditions** | SUT running; PostgreSQL up; seed data present; browser dev-tools open |
| **Test data** | Alice's seeded articles + tags; `<known-slug>` with comments |

**Steps**
1. Open `/` and confirm the ArticlesPreview list shows the seeded articles (titles/authors match the seed data), the PopularTags sidebar shows the seeded tags, and pagination reflects Alice's >= 12 articles.
2. Open `/article/<known-slug>` and confirm the CommentList shows exactly the seeded comments.
3. In a psql session (or the project's DB tooling), change one seeded article's title directly in the database.
4. Reload `/` and the article page.
5. Throughout steps 1–4 watch the browser Network tab.

**Expected result**
- The data rendered by the ported components matches the datastore contents (a change made directly in PostgreSQL appears after reload) — confirming components are wired to the real data path, not to mock/hard-coded data.
- All data requests observed in the browser are **same-origin** to `http://localhost:3000` (Next.js Server Component render or same-origin Server Action / Route Handler). No request goes to a separate host via a client Axios service.

**Pass/Fail criteria**: PASS if component data tracks the datastore and all traffic is same-origin Next.js. FAIL if data is stale/mocked or a cross-origin client Axios call is observed.
**Cleanup**: Restore the article title you changed in the DB.

---

### TC-INT-02 — Repository inspection: ZERO Axios usage in `src/` (structural, negative-is-fail)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-27, REQ-NF-05 |
| **Type** | Integration (repository inspection) |
| **Priority** | P1 (critical path) |
| **Preconditions** | Local checkout of `epic/nextjs-migration`; run from repo root; `grep` available |
| **Test data** | The `src/` tree |

**Steps**
1. From the repo root, search `src/` for any Axios import or usage:
   ```
   grep -rnE "from ['\"]axios['\"]|require\(['\"]axios['\"]\)|axios\." src/
   ```
2. Search `src/` for any file that looks like the old service layer (e.g. an `axios.create(` instance):
   ```
   grep -rnE "axios\.create\(" src/
   ```
3. Check that `axios` is not declared as a runtime dependency the new app relies on:
   ```
   grep -nE "\"axios\"" package.json
   ```
   (TO CONFIRM with dev: whether the root `package.json` is the one governing `src/`, or a separate manifest — record which manifest governs the `src/` Next.js app and inspect that one.)

**Expected result**
- Step 1 prints **no matches** (exit status non-zero / empty output).
- Step 2 prints **no matches**.
- Step 3 shows `axios` is absent from the manifest governing the `src/` app (or, if the legacy root manifest still lists it for `backend/`/`frontend/`, confirm `src/` code has zero import usage per steps 1–2 — the AC is about `src/` usage, and AC-5 keeps the legacy dirs).

**Pass/Fail criteria**: PASS if `src/` has **zero** Axios import/usage matches. **Any** Axios match inside `src/` is a FAIL.
**Cleanup**: None (read-only inspection).

---

### TC-INT-03 — Repository inspection: ZERO React-Router usage in `src/` (structural, negative-is-fail)

| Field | Value |
|-------|-------|
| **Traces to** | AC-2 / REQ-F-30, REQ-NF-05 |
| **Type** | Integration (repository inspection) |
| **Priority** | P1 |
| **Preconditions** | Local checkout; repo root; `grep` available |
| **Test data** | The `src/` tree |

**Steps**
1. Search `src/` for any react-router-dom import or its common APIs:
   ```
   grep -rnE "from ['\"]react-router-dom['\"]|require\(['\"]react-router-dom['\"]\)|useNavigate|useHistory|BrowserRouter|<Route\b|<Routes\b|<Switch\b" src/
   ```
2. Confirm navigation links in `src/` use the Next.js Link instead:
   ```
   grep -rnE "from ['\"]next/link['\"]" src/
   ```
3. Check `react-router-dom` is not a dependency the `src/` app relies on:
   ```
   grep -nE "\"react-router-dom\"" package.json
   ```

**Expected result**
- Step 1 prints **no matches** — no react-router-dom import and none of its routing APIs appear in `src/`.
- Step 2 prints **one or more** matches — the ported components/pages use `next/link`.
- Step 3 shows `react-router-dom` is absent from the manifest governing the `src/` app.

**Pass/Fail criteria**: PASS only if step 1 yields **zero** matches AND step 2 yields **>= 1** match. Any react-router-dom usage in `src/`, or zero `next/link` usage, is a FAIL.
**Cleanup**: None.

---

### TC-INT-04 — Repository inspection: no TypeScript files, no Prisma; Sequelize retained (structural)

| Field | Value |
|-------|-------|
| **Traces to** | AC-4 / REQ-NF-07 |
| **Type** | Integration (repository inspection) |
| **Priority** | P1 |
| **Preconditions** | Local checkout; repo root; `find` + `grep` available |
| **Test data** | The `src/` tree and the manifest governing it |

**Steps**
1. Find any TypeScript source files under `src/`:
   ```
   find src -type f \( -name "*.ts" -o -name "*.tsx" \) -not -name "*.d.ts"
   ```
2. Confirm there is no TypeScript config introduced for the app:
   ```
   ls -1 tsconfig.json 2>/dev/null; find . -maxdepth 2 -name "tsconfig.json" -not -path "*/node_modules/*"
   ```
   (TO CONFIRM with dev: whether an inherited `tsconfig.json` from `frontend/` is acceptable — the AC forbids *introducing* TS into the new `src/` app.)
3. Confirm Prisma is NOT a dependency and Sequelize IS:
   ```
   grep -nE "\"prisma\"|\"@prisma/client\"" package.json
   grep -nE "\"sequelize\"" package.json
   ```
4. Confirm no Prisma schema/artifacts were added:
   ```
   find . -maxdepth 3 -name "schema.prisma" -not -path "*/node_modules/*"
   ```

**Expected result**
- Step 1 prints **no files** — `src/` contains no `.ts`/`.tsx` files.
- Step 3: the `prisma`/`@prisma/client` grep prints **no match**; the `sequelize` grep prints **a match** (Sequelize retained).
- Step 4 prints **no `schema.prisma`** outside `node_modules`.

**Pass/Fail criteria**: PASS if there are zero TS files under `src/`, no Prisma dependency/schema, and Sequelize is present. Any `.ts`/`.tsx` in `src/`, any Prisma dependency, or a missing Sequelize dependency is a FAIL.
**Cleanup**: None.

---

### TC-INT-05 — Repository inspection: Vitest + RTL baseline exists under `tests/unit/` mirroring `src/` (structural)

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-F-40, REQ-NF-06 |
| **Type** | Integration (repository inspection) |
| **Priority** | P1 |
| **Preconditions** | Local checkout; repo root; `find` + `grep` available |
| **Test data** | The `tests/unit/` tree |

**Steps**
1. Confirm the baseline directory exists and contains test files:
   ```
   find tests/unit -type f -name "*.test.js*" -o -type f -name "*.spec.js*"
   ```
2. Confirm Vitest + React Testing Library are the declared tooling:
   ```
   grep -nE "\"vitest\"|@testing-library/react" package.json
   ```
3. Confirm the required coverage areas each have at least one test file present (by path/name — no source comprehension):
   - Model association tests for all 4 models:
     ```
     find tests/unit -type f \( -iname "*user*" -o -iname "*article*" -o -iname "*comment*" -o -iname "*tag*" \) -path "*model*"
     ```
     TO CONFIRM: the exact 4 model names (User, Article, Comment, Tag assumed) and their test-file naming — confirm with dev.
   - Route Handler tests for each API resource group (Stories 1.2-1.5 — auth/user, profiles, articles/feed/tags, favorites/comments):
     ```
     find tests/unit -type f -path "*api*"
     ```
   - Component tests for auth forms, article editor, and feed:
     ```
     find tests/unit -type f \( -iname "*login*" -o -iname "*register*" -o -iname "*editor*" -o -iname "*feed*" -o -iname "*auth*" \)
     ```

**Expected result**
- Step 1 lists one or more test files under `tests/unit/`.
- Step 2 shows both `vitest` and `@testing-library/react` declared.
- Step 3: each of the three coverage areas returns at least one matching test file (all 4 models represented; at least one Route-Handler test per resource group; at least one test each for auth forms, article editor, and feed).

**Pass/Fail criteria**: PASS if the baseline exists with Vitest+RTL and every named coverage area has >= 1 test file. A missing coverage area (e.g. a model with no association test, or no feed component test) is a FAIL.
**Cleanup**: None.

---

### TC-INT-06 — Run the test suite: Vitest baseline executes green and covers the named areas (structural)

| Field | Value |
|-------|-------|
| **Traces to** | AC-3 / REQ-F-40, REQ-NF-06 |
| **Type** | Integration (repository inspection / documented test-run) |
| **Priority** | P1 (critical path) |
| **Preconditions** | Local checkout with dependencies installed per the project's build docs; PostgreSQL available if model/route tests require it (TO CONFIRM whether the suite uses a test DB or mocks) |
| **Test data** | The committed test suite |

**Steps**
1. Run the project's documented unit-test command (TO CONFIRM the exact script name with dev — commonly `npm test` or `npx vitest run`). Run it in non-watch/CI mode so it terminates.
2. Observe the summary line (files passed/failed, tests passed/failed).
3. Optionally run with coverage if the project exposes it (TO CONFIRM the coverage script) and note the reported files.

**Expected result**
- The suite runs to completion and reports **all tests passing** (0 failed).
- The run's file list includes model, Route-Handler (api), and component (auth/editor/feed) tests — i.e. the baseline actually exercises the three areas AC-3 names, not an empty/placeholder suite.

**Pass/Fail criteria**: PASS if the suite completes with zero failing tests and the three coverage areas appear in the run. Any failing test, or a suite that runs zero tests / skips a whole named area, is a FAIL.
**Cleanup**: None.

---

### TC-INT-07 — Repository inspection: `backend/` and `frontend/` retained, no deployment/decommission (structural, negative-is-fail)

| Field | Value |
|-------|-------|
| **Traces to** | AC-5 / REQ-NF-07 |
| **Type** | Integration (repository inspection) |
| **Priority** | P2 (boundary — asserts a non-goal was respected) |
| **Preconditions** | Local checkout; repo root; `ls`/`find` available |
| **Test data** | The repository tree |

**Steps**
1. Confirm the legacy directories still exist:
   ```
   ls -d backend frontend
   ```
2. Confirm no production-deployment or DNS-cutover artifact was introduced by this story (spot check — TO CONFIRM the exact non-goal set with dev/BA):
   ```
   git log --oneline epic/nextjs-migration | grep -iE "deploy|dns|cutover|decommission|remove.*(backend|frontend)"
   ```
3. Confirm the app still runs from `src/` only (from TC-INT-01) without requiring `backend/`/`frontend/` to be running — i.e. the migration is self-contained but the legacy code is not deleted.

**Expected result**
- Step 1 lists both `backend` and `frontend` directories (they are NOT removed).
- Step 2 prints **no matches** — no commit in this story performs a deploy, DNS cutover, or directory decommission.

**Pass/Fail criteria**: PASS if both legacy directories still exist and no deploy/cutover/decommission commit is present. If `backend/` or `frontend/` is gone, or a deployment/decommission was performed in this cycle, that is a FAIL (the non-goal was violated).
**Cleanup**: None.
