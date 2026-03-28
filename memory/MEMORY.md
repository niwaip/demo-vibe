# Vibe-Kanban 开发框架记忆

## 架构版本

- **v1**: 原始技能文档（混合执行假设）
- **v2**: 分层架构（方法论/规格/编排/适配器分离）

## 分层架构

```
Layer 1: METHODOLOGY      ← 抽象流程定义（无执行依赖）
Layer 2: SPECIFICATIONS   ← OpenSpec + Harness 模板
Layer 3: ORCHESTRATION    ← 批次调度、依赖解析
Layer 4: EXECUTION ADAPTERS ← Claude Code / Vibe-Kanban 适配
```

## 适配器

| 适配器 | 文件 | 执行方式 |
|--------|------|---------|
| Claude Code | `.vibe-attachments/adapters/claude_code.md` | Skill/Prompt 指导 |
| Vibe-Kanban | `.vibe-attachments/adapters/vibe_kanban.md` | MCP API 调用 |

## 技能文档位置

`.vibe-attachments/skills/*.md` - 8个阶段技能

## 重构指导

见 `.vibe-attachments/VK_ARCHITECTURE_V2.md` 详细架构设计。

## Vibe-Kanban API 映射

| 操作 | MCP API |
|------|---------|
| 创建任务 | `mcp__vibe_kanban__create_issue` |
| 设置依赖 | `mcp__vibe_kanban__create_issue_relationship` |
| 启动 workspace | `mcp__vibe_kanban__start_workspace` |
| 执行开发 | `mcp__vibe_kanban__run_session_prompt` |
| 更新状态 | `mcp__vibe_kanban__update_issue` |

## 使用方式

1. 简单任务 → Claude Code Adapter (纯 Skill 模式)
2. 复杂并行任务 → Vibe-Kanban Adapter (Workspace 并行)
3. 混合模式 → 规划用 Claude Code，开发用 Vibe-Kanban workspace