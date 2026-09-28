# Baseline Static Eval — Story 1.1 (pre-code, epic branch state)

Captured on branch `story/1.1-nextjs-foundation-db-layer` immediately after cutting from
`epic/nextjs-migration`, BEFORE any code was generated. Every finding here is **pre-existing debt** on
the epic branch (from the existing `backend/`/`frontend/` code) — recorded, then ignored forever. Only
findings NEW versus this baseline, on files Story 1.1 changes, count against the gate (Step 6.6).

| Check | Tool | Baseline result | Notes |
|---|---|---|---|
| D1 Lint | eslint 9.39.5 (recommended preset, bootstrapped) | 211 errors | All in existing frontend/ + backend/ (mostly no-undef for un-configured browser/node globals) |
| D2 Type check | — | N/A | Plain JavaScript, no TypeScript in the stack (confirmed decision — no type checker applies) |
| D3 SAST | semgrep 1.176.0 (--config auto) | 5 findings | In existing code; d3-semgrep.json |
| D4 SCA | npm audit | 21 vulns (3 critical, 11 high, 5 moderate, 2 low) | Existing backend/frontend deps; d4-npm-audit.json |
| D5 Licence | license-checker | captured | d5-licenses.json (production deps) |
| D6 Complexity | eslint complexity rule (cap 12) | included in D1 count | No separate over-threshold finding isolated at baseline |
| D7 Secrets | gitleaks 8.30.1 (default ruleset) | 2 leaks | In git history/existing files; d7-gitleaks.json |

**Tools installed/verified for the gate**: eslint@9.39.5 + @eslint/js@9 (bootstrapped, dev deps),
semgrep 1.176.0 (present on PATH), gitleaks 8.30.1 (present), podman (present), license-checker (npx).
**Configs bootstrapped this story**: `eslint.config.js` (recommended + complexity:12), `.gitleaks.toml`
(default ruleset). Both commit with the story.

**Bootstrap → baseline ordering honored**: all configs/tools were in place BEFORE this baseline run, so
the Step 6.6 post-change diff measures under identical rules.
