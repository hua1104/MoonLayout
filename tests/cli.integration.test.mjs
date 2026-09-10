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

test("CLI audits a valid deterministic snapshot", async () => {
  const report = path.join(repoRoot, "cli-report.json");
  const svg = path.join(repoRoot, "cli-audit.svg");
  runCli([
    "--input",
    path.join(repoRoot, "examples", "pipeline.snapshot"),
    "--report",
    report,
    "--svg",
    svg,
  ]);
  assert.equal(existsSync(report), true);
  assert.equal(existsSync(svg), true);
  const json = await readFile(report, "utf8");
  const parsed = JSON.parse(json);
  assert.equal(parsed.passed, true);
  assert.equal(parsed.overlap_pairs, 0);
  assert.equal(parsed.edge_crossings, 0);
  const image = await readFile(svg, "utf8");
  assert.match(image, /marker-end/);
  assert.match(image, /<title>/);
  assert.match(image, /status=PASS/);
});

test("CLI returns a quality failure for an overlapping snapshot", () => {
  const result = runCli(
    [
      "--input",
      path.join(repoRoot, "examples", "overlap.snapshot"),
      "--report",
      path.join(repoRoot, "overlap-report.json"),
      "--svg",
      path.join(repoRoot, "overlap-audit.svg"),
    ],
    1,
  );
  assert.match(result.stdout, /status: FAIL/);
  assert.match(result.stdout, /overlaps: 1/);
});

test("CLI rejects malformed snapshots and option values", () => {
  runCli(
    [
      "--input",
      path.join(repoRoot, "examples", "missing.snapshot"),
      "--report",
      path.join(repoRoot, "invalid-report.json"),
    ],
    2,
  );
  runCli(["--max-overlaps", "--svg"], 2);
});

test("CLI exposes a version", () => {
  const result = runCli(["--version"]);
  assert.match(result.stdout, /moonlayout-audit 0\.2\.0/);
});
