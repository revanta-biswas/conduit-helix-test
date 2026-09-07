// Smoke test for Story 1 (Next.js application scaffold, REQ-F-01, AC-1/AC-2/AC-3).
//
// A pure scaffold introduces no custom business logic to unit-test in isolation, and
// conduit-next's App Router pages are plain-JavaScript ".js" files containing JSX — a
// combination Next.js's own SWC/Turbopack pipeline accepts but Vite/esbuild (this repo's
// existing Vitest transform, shared with frontend/) does not parse without renaming files
// away from Next's required "page.js"/"layout.js" conventions, which would break the App
// Router. Rather than fight the bundler or rename framework-mandated filenames, this test
// exercises the story's actual, concrete deliverable end-to-end: it starts the real
// `next dev` server (the same command AC-2 names) as a child process and asserts on its
// real, observable behaviour — starts without error, listens on port 3002, and serves the
// scaffolded home page — which is a stronger and more honest proof of AC-2 than a mocked
// component render would be.
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { spawn } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const CONDUIT_NEXT_DIR = path.resolve(__dirname, "../../../conduit-next");
const PORT = 3002;
const BASE_URL = `http://localhost:${PORT}`;

let devServer;
let startupOutput = "";

function waitForServerReady(timeoutMs = 30000) {
  return new Promise((resolve, reject) => {
    const start = Date.now();
    const check = () => {
      if (/Ready in/i.test(startupOutput)) return resolve();
      if (Date.now() - start > timeoutMs) {
        return reject(new Error(`next dev did not become ready within ${timeoutMs}ms. Output so far:\n${startupOutput}`));
      }
      setTimeout(check, 250);
    };
    check();
  });
}

describe("conduit-next scaffold — real `next dev` server", () => {
  beforeAll(async () => {
    devServer = spawn("npx", ["next", "dev", "--turbopack", "-p", String(PORT)], {
      cwd: CONDUIT_NEXT_DIR,
      env: { ...process.env },
      stdio: ["ignore", "pipe", "pipe"],
      detached: true,
    });
    devServer.stdout.on("data", (chunk) => {
      startupOutput += chunk.toString();
    });
    devServer.stderr.on("data", (chunk) => {
      startupOutput += chunk.toString();
    });
    await waitForServerReady();
  }, 40000);

  afterAll(() => {
    if (devServer && !devServer.killed) {
      try {
        process.kill(-devServer.pid, "SIGTERM");
      } catch {
        devServer.kill("SIGTERM");
      }
    }
  });

  it("starts without throwing or exiting non-zero (AC-2)", () => {
    expect(devServer.exitCode).toBeNull();
    expect(startupOutput).toMatch(/Ready in/i);
  });

  it("listens on port 3002 and serves a successful response (AC-2)", async () => {
    const res = await fetch(BASE_URL + "/");
    expect(res.status).toBe(200);
    const body = await res.text();
    expect(body).toMatch(/Get started by editing/i);
  });

  it("serves the App Router home page content (AC-1)", async () => {
    const res = await fetch(BASE_URL + "/");
    const body = await res.text();
    expect(body).toMatch(/next\.svg/);
  });
});
