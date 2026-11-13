// Run inside the built image: node --test /tests/t3-entrypoint.test.cjs
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { spawn, spawnSync } = require("node:child_process");
const { test } = require("node:test");

test("seeds an existing home without changing user data, then follows the updated service runtime", (t) => {
  const home = fs.mkdtempSync(path.join(os.tmpdir(), "t3-entrypoint-"));
  t.after(() => fs.rmSync(home, { recursive: true, force: true }));
  fs.writeFileSync(path.join(home, "user-data"), "keep me");
  const run = (...args) => {
    const result = spawnSync("/usr/local/bin/t3", args, {
      env: { ...process.env, T3CODE_HOME: home },
      encoding: "utf8",
      timeout: 30000,
    });
    assert.equal(result.status, 0, result.stderr);
    return result.stdout.trim();
  };

  const initial = fs.readFileSync("/opt/t3/version", "utf8").trim();
  assert.ok(run("--version").endsWith(`v${initial}`));
  assert.equal(fs.readFileSync(path.join(home, "user-data"), "utf8"), "keep me");
  const statePath = path.join(home, "runtime/service-state.json");
  assert.deepEqual(JSON.parse(fs.readFileSync(statePath)), { protocol: 3, activeVersion: initial });
  assert.deepEqual(fs.readdirSync(path.join(home, "runtime/versions")), [initial]);
  const browserVersion = fs.readFileSync("/opt/t3-browser/version", "utf8").trim();
  const browser = path.join(home, "tools/chrome-headless-shell/linux64", browserVersion, "chrome-headless-shell");
  assert.ok(fs.statSync(browser).mode & 0o111);

  const updated = "99.0.0";
  const versionDir = path.join(home, "runtime/versions", updated);
  fs.mkdirSync(versionDir);
  fs.writeFileSync(path.join(versionDir, ".install-complete"), updated);
  fs.writeFileSync(
    path.join(versionDir, "t3"),
    "#!/usr/bin/env node\nconsole.log(JSON.stringify(process.argv.slice(2)));\n",
    { mode: 0o755 },
  );
  const state = JSON.stringify({ protocol: 3, activeVersion: updated });
  fs.writeFileSync(statePath, state);
  assert.deepEqual(JSON.parse(run()), ["__service-launcher"]);
  assert.deepEqual(JSON.parse(run("connect", "status")), ["connect", "status"]);
  assert.equal(fs.readFileSync(statePath, "utf8"), state);
});

test("concurrent first use leaves one complete runtime and browser", async (t) => {
  const home = fs.mkdtempSync(path.join(os.tmpdir(), "t3-concurrent-"));
  t.after(() => fs.rmSync(home, { recursive: true, force: true }));
  const versions = await Promise.all(Array.from({ length: 8 }, () => new Promise((resolve, reject) => {
    const child = spawn("/usr/local/bin/t3", ["--version"], {
      env: { ...process.env, T3CODE_HOME: home },
      timeout: 30000,
    });
    let output = "";
    let error = "";
    child.stdout.on("data", (data) => { output += data; });
    child.stderr.on("data", (data) => { error += data; });
    child.on("error", reject);
    child.on("close", (code) => code === 0 ? resolve(output.trim()) : reject(new Error(error)));
  })));
  assert.equal(new Set(versions).size, 1);
  const initial = fs.readFileSync("/opt/t3/version", "utf8").trim();
  assert.deepEqual(fs.readdirSync(path.join(home, "runtime/versions")), [initial]);
  assert.equal(JSON.parse(fs.readFileSync(path.join(home, "runtime/service-state.json"))).activeVersion, initial);
});
