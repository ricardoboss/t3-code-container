const assert = require("node:assert/strict");
const { spawn } = require("node:child_process");
const { test } = require("node:test");

test("32 concurrent Node and Python processes finish under the container limits", async () => {
  const programs = [
    ["node", ["-e", "const c=require('node:crypto'); const b=Buffer.alloc(1024*1024); for(let i=0;i<64;i++) c.createHash('sha256').update(b).digest();"]],
    ["python3", ["-c", "import hashlib; b=bytes(1024*1024); [hashlib.sha256(b).digest() for _ in range(64)]"]],
  ];
  await Promise.all(Array.from({ length: 32 }, (_, index) => new Promise((resolve, reject) => {
    const [command, args] = programs[index % programs.length];
    const child = spawn(command, args, { stdio: ["ignore", "ignore", "pipe"], timeout: 30000 });
    let error = "";
    child.stderr.on("data", (data) => { error += data; });
    child.on("error", reject);
    child.on("close", (code) => {
      try {
        assert.equal(code, 0, `${command}: ${error}`);
        resolve();
      } catch (failure) { reject(failure); }
    });
  })));
});
