# Vibe-Kanban 开发框架记忆

## ⚠️ 执行前检查清单

**每次开始任务前，必须确认以下检查项：**

```
□ 已读取 VK_IMPORT_GUIDE.md
□ 已理解两技能分离设计
□ 当前阶段：VK-Plan 还是 VK-Execute
□ 如果 VK-Plan：
    □ 可选：EXPLORE 探索想法
    □ 需求细化追问至少3次
    □ 输出风险与回滚计划
    □ 使用 Given/When/Then 格式
    □ 输出 OpenSpec 后自我确认
    □ 等待用户确认
□ 如果 VK-Execute：
    □ 确认 Vibe-Kanban MCP 已连接
    □ 所有任务独立（无父子关系）
    □ 任务名称带阶段前缀
    □ 可选：VERIFY 验证实现
    □ 可选：ARCHIVE 归档变更
```

---

## 核心规则摘要

### Rule 1: 必须先理解框架
读取所有 memory/*.md 文件

### Rule 2: 必须按顺序执行
VK-Plan → 用户确认 → VK-Execute

### Rule 3: 需求细化提问 + 自我确认 + 用户确认
- 至少3次追问（功能目标、输入输出、非功能需求）
- 自我确认检查（任务独立性、命名规范、OpenSpec完整）
- 等待用户明确确认

### Rule 4: 检查 MCP 可用性
VK-Execute 前调用 get_context

### Rule 5: 任务独立性原则
- ❌ 禁止：创建父子子任务（parent_issue_id）
- ✅ 正确：所有任务独立，通过 relationship 设置依赖

### Rule 6: 任务命名规范
格式：`[阶段]-[功能名称]`
阶段：Foundation / Core / Integration / Release

### Rule 7: Given/When/Then 测试格式
- **Given** 前置条件
- **When** 用户操作
- **Then** 预期结果

### Rule 8: 风险与回滚
每个 OpenSpec 必须包含风险评估和回滚计划

---

## 流程阶段

```
可选                必选                          可选
──────────────────────────────────────────────────────────
EXPLORE → REFINE → SPLIT → PLAN → [确认] → EXECUTE → VERIFY → ARCHIVE
  │         │        │       │               │          │         │
  │         │        │       │               │          │         └─ 归档变更
  │         │        │       │               │          └─ 验证实现
  │         │        │       │               └─ 执行开发
  │         │        │       └─ 生成规格文档
  │         │        └─ 划分任务批次
  │         └─ 需求细化（3次追问）
  └─ 探索想法
```

---

## 导入指南

**新环境导入**：读取 `memory/VK_IMPORT_GUIDE.md`，AI Agent 可自动配置框架。

## 两技能分离设计

| 技能 | 文件 | 依赖 | 用途 |
|------|------|------|------|
| **VK-Plan** | `memory/vk-plan.md` | 无 | 探索、需求细化、任务划分、规格生成 |
| **VK-Execute** | `memory/vk-execute.md` | Vibe-Kanban MCP | 创建 Issues、启动 Workspaces、验证、归档 |

**执行顺序**：VK-Plan 完成并确认 → VK-Execute 开始

## 分层架构

```
Layer 1: METHODOLOGY      ← 抽象流程定义（无执行依赖）
Layer 2: SPECIFICATIONS   ← OpenSpec + Harness 模板
Layer 3: ORCHESTRATION    ← 批次调度、依赖解析
Layer 4: EXECUTION        ← Vibe-Kanban MCP 执行
```

## OpenSpec 模板要点

每个任务规格必须包含：
1. **Execution Order** - 执行顺序
2. **Branch Isolation Rules** - 文件所有权
3. **Objective** - 目标
4. **Risk and Rollback** - 风险与回滚
5. **Deliverables** - 交付物
6. **Implementation** - 实现骨架
7. **Test Cases (Given/When/Then)** - 测试场景
8. **Acceptance Criteria** - 验收标准

## Vibe-Kanban API 映射

| 操作 | MCP API |
|------|---------|
| 创建任务 | `mcp__vibe_kanban__create_issue` |
| 设置依赖 | `mcp__vibe_kanban__create_issue_relationship` |
| 启动 workspace | `mcp__vibe_kanban__start_workspace` |
| 执行开发 | `mcp__vibe_kanban__run_session_prompt` |
| 更新状态 | `mcp__vibe_kanban__update_issue` |

## Memory 文件清单

```
memory/
├── MEMORY.md           ← 本文件（核心索引）
├── VK_IMPORT_GUIDE.md  ← 导入指南（新环境配置）
├── vk-plan.md          ← Skill 1: 规划技能（无依赖）
├── vk-execute.md       ← Skill 2: 执行技能（依赖 MCP）
```