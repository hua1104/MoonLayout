# MoonLayout 项目申报书

## 项目名称

MoonLayout：MoonBit 原生的确定性图自动布局引擎

## 项目简介

MoonLayout 面向依赖图、工作流、系统架构图和教学可视化场景。用户输入简洁的
`A-B,B-C` 边列表，库使用 MoonBit 实现整数力导向模拟，输出稳定的节点坐标与
可直接嵌入网页的 SVG。项目不依赖网络服务或随机种子，同一输入始终产生一致结果。

## 比赛方向

项目属于“应用开发与内容处理”中的自动布局引擎方向，类似 d3-force 的通用组件。
核心库与命令行演示均以 MoonBit 为主要实现语言，CLI 只负责参数读取和写出 SVG。

## 本期交付

- `Node`、`Edge`、`Graph` 和 `LayoutConfig` 数据模型；
- 可配置迭代次数、画布尺寸、连线距离、斥力和阻尼；
- 确定性整数力模拟，边界约束和非法边索引保护；
- `render_svg` 生成带连线、节点、标签的自包含 SVG；
- `moonlayout` CLI 与真实 SVG 演示；
- MoonBit 单元测试和 CI 构建步骤。
- 7 个 MoonBit 单元测试与 2 个 Node CLI 集成测试，覆盖正常、空图和错误参数路径。

## 原创性与参考

实现为原创 MoonBit 代码。算法采用公开的力导向布局思想，参考 d3-force 等项目
的产品形态与问题建模，但未复制其源码。整数化和固定初始网格是本项目为可复现
测试与 WASM/JS 移植做出的工程选择。

## 验收方式

```bash
moon fmt --check
moon check --deny-warn
moon test --deny-warn
moon build --target js src/cmd/moonlayout
moon run src/cmd/moonlayout -- --edges Client-API,API-DB,API-Queue --out demo.svg
```

验收时可打开生成的 `demo.svg`，检查 SVG 中的 `<line>`、`<circle>`、`<text>` 元素，
并重复运行命令确认输出稳定。

## 许可证

MIT License。
