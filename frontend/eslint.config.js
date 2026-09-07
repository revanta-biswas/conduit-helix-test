// Minimal recommended-preset ESLint config for frontend/ (React 19, ES Modules, plain JavaScript).
// Bootstrapped by AIRE per common/eval-framework.md Section 2.3 — recommended preset, never strict/all.
import js from "@eslint/js";
import react from "eslint-plugin-react";
import reactHooks from "eslint-plugin-react-hooks";

export default [
  js.configs.recommended,
  {
    plugins: { react, "react-hooks": reactHooks },
    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "module",
      parserOptions: { ecmaFeatures: { jsx: true } },
      globals: {
        window: "readonly",
        document: "readonly",
        console: "readonly",
        fetch: "readonly",
        localStorage: "readonly",
        sessionStorage: "readonly",
        navigator: "readonly",
        Response: "readonly",
        // Vitest globals (vitest.config.js at repo root sets test.globals: true) — matches the
        // runner's own configuration rather than importing describe/it/expect in every test file.
        describe: "readonly",
        it: "readonly",
        test: "readonly",
        expect: "readonly",
        vi: "readonly",
        beforeEach: "readonly",
        afterEach: "readonly",
        beforeAll: "readonly",
        afterAll: "readonly",
      },
    },
    rules: {
      ...react.configs.recommended.rules,
      ...reactHooks.configs.recommended.rules,
      "react/react-in-jsx-scope": "off",
      complexity: ["warn", 12],
    },
    settings: { react: { version: "detect" } },
  },
];
