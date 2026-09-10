# MoonLayout Audit

MoonLayout Audit 是一个 MoonBit 原生的图布局质量审计与回归验证库。
它不重新实现图自动布局算法，而是接收 Moon ELK、Graphviz、d3-force 或自定义
布局程序生成的坐标快照，检查节点和连线是否满足可读性与构建质量要求。

项目的核心价值是：纯计算、无网络、确定性、可解释、适合 CI。相同的快照和审计
阈值会产生相同的报告、指纹和 SVG 标注结果。

## 为什么需要它

自动布局引擎解决“如何摆放节点”，但工程团队还需要知道结果是否合格：节点是否
重叠、边是否交叉、节点是否越界、一次升级是否让文档图形发生意外漂移。MoonLayout
Audit 将这些检查独立出来，作为布局引擎和文档构建之间的质量门禁。

它与 MoonBit 社区中的图布局项目形成互补关系，而不是替代某个布局算法：布局由
其他工具完成，MoonLayout Audit 负责验证和记录结果。

## 快速开始

要求 MoonBit 工具链和 Node.js（JS 目标只用于 CLI 文件读写）。

```bash
moon fmt
moon check --deny-warn
moon test --deny-warn
moon build --target js src/cmd/moonlayout
moon run src/cmd/moonlayout -- \
  --input examples/pipeline.snapshot \
  --report audit-report.json \
  --svg audit.svg
```

审计通过时 CLI 返回退出码 `0`，发现质量问题时返回 `1`，输入或参数错误时返回
`2`。`audit-report.json` 是机器可读报告，`audit.svg` 会把问题节点和问题边标成红色。
仓库中的示例产物见 [`examples/pipeline-audit.svg`](examples/pipeline-audit.svg) 和
[`examples/pipeline-report.json`](examples/pipeline-report.json)。

## 快照格式

快照是一个简单、可审阅、可放入 Git 的文本文件：

```text
canvas 900 600
node Client 120 260 44 44
node API 360 260 44 44
node DB 600 180 44 44
node Queue 600 340 44 44
edge Client API
edge API DB
edge API Queue
```

每行分别表示画布、节点或有向边。节点坐标是中心点，后两个数字是节点宽度和高度。
解析器会报告行号、重复节点、非法数字和不存在的边端点；空行和 `#` 注释可以忽略。

## CLI 选项

```text
--input <file>            .snapshot 输入（缺省使用内置示例）
--report <file>           JSON 审计报告
--svg <file>              带问题标注的 SVG
--max-overlaps <n>        允许的重叠节点对，默认 0
--max-crossings <n>       允许的边交叉数，默认 0
--max-out-of-bounds <n>   允许的越界节点数，默认 0
--min-edge-length <n>     最小曼哈顿边长，默认不限制
--max-edge-length <n>     最大曼哈顿边长，默认不限制
```

## MoonBit API

```moonbit
let snapshot = @core.make_snapshot(
  900,
  600,
  [
    { id: "Client", x: 120, y: 260, width: 44, height: 44 },
    { id: "API", x: 360, y: 260, width: 44, height: 44 },
  ],
  [{ source: "Client", target: "API" }],
)
let report = @core.audit_snapshot(snapshot, @core.default_audit_config())
let json = @core.report_to_json(report)
let svg = @core.render_audit_svg(snapshot, report)
```

审计指标包括：

- 节点越界数量；
- 节点重叠对数量；
- 重复坐标数量；
- 非共享端点的边交叉数量；
- 最小、最大和平均边长；
- 稳定布局指纹；
- 逐条机器可读的违规记录。

## 预期使用场景

1. **架构图 CI**：布局引擎先生成服务架构坐标，MoonLayout Audit 在 Pull Request 中
   阻止重叠节点或交叉边进入文档。
2. **文档回归**：提交上一次的快照指纹，升级布局引擎后重新审计，发现坐标漂移或
   质量指标恶化时给出明确报告。
3. **多引擎统一验证**：Moon ELK、Graphviz、d3-force 和自定义布局器输出同一种快照，
   使用同一套阈值进行比较。
4. **教学与报告发布**：生成 SVG 前检查标签、边线和画布边界，避免发布不可读图形。

## 项目边界与差异化

MoonLayout Audit 不实现 Layered、Force、Radial 或其他通用自动布局算法，也不复制
Eclipse ELK、Graphviz 或 d3-force 的源代码。社区中的
[moon_elk](https://github.com/wangjiale6036-dotcom/moon_elk) 等布局项目负责生成坐标，
本项目专注于布局快照审计、确定性回归和 CI 质量门禁。

项目代码为原创 MoonBit 实现，采用 MIT License。

## 验收命令

```bash
moon fmt
moon check --deny-warn
moon test --deny-warn
moon info
moon build --target js src/cmd/moonlayout
node --test tests/cli.integration.test.mjs
moon run src/cmd/moonlayout -- --input examples/pipeline.snapshot --report audit-report.json --svg audit.svg
```

## License

MIT
