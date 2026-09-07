import react from "@vitejs/plugin-react-swc";
import { defineConfig } from "vite";

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: "jsdom",
    setupFiles: "frontend/src/setupTests.js",
    css: true,
    coverage: {
      provider: "v8",
      reporter: ["text", "lcov", "json-summary"],
    },
  },
});
