# MoonLayout 验收清单

在项目根目录执行：

```bash
moon version
moon fmt --check
moon check --deny-warn
moon test --deny-warn
moon info
moon build --target js src/cmd/moonlayout
moon run src/cmd/moonlayout -- --edges A-B,B-C,C-A --out demo.svg
node --test tests/cli.integration.test.mjs
```

预期结果：7 个 MoonBit 测试和 2 个 Node 集成测试通过，CLI 输出 3 个节点和 3 条边，`demo.svg` 是非空
自包含 SVG。删除输出后重复执行，布局坐标和文件内容保持一致。
