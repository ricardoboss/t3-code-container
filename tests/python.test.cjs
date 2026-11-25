const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { spawnSync } = require("node:child_process");
const { test } = require("node:test");

test("uv can install default Python executables in a user directory offline", (t) => {
  const home = fs.mkdtempSync(path.join(os.tmpdir(), "python-user-"));
  t.after(() => fs.rmSync(home, { recursive: true, force: true }));
  const bin = path.join(home, ".local/bin");
  const version = fs.readFileSync("/opt/toolchain/versions.env", "utf8")
    .match(/^PYTHON_VERSION=(.+)$/m)[1].trim();
  const env = {
    ...process.env,
    HOME: home,
    UV_PYTHON_BIN_DIR: bin,
    PATH: `${bin}:${process.env.PATH}`,
  };
  // Reuse the provisioned distribution so this verifies uv's executable selection
  // without a download. Online verification also installs a different Python version.
  const install = spawnSync("uv", ["python", "install", "--offline", "--default",
    "--install-dir", "/opt/tools/current/python", version], { env, encoding: "utf8" });
  assert.equal(install.status, 0, install.stderr);
  for (const executable of ["python", "python3"]) {
    assert.ok(fs.lstatSync(path.join(bin, executable)).isSymbolicLink());
    const run = spawnSync(executable, ["-c", "import sys; print(sys.executable)"], {
      env, encoding: "utf8",
    });
    assert.equal(run.status, 0, run.stderr);
    assert.equal(run.stdout.trim(), path.join(bin, executable));
  }
  const python = spawnSync("python3", ["--version"], { encoding: "utf8" });
  assert.equal(python.status, 0, python.stderr);
  assert.equal(python.stdout.trim(), `Python ${version}`);
});
