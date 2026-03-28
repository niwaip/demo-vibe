# Vibe-Kanban 开发框架记忆

## 核心技能体系

基于 OpenSpec + Harness 模式，设计了完整的开发流程技能：

| 阶段 | 技能 | 文件位置 |
|------|------|---------|
| 需求细化 | `/vk-refine` | `.vibe-attachments/skills/vk-refine.md` |
| 任务划分 | `/vk-split` | `.vibe-attachments/skills/vk-split.md` |
| 规划 | `/vk-plan` | `.vibe-attachments/skills/vk-plan.md` |
| 开发 | `/vk-dev` | `.vibe-attachments/skills/vk-dev.md` |
| 单体测试 | `/vk-test-unit` | `.vibe-attachments/skills/vk-test-unit.md` |
| 集成测试 | `/vk-test-int` | `.vibe-attachments/skills/vk-test-int.md` |
| 部署 | `/vk-deploy` | `.vibe-attachments/skills/vk-deploy.md` |
| 自动流程 | `/vk-auto` | `.vibe-attachments/skills/vk-auto.md` |

## 快速参考

`.vibe-attachments/VK_QUICK_REF.md` 包含所有技能的速查表。

## OpenSpec 规格格式

每个任务规格包含：
- Execution Order（执行顺序）
- Branch Isolation Rules（文件所有权）
- Objective（目标）
- Deliverables（交付物）
- Implementation（实现骨架）
- Test Cases（测试用例）
- Acceptance Criteria（验收标准）

## Harness 测试框架

核心函数：
- `assert_eq DESCRIPTION EXPECTED ACTUAL`
- `assert_contains DESCRIPTION HAYSTACK NEEDLE`
- `assert_exit_code DESCRIPTION EXPECTED ACTUAL`
- `run_tests` 汇总并返回退出码

## 并行执行策略

```
Batch 0: Foundation（先行，必须完成）
    ↓
Batch 1: Core Features（并行，可同时执行）
    ↓
Batch 2: Integration（整合，依赖Batch 1）
    ↓
Batch 3: Release（发布）
```

## 文件所有权原则

每个任务必须明确：
- READ-ONLY：可读不可写
- OWNED：完全控制
- FORBIDDEN：禁止访问

## 使用方式

用户提出需求时：
1. 简单需求 → `/vk-auto B "需求"`
2. 复杂需求 → 分阶段执行 `/vk-refine` → `/vk-split` → `/vk-plan` → `/vk-dev` → `/vk-test` → `/vk-deploy`
3. 紧急修复 → `/vk-auto A "修复描述"`