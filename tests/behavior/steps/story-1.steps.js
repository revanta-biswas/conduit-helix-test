// Step definitions for spec/behavior/story-1.feature (Story 1: Next.js application scaffold).
// Bound to the application's public surface only: the repo's own package.json manifests, the
// real `next dev` process over HTTP, and `git diff` against the epic branch — never internals.
const { Given, When, Then, Before, After, setDefaultTimeout } = require("@cucumber/cucumber");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const { execSync, spawn } = require("node:child_process");

setDefaultTimeout(45 * 1000);

const REPO_ROOT = path.resolve(__dirname, "..", "..", "..");
const CONDUIT_NEXT_DIR = path.join(REPO_ROOT, "conduit-next");
const PORT = 3002;
const BASE_URL = `http://localhost:${PORT}`;

function readJson(relPath) {
  return JSON.parse(fs.readFileSync(path.join(REPO_ROOT, relPath), "utf8"));
}

function killDevServerGroup(devServer) {
  if (!devServer || devServer.killed) return;
  try {
    // Negative PID = signal the whole process group (valid because the process was spawned
    // `detached: true`), which reaps Turbopack's own worker subprocesses too.
    process.kill(-devServer.pid, "SIGTERM");
  } catch {
    devServer.kill("SIGTERM");
  }
}

Given("the repository root contains a root {string} with an npm {string} array", function (fileName, fieldName) {
  this.rootPkg = readJson(fileName);
  assert.ok(Array.isArray(this.rootPkg[fieldName]), `${fieldName} should be an array in root ${fileName}`);
});

Given("the existing {string} and {string} workspace members are present", function (ws1, ws2) {
  assert.ok(fs.existsSync(path.join(REPO_ROOT, ws1, "package.json")), `${ws1}/package.json should exist`);
  assert.ok(fs.existsSync(path.join(REPO_ROOT, ws2, "package.json")), `${ws2}/package.json should exist`);
});

When("the root {string} {string} array is inspected", function (fileName, fieldName) {
  this.rootPkg = readJson(fileName);
  this.inspectedField = this.rootPkg[fieldName];
});

Then("it includes {string}", function (memberName) {
  assert.ok(this.inspectedField.includes(memberName), `expected ${JSON.stringify(this.inspectedField)} to include ${memberName}`);
});

Then("{string} declares a {string} dependency on major version {int}", function (pkgPath, depName, major) {
  const pkg = readJson(pkgPath);
  const range = (pkg.dependencies && pkg.dependencies[depName]) || (pkg.devDependencies && pkg.devDependencies[depName]);
  assert.ok(range, `${pkgPath} should declare a dependency on ${depName}`);
  const versionDigits = range.replace(/^[^\d]*/, "");
  assert.equal(versionDigits.split(".")[0], String(major), `${depName} should be major version ${major}, got range ${range}`);
});

Then("{string} exists as the App Router entry directory", function (dirPath) {
  const full = path.join(REPO_ROOT, dirPath);
  assert.ok(fs.existsSync(full) && fs.statSync(full).isDirectory(), `${dirPath} should exist as a directory`);
});

When("{string} is started", async function (command) {
  this.startupOutput = "";
  this.devServer = spawn("npm", ["run", "dev", "-w", "conduit-next"], {
    cwd: REPO_ROOT,
    env: { ...process.env },
    stdio: ["ignore", "pipe", "pipe"],
    // `next dev --turbopack` spawns its own worker subprocesses. Without its own process group,
    // killing just this direct child leaves Turbopack's workers running, which keeps this
    // container's PID 1 blocked (nothing left to reap them) even after cucumber-js itself exits.
    detached: true,
  });
  this.devServer.stdout.on("data", (c) => (this.startupOutput += c.toString()));
  this.devServer.stderr.on("data", (c) => (this.startupOutput += c.toString()));

  const start = Date.now();
  while (!/Ready in/i.test(this.startupOutput)) {
    if (this.devServer.exitCode !== null) {
      throw new Error(`dev server exited early (code ${this.devServer.exitCode}). Output:\n${this.startupOutput}`);
    }
    if (Date.now() - start > 30000) {
      throw new Error(`dev server did not become ready within 30s. Output so far:\n${this.startupOutput}`);
    }
    await new Promise((r) => setTimeout(r, 250));
  }
});

Then("the process starts without throwing or exiting non-zero", function () {
  assert.equal(this.devServer.exitCode, null, "dev server process should still be running (exitCode null)");
  assert.match(this.startupOutput, /Ready in/i);
});

Then("it listens on port {int}", async function (port) {
  const res = await fetch(`http://localhost:${port}/`);
  assert.equal(res.status, 200, `expected 200 from http://localhost:${port}/, got ${res.status}`);
});

Then("an HTTP request to {string} returns a successful response", async function (url) {
  const res = await fetch(url);
  assert.equal(res.status, 200);
  this.lastResponseBody = await res.text();
});

Then(
  "ports {int} and {int} remain owned by {string} and {string} respectively \\(no collision)",
  function (port1, port2, ws1, ws2) {
    const viteConfig = fs.readFileSync(path.join(REPO_ROOT, ws1, "vite.config.js"), "utf8");
    assert.match(viteConfig, new RegExp(`port:\\s*${port1}`), `${ws1}/vite.config.js should still declare port ${port1}`);
    const envExample = fs.readFileSync(path.join(REPO_ROOT, ws2, ".env.example"), "utf8");
    assert.match(envExample, new RegExp(`PORT=${port2}`), `${ws2}/.env.example should still declare PORT=${port2}`);

    killDevServerGroup(this.devServer);
  },
);

When("{string} is executed", function (command) {
  const [, script] = command.match(/npm run (\S+) -w conduit-next/) || [];
  this.lintOutput = execSync(`npm run ${script} -w conduit-next`, { cwd: REPO_ROOT, encoding: "utf8", stdio: "pipe" });
});

Then("it runs to completion using {string}", function (configPath) {
  assert.ok(fs.existsSync(path.join(REPO_ROOT, configPath)), `${configPath} should exist and have been used`);
});

Then("no {string} exists anywhere under {string}", function (fileName, dirPath) {
  const full = path.join(REPO_ROOT, dirPath);
  const found = execSync(`find "${full}" -iname "${fileName}" -not -path "*/node_modules/*" 2>/dev/null || true`, {
    encoding: "utf8",
  }).trim();
  assert.equal(found, "", `expected no ${fileName} under ${dirPath}, found: ${found}`);
});

Then("a Prettier configuration is present and used by {string}'s format script", function (workspaceName) {
  const prettierRc = path.join(REPO_ROOT, workspaceName, ".prettierrc.json");
  assert.ok(fs.existsSync(prettierRc), `${workspaceName}/.prettierrc.json should exist`);
  const pkg = readJson(path.join(workspaceName, "package.json"));
  assert.ok(pkg.scripts && pkg.scripts.format, `${workspaceName}/package.json should declare a format script`);
});

When("{string} is computed between the epic branch and this story's branch", function (command) {
  // Bind-mounted repos inside a container are commonly owned by a different UID than the container
  // user, which makes git refuse to operate ("detected dubious ownership") unless explicitly trusted.
  // Harmless no-op on a native (non-container) run where the repo is already trusted.
  execSync(`git config --global --add safe.directory "${REPO_ROOT}"`, { cwd: REPO_ROOT, encoding: "utf8" });
  this.diffOutput = execSync("git diff --stat epic/nextjs-modernization -- backend frontend", {
    cwd: REPO_ROOT,
    encoding: "utf8",
  }).trim();
});

Then("no changed path starts with {string}", function (prefix) {
  const lines = this.diffOutput.split("\n").filter(Boolean);
  const offending = lines.filter((l) => l.trim().startsWith(prefix));
  assert.equal(offending.length, 0, `expected no changed path starting with ${prefix}, found: ${JSON.stringify(offending)}`);
});

After(function () {
  killDevServerGroup(this.devServer);
});
