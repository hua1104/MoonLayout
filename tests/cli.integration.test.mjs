import assert from "node:assert/strict";
import { existsSync } from "node:fs";
import { readFile } from "node:fs/promises";
import { spawnSync } from "node:child_process";
import test from "node:test";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = fileURLToPath(new URL("../", import.meta.url));
const cliPath = path.join(
  repoRoot,
  "_build",
  "js",
  "debug",
  "build",
  "cmd",
  "moonlayout",
  "moonlayout.js",
);

function runCli(args, status = 0) {
  const result = spawnSync(process.execPath, [cliPath, ...args], {
    cwd: repoRoot,
    encoding: "utf8",
  });
  assert.equal(result.status, status, result.stderr || result.stdout);
  return result;
}

test("CLI renders a valid deterministic SVG", async () => {
  const output = path.join(repoRoot, "cli-test.svg");
  runCli(["--edges", "Client-API,API-DB,API-Queue", "--out", output]);
  assert.equal(existsSync(output), true);
  const svg = await readFile(output, "utf8");
  assert.match(svg, /^<svg [^>]+role="img">/);
  assert.match(svg, /<line /);
  assert.match(svg, /<circle /);
  assert.match(svg, /<text /);
  assert.match(svg, /Client/);
});

test("CLI rejects unsafe canvas and iteration values", () => {
  runCli(["--width", "20"], 2);
  runCli(["--iterations", "5001"], 2);
});
