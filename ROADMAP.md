# MoonLayout Roadmap

## Delivered

- Deterministic integer force-directed layout for small and medium graphs.
- Stable grid initialization, bounds normalization, and invalid-edge guards.
- Self-contained SVG output with escaped node labels.
- MoonBit library API, CLI demo, unit tests, Node integration tests, and CI.

## Next

- Optional directional arrows and edge labels in SVG.
- Connected-component packing for large disconnected graphs.
- WASM host example for embedding the layout engine in a browser.
- Incremental layout updates when one node or edge changes.

The roadmap deliberately keeps the core dependency-free and deterministic.
