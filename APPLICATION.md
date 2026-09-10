# MoonBit 黑客松项目申请书

## 1、项目名称

**MoonLayout Audit：MoonBit 图布局质量审计与回归验证库**

## 2、项目简介

MoonLayout Audit 是一个使用 MoonBit 编写的图布局质量审计库和 CLI 工具。它不负责
重新实现图自动布局算法，而是接收其他布局引擎或应用生成的节点坐标、节点尺寸和
有向边关系，检查布局结果是否适合发布到文档、网页或报告中。

项目会检测节点重叠、重复坐标、画布越界、边交叉和边长异常，输出确定性的文本报告、
JSON 报告以及带问题标注的 SVG。相同的布局快照和审计阈值会产生相同的质量指标和
指纹，因此可以直接接入 CI，防止布局升级或文档构建造成不可见的图形回归。

## 3、项目方向与通用性说明

### 项目方向

项目属于赛事“应用开发与内容处理”方向中的**可视化质量验证组件**。它面向静态图形
产物的验证和回归，而不是编程语言、编辑器、LSP 或通用命令行工具。

### 通用性说明

图布局质量问题与具体的布局算法无关。只要应用能够提供节点坐标、尺寸和边关系，
就可以使用 MoonLayout Audit 检查结果。它可以作为：

- Moon ELK、Graphviz 或自定义布局器之后的质量门禁；
- 架构图、依赖图、流程图和知识图谱的文档构建步骤；
- Web/WASM 应用导出 SVG 前的离线验证组件；
- CI 中用于检测坐标漂移、节点重叠和边交叉的回归工具；
- 教学材料、报告和静态站点发布前的图形检查器。

项目只依赖纯 MoonBit 数据结构和整数几何计算，不访问网络、不绑定浏览器 DOM，也不
要求使用某一个特定的布局引擎。

## 4、完整的预期使用场景

### 场景一：软件架构图的 CI 质量门禁

团队使用 Moon ELK、Graphviz 或自定义程序生成架构图坐标，并保存为：

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

Pull Request 中执行：

```bash
moon run src/cmd/moonlayout -- \
  --input architecture.snapshot \
  --report architecture-report.json \
  --svg architecture-audit.svg
```

如果节点重叠、越界或边交叉数量超过阈值，CLI 返回非零退出码，CI 阻止问题图形进入
README、设计文档和发布页面。

### 场景二：文档构建的布局回归检测

项目将上一版本的图布局快照和稳定指纹提交到仓库。升级布局引擎、修改节点尺寸或调整
文档主题后重新运行审计，比较节点数量、边数量、指纹和质量指标。如果图形发生意外
漂移或可读性下降，报告会列出具体违规项，开发者无需手工打开图片排查。

### 场景三：多个布局引擎的统一比较

同一份依赖图可以分别交给 Moon ELK、Graphviz 和其他布局器处理，再将结果转换为统一
快照格式。MoonLayout Audit 使用同一套指标比较它们的重叠、边交叉、边长和画布利用
情况，帮助应用选择质量更高的布局结果。

### 场景四：教学、知识图谱与报告发布前检查

课程作者或报告作者将知识点、章节或实体关系导出为快照，在生成 SVG 之前检查标签
区域是否相互遮挡、连线是否交叉和节点是否超出画布。审计通过后，SVG 可以直接嵌入
课程网页、电子讲义和离线报告。

## 5、拟实现的核心功能

### 快照数据模型

- `PositionedNode`：节点标识、中心坐标、宽度和高度；
- `Edge`：有向边的源节点和目标节点标识；
- `LayoutSnapshot`：画布尺寸、节点集合和边集合；
- `AuditConfig`：重叠、交叉、越界和边长阈值；
- `AuditReport`：统计指标、稳定指纹、通过状态和违规明细。

### 确定性几何审计

- 使用轴对齐矩形检测节点重叠；
- 检测节点中心坐标完全重复的情况；
- 检测节点是否超出画布边界；
- 使用整数方向判断检测非共享端点的边交叉；
- 统计最小、最大和平均曼哈顿边长；
- 使用稳定序列化和整数哈希生成快照指纹；
- 使用配置阈值决定审计通过或失败。

### 输入与输出

- 解析带行号错误提示的 `.snapshot` 文本格式；
- 支持空行和注释；
- 拒绝重复节点、非法数字和不存在的边端点；
- 输出文本报告和 JSON 报告；
- 输出包含箭头、标题、描述和违规颜色标记的 SVG；
- CLI 以 `0/1/2` 分别表示通过、质量失败和输入错误。

### 工程质量

- MoonBit 单元测试覆盖重叠、越界、边交叉、重复坐标、指纹稳定性和 SVG 输出；
- Node 集成测试覆盖正常快照、质量失败快照、缺失文件和错误参数；
- CI 执行格式检查、警告检查、测试、接口生成、JS 构建和示例审计；
- 核心库不依赖网络、数据库或第三方运行时；
- MIT License，适合被其他 MoonBit 项目嵌入。

## 6、原创性、移植性与参考说明

MoonLayout Audit 是**原创项目**，不是 Eclipse Layout Kernel、Graphviz 或 d3-force 的
代码移植，也没有复制这些项目的源代码。项目的核心贡献是针对布局快照的确定性质量
审计、回归指纹、机器可读报告和 CI 退出码。

社区中的 [`wangjiale6036-dotcom/moon_elk`](https://github.com/wangjiale6036-dotcom/moon_elk)
和 [`gfy185/moon_elk`](https://github.com/gfy185/moon_elk) 主要负责生成图布局，属于
本项目可以验证的上游布局来源；MoonLayout Audit 不实现同类的 Layered、Force、Radial
等自动布局算法，因此定位为互补的质量验证层。

## 7、参考项目、来源链接与许可证

本项目不是移植项目，不包含被移植项目的源代码，因此没有需要继承的上游许可证。

为说明兼容场景和问题背景，项目参考以下公开项目的产品形态或输入生态：

- **Eclipse Layout Kernel (ELK)**：<https://github.com/eclipse-elk/elk>
  - 许可证：Eclipse Public License 2.0
  - 用途：作为可被审计的布局生成器示例，不复制源代码。
- **Graphviz**：<https://graphviz.org/>
  - 许可证：Eclipse Public License 1.0
  - 用途：作为可被审计的图形输出工具示例，不打包其运行时。
- **d3-force**：<https://github.com/d3/d3-force>
  - 许可证：ISC License
  - 用途：仅参考图布局结果需要质量验证这一使用背景，不复制源代码。

MoonLayout Audit 自身以 MIT License 发布，许可证全文见仓库根目录的 `LICENSE` 文件。

## 验收与复现命令

```bash
moon fmt
moon check --deny-warn
moon test --deny-warn
moon info
moon build --target js src/cmd/moonlayout
node --test tests/cli.integration.test.mjs
moon run src/cmd/moonlayout -- --input examples/pipeline.snapshot --report audit-report.json --svg audit.svg
```

合格示例应输出 `status: PASS`、0 个重叠节点、0 条交叉边和 0 个越界节点；
`examples/overlap.snapshot` 应返回退出码 1，以证明质量门禁能够阻止不合格布局。
