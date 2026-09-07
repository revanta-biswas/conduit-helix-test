// Minimal recommended-preset ESLint config for backend/ (Node.js, CommonJS — this workspace's
// existing code uses require()/module.exports throughout, verified against backend/index.js;
// the repo's "JavaScript (ES Modules)" description refers to the language level, not the module
// system actually in use here). Bootstrapped by AIRE per common/eval-framework.md Section 2.3 —
// recommended preset, never strict/all.
import js from "@eslint/js";

export default [
  js.configs.recommended,
  {
    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "commonjs",
      globals: {
        process: "readonly",
        console: "readonly",
        Buffer: "readonly",
        __dirname: "readonly",
        __filename: "readonly",
        require: "readonly",
        module: "writable",
        exports: "writable",
      },
    },
    rules: {
      complexity: ["warn", 12],
    },
  },
];
