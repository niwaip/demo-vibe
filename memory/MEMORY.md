# Vibe-Kanban 开发框架记忆

## 导入指南

**新环境导入**：读取 `memory/VK_IMPORT_GUIDE.md`，AI Agent 可自动配置框架。

## 两技能分离设计

| 技能 | 文件 | 依赖 | 用途 |
|------|------|------|------|
| **VK-Plan** | `memory/vk-plan.md` | 无 | 需求细化、任务划分、规格生成 |
| **VK-Execute** | `memory/vk-execute.md` | Vibe-Kanban MCP | 创建 Issues、启动 Workspaces |

**执行顺序**：VK-Plan 完成并确认 → VK-Execute 开始

## 分层架构

```
Layer 1: METHODOLOGY      ← 抽象流程定义（无执行依赖）
Layer 2: SPECIFICATIONS   ← OpenSpec + Harness 模板
Layer 3: ORCHESTRATION    ← 批次调度、依赖解析
Layer 4: EXECUTION        ← Vibe-Kanban MCP 执行
```

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