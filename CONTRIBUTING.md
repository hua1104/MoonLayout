# Contributing to MoonLayout Audit

Keep changes focused on deterministic snapshot auditing. The project does not aim to become
another general-purpose automatic layout engine.

New geometry behavior should have MoonBit unit coverage in `src/*_test.mbt`; CLI behavior
belongs in `tests/cli.integration.test.mjs`. Add a small fixture under `examples/` when a
new input or regression case is important.

Run the complete local check before opening a pull request:

```bash
moon fmt
moon check --deny-warn
moon test --deny-warn
moon info
moon build --target js src/cmd/moonlayout
node --test tests/cli.integration.test.mjs
moon run src/cmd/moonlayout -- --input examples/pipeline.snapshot --report audit-report.json --svg audit.svg
```

Preserve deterministic output, stable report fields, explicit parse errors and CI exit codes.
Do not introduce wall-clock state, unseeded randomness, network calls or generated files outside
the documented report and SVG outputs.
