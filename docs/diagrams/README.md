# Skill-Based Architecture 可视化文档

一套把「从用户提问到任务闭合」讲清楚的图：**全局架构** + **端到端流程** + **路由核心专题** + **单模块/维度图**。
每张都有 `.svg`（可编辑源）和 `.png`（1360px 宽、2× 高清、白底，任意查看器可开）。

配色图例（全局统一）：
**灰 = 步骤/中立/投影 · 琥珀 = 判定闸门 · 蓝 = 脚本/校验 · 青 = 骨架层(skill_root) · 珊瑚 = 肉层(code_root) · 紫 = routing 机制主轴**

---

## 图索引

| 分类 | 图 | 说明 |
|---|---|---|
| 全局 | [system-panorama](system-panorama.png) | 七层静态架构全景 |
| 全局 | [skill-flow-complete](skill-flow-complete.png) | 端到端流程（提问 → 闭合，八阶段） |
| 路由专题 | [routing-core](routing-core.png) | routing 核心思维（唯一真源 + 自维护回环） |
| 路由专题 | [routes-to-workflows](routes-to-workflows.png) | 两个 Skill 的真实 route → workflow 映射 |
| 路由专题 | [file-call-graph-fixbug](file-call-graph-fixbug.png) | 一条 route 的文件调用关系（骨架/肉 + index 扇出） |
| 维度 | [progressive-rigor](progressive-rigor.png) | 三档生长（只在压力下升档，缩水则降档） |
| 维度 | [upstream-downstream-sync](upstream-downstream-sync.png) | 元仓 ↔ 下游 app 的 vendor / 搬运 / 落后检测 |

---

## 一、全局架构 —— 七层（见 `system-panorama`）

自上而下是「一次调用穿过的所有层」：

1. **触发 · 活化** —— 用户/任务 + harness（Claude Code / Cursor / Codex / Gemini）。由 `description` 做**粗活化**：只决定「这个 skill 该不该醒」，故意不写 workflow 步骤。
2. **入口薄壳** —— `AGENTS.md / CLAUDE.md / CODEX.md / GEMINI.md / .cursor/rules`。**只做 bootstrap**，内容由 routing 生成，不承载领域规则。
3. **路由核心 · 唯一真源** —— `SKILL.md`(router, dual budget) + `routing.yaml`(唯一真源)。薄壳 bootstrap、Common Tasks、Always Read **都是它生成的投影**。
4. **知识层 · 按 abstraction 两层** —— 骨架 `skill_root`（architecture/rules/workflows，稳定）vs 肉 `code_root`（conventions/gotchas/references，随代码漂）。
5. **Task Anchor / 执行 / 闭合** —— Simple 任务直接执行；其他任务建立 Goal + Done When，默认只做自然语言对齐、复杂或范围敏感任务才展示完整简报，Native Plan 可见时不在对话里重复步骤；每个主步骤前运行 Anchor Checkpoint，最后经 `task-closure` 和 blast-radius 桶 A/B/C 闭合；状态只在当前 Session，不创建计划文件。
6. **维护 / 校验脊柱** —— `sync-routing / smoke-test / route-reachability / audit-orphans`，回灌 ③ 真源、分别保证结构、链接与任务激活真实可达（**激活 not 存储**）。
7. **生命周期** —— 上游元仓 ↔ 下游 app，机制文件字节同步、骨架变更手工搬运。

---

## 二、端到端流程 —— 八阶段（见 `skill-flow-complete`）

一次任务从提问到闭合的主干（分支出口见图右侧）：

1. **① 入口引导** —— 会话纪律：同一会话后续任务只重匹配 route，仅在 route 变化/上下文压缩时重读；读薄壳 → 指向 SKILL.md + bootstrap。
2. **② 路由匹配** —— 扫 SKILL.md 命中 skill（前端/后端/双端/other）。
3. **③ 分层阅读** —— 读 Always Read + routing.yaml，匹配 route（无匹配→other），**只读 required_reads**（token 收口），按骨架/肉取用。
4. **④⑤ 锚定 + 执行 + 跨端** —— Simple 直接执行；Managed 建立 Task Anchor 并按任务风险决定自然语言对齐或完整简报，Native Plan 把 Workflow 实例化为当前步骤且不在对话中重复；每个主步骤前用 Anchor Checkpoint 重读 Goal / 剩余证据 / 步骤检查 / 相关边界；单 Skill 走领域 Workflow，跨端仍走**契约优先**。
5. **⑥ Closure Entry Gate + 桶分级** —— Goal / Done When / Plan 步骤未验证则返回执行；入口通过后，`Trigger Policy` 放行纯读任务，改动按**文件路径**落入 A/B/C 桶：
   - **A**（SKILL.md/薄壳/routing.yaml/scripts/*.tpl）→ 完整闭合：AAR + smoke-test + 路径完整性；
   - **B**（模板 rules/workflows、SKILL 链接的 references、full-migration）→ 轻量 AAR，不跑 smoke-test；
   - **C**（README/examples/docs/UPSTREAM/*.example/未链接 references）→ 跳过闭合。
   多文件取最大桶 A>B>C；A 桶内改错别字也走完整闭合（桶量的是「能炸什么」）。
6. **⑦ AAR + 沉淀** —— AAR 四问 → 想象痛点闸门（要有具体 file+line/commit/session）→ 查重 → 泛化 → 选落点 → **激活闸门**（在路径上 且 改变 agent 下一步；reached ≠ activated）。
7. **⑧ 路由同步 + 校验** —— 改路由则更新 routing.yaml + `sync-routing.sh` 回灌薄壳；A 桶完整闭合运行 smoke-test、route-reachability 与 audit-orphans。

---

## 三、路由核心（见 `routing-core` + `routes-to-workflows` + `file-call-graph-fixbug`）

routing 是这套架构**最核心的思维**，不是流程里的一个节点：

- **两级激活**：`description` 粗活化（醒不醒）→ `routing.yaml` 细分派（去哪）。二者刻意分工。
- **唯一真源**：薄壳/Common Tasks/Always Read 都由 `sync-routing.sh` 从 routing.yaml 生成，改路由只改一处、其余回灌。
- **一条 route = 意图→落点绑定**：`id + labels(中/英) + trigger_examples(自然语言) + route(策略) + required_reads + workflow`；`other` 强制兜底。
- **required_reads 外科式 + 分层**：`skill:` = 骨架（元仓），`code:` = 肉（代码层）。只读这条 route 要的。
- **route → workflow 可复用/可跳转**：多 route 共用一个 workflow（rpc-contract → implement-feature），或跳到别的 skill（do-bo → do-bo skill）。
- **激活/可达性脊柱**：route-reachability 保证每个活跃文件可从某条 route 到达，audit-orphans 杜绝孤儿——让知识不腐化。

`routes-to-workflows` 展开两侧真实路由表；`file-call-graph-fixbug` 以一条 route 为例展开它读的文件与 index 扇出关系。

---

## 四、两个独立维度

- **Progressive Rigor**（见 `progressive-rigor`）：Single-file → Folder-light → Full 三档，只在具体压力（body>90 行、同一坑两次、需要分步、多 harness 共享路由…）下升档，内容缩水则降档。
- **上下游同步**（见 `upstream-downstream-sync`）：元仓 `skill_root` 是骨架真源；下游 app `code_root` 只 vendor 机制文件（字节一致、不可编辑）并自持肉。`sync-vendor` 只在 `local==base` 时覆盖，改过就只报告。

---

## 重新生成 PNG

自包含 SVG（样式内联，不依赖任何外部 CSS），用本机 Chrome 无头渲染：

```bash
CHROME='/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
"$CHROME" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=2 \
  --default-background-color=ffffffff --window-size=680,<SVG高度> \
  --screenshot="<name>.png" "file://$PWD/<name>.svg"
```

`<SVG高度>` 取该 SVG `viewBox` 的高度值。
