# Static Eval Gate (D1–D7) — Story 1.1, post-change diff vs baseline

**Ordering honored**: bootstrap → baseline → code → post-change → diff.
**Scope**: findings NEW vs baseline, on files this story changed (src/, tests/, config).

| Check | Baseline | Post-change (my files) | New findings | Status |
|---|---|---|---|---|
| D1 Lint | 65 (existing tree, updated config) | 0 | 0 | PASS |
| D2 Types | — | — | — | N/A (plain JS) |
| D3 SAST | 5 (existing) | 0 (src/+tests/) | 0 | PASS |
| D4 SCA | 21 vulns | 20 vulns | 0 new (decreased) | PASS |
| D5 License | captured | 0 disallowed | 0 | PASS |
| D6 Complexity | (in D1) | 0 | 0 | PASS |
| D7 Secrets | 2 (framework templates) | 0 on my files | 0 | PASS |

**SH-LOOP-4 attempt log**
- **Attempt 1** — root causes: (a) my bootstrapped eslint.config.js declared no runtime globals, so legitimate `process`/`console`/`URL`/`globalThis` usage produced 50 no-undef false positives → added `globals.node`+`globals.browser` (and re-captured the baseline under the same config so the diff stays fair); (b) JSX in src/app/{layout,page}.js failed to parse → added `parserOptions.ecmaFeatures.jsx`; (c) 2 genuinely unused imports (`vi` in config.test.js, `parseLogging` in the step file) → removed; (d) `resolveDbConfig` genuinely exceeded the complexity cap (13 > 12) → extracted a `pickEnv()` helper, dropping it under the cap. Re-verify: `npx eslint src/ tests/` → 0 errors; unit tests still 16/16. Loop exited successfully.

🔴 No finding was suppressed to pass — every fix addressed the real cause (declare globals / add JSX parser / remove dead imports / reduce real complexity).
