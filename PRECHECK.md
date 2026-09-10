# MoonLayout Audit 验收清单

在项目根目录执行：

```bash
moon version
node --version
moon fmt --check
moon check --deny-warn
moon test --deny-warn
moon info
moon build --target js src/cmd/moonlayout
node --test tests/cli.integration.test.mjs
moon run src/cmd/moonlayout -- --input examples/pipeline.snapshot --report audit-report.json --svg audit.svg
```

预期结果：

- 6 个 MoonBit 单元测试通过；
- 4 个 Node CLI 集成测试通过；
- 合格快照返回退出码 0，并输出 `status: PASS`；
- `audit-report.json` 中 `overlap_pairs`、`edge_crossings` 和 `out_of_bounds` 均为 0；
- `audit.svg` 包含箭头、`title`、`desc` 和审计摘要；
- `examples/overlap.snapshot` 返回退出码 1；
- 缺失文件或非法参数返回退出码 2。
