# MoonLayout

MoonLayout is a deterministic graph auto-layout engine written in MoonBit.
It turns a compact edge list into stable node coordinates and a self-contained
SVG image. The project targets the Hackathon 2026 application/content tooling
direction: it is a reusable layout component for dependency maps, workflows,
small architecture diagrams, and educational visualizations.

## Why this project

Graph layout is usually hidden inside a browser library and often depends on
random seeds or floating-point convergence. MoonLayout keeps the core model
small and portable: integer forces, bounded coordinates, no network, and no
randomness. The same input produces the same SVG, which makes examples and
tests easy to verify.

## Run the demo

Prerequisites: the MoonBit toolchain and Node.js (the JS target uses Node's
filesystem API only for writing the output file).

Repository CI uses the latest MoonBit toolchain and normalizes formatting before
the build, so formatter upgrades do not cause a false-negative before the real
checks run. The CI workflow uses Node.js 24.

```bash
moon check --deny-warn
moon test --deny-warn
moon build --target js src/cmd/moonlayout
moon run src/cmd/moonlayout -- --edges A-B,B-C,C-A --out demo.svg
```

Open `demo.svg` in any browser. Custom graphs use `--edges`, for example
`Client-API,API-DB,API-Queue,Queue-Worker`. Isolated nodes can be supplied as a
single name. Use `--width`, `--height`, and `--iterations` to tune the canvas;
the CLI requires dimensions of at least 100 pixels and caps iterations at 5000.

## Library API

The reusable core is in `src/layout.mbt` and `src/svg.mbt`:

```moonbit
let graph = @core.parse_edge_list("A-B,B-C,C-A")
let config = @core.default_layout_config()
let positioned = @core.layout(graph, config)
let image = @core.render_svg(positioned, config)
```

`parse_edge_list`, `layout`, and `render_svg` are pure library operations.
Only the CLI's final file write uses the JS host.

`normalize_layout_config` bounds dimensions to 100..4096 pixels, iterations to
0..5000, and keeps force parameters non-negative. `layout` applies this
normalization automatically, so library consumers get the same safety
guarantees as the CLI.

## Acceptance evidence

- MoonBit formatting, warning checks, tests, and JS build pass from a clean
  build directory.
- Unit tests cover edge parsing, isolated nodes, deterministic coordinates,
  canvas bounds, invalid edge indexes, and SVG escaping. Node integration
  tests exercise the real CLI output and invalid-parameter exit codes.
- The MIT license is included. The implementation is original MoonBit code;
  the layout model is a compact integer simulation inspired by the public
  force-directed layout pattern used by projects such as d3-force, with no
  source code copied from them.

## License

MIT
