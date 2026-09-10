# MoonLayout Audit Roadmap

## Delivered

- Deterministic `.snapshot` parser with line-numbered errors.
- Node overlap, duplicate position, bounds and edge-crossing checks.
- Edge-length statistics and stable snapshot fingerprints.
- Machine-readable JSON report and CI-friendly exit codes.
- Annotated SVG with arrows, accessibility metadata and problem highlighting.
- MoonBit unit tests, Node CLI integration tests and a clean CI example.

## Next

- Optional JSON/ELK snapshot importer.
- Baseline diff report showing moved, added and removed nodes.
- More geometry checks such as label bounds and edge-through-node detection.
- Benchmark fixtures for 100, 1,000 and 10,000 node snapshots.
- Adapters for Moon ELK, Graphviz and common documentation generators.
