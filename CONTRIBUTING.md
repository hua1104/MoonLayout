# Contributing to MoonLayout

Keep changes focused on the reusable MoonBit library. New behavior should have
unit coverage in `src/*_test.mbt`; CLI behavior belongs in
`tests/cli.integration.test.mjs`.

Run the complete local check before opening a pull request:

```bash
moon fmt --check
moon check --deny-warn
moon test --deny-warn
moon info
moon build --target js src/cmd/moonlayout
node --test tests/cli.integration.test.mjs
```

Please preserve deterministic output: do not introduce wall-clock state,
unseeded randomness, network calls, or generated files outside the documented
demo output.
