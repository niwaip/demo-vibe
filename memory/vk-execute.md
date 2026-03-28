# VK-Execute: Vibe-Kanban 执行技能

**依赖 Vibe-Kanban MCP Server**

---

## ⚠️ 强制规则

```
1. 本技能必须在 VK-Plan 完成且用户确认后执行
2. 必须检查 Vibe-Kanban MCP 可用性
3. 必须有完整的 OpenSpec 规格文档作为输入
4. 禁止跳过任何 Batch 阶段
5. 所有 Issue 必须独立创建，不使用 parent_issue_id
6. Issue 标题必须使用阶段前缀命名
```

---

## 前置条件检查

**开始执行前，必须验证：**

```python
# 1. 检查 MCP 连接
context = mcp__vibe_kanban__get_context()
if context is None:
    raise Error("Vibe-Kanban MCP 未连接，停止执行")

# 2. 检查 VK-Plan 已完成
if not has_openspec_documents():
    raise Error("缺少 OpenSpec 规格文档，请先执行 VK-Plan")

# 3. 检查用户已确认
if not user_confirmed:
    raise Error("用户未确认规划，请等待确认")

# 4. 检查任务独立性
for task in tasks:
    if task.has_parent:
        raise Error(f"任务 {task.id} 有父子关系，请修改为独立任务")
```

---

## 技能概述

| 属性 | 值 |
|------|-----|
| 名称 | VK-Execute |
| 依赖 | Vibe-Kanban MCP Server |
| 触发 | VK-Plan 完成且用户确认 |
| 输入 | OpenSpec 规格、任务列表、依赖图 |
| 输出 | 创建的 Issues、Workspaces、开发结果 |

---

## 前置条件

1. **Vibe-Kanban MCP 已连接**
2. **VK-Plan 已完成**，用户已确认规划
3. **有可用的 Repository**（在 Vibe-Kanban 中注册）

---

## MCP API 参考

### 核心 API

| API | 用途 | 参数 |
|-----|------|------|
| `mcp__vibe_kanban__get_context` | 获取当前上下文 | 无 |
| `mcp__vibe_kanban__list_repos` | 获取可用仓库 | 无 |
| `mcp__vibe_kanban__list_organizations` | 获取组织 | 无 |
| `mcp__vibe_kanban__list_projects` | 获取项目 | organization_id |
| `mcp__vibe_kanban__create_issue` | 创建任务 | title, description, priority, project_id |
| `mcp__vibe_kanban__create_issue_relationship` | 设置依赖 | issue_id, related_issue_id, relationship_type |
| `mcp__vibe_kanban__start_workspace` | 启动开发环境 | name, executor, repositories, prompt |
| `mcp__vibe_kanban__run_session_prompt` | 执行任务 | session_id, prompt |
| `mcp__vibe_kanban__list_workspaces` | 查询状态 | workspace_id (可选) |
| `mcp__vibe_kanban__list_sessions` | 查询会话 | workspace_id |
| `mcp__vibe_kanban__update_issue` | 更新状态 | issue_id, status |
| `mcp__vibe_kanban__assign_issue` | 分配执行者 | issue_id, user_id |

### 状态值

| Status | 说明 |
|--------|------|
| pending | 待执行 |
| in_progress | 进行中 |
| needs_fix | 需修复 |
| tested_unit | 单体测试通过 |
| tested_integration | 集成测试通过 |
| review | 待审查 |
| released | 已发布 |
| completed | 完成 |

### 依赖类型

| Type | 说明 |
|------|------|
| blocking | 阻塞关系（A 必须先完成 B 才能开始） |
| related | 相关关系（参考关联） |
| has_duplicate | 重复关系 |

---

## 执行流程

### Phase 0: 环境准备

**目标**：获取执行所需的上下文信息

#### 步骤

```python
# 1. 获取当前上下文
context = mcp__vibe_kanban__get_context()
# 返回：project, issue, workspace, orchestrator-session 信息

# 2. 获取可用仓库
repos = mcp__vibe_kanban__list_repos()
# 选择目标 repo，获取 repo_id

# 3. 获取项目（如果需要）
orgs = mcp__vibe_kanban__list_organizations()
projects = mcp__vibe_kanban__list_projects(organization_id=org_id)
# 获取 project_id
```

---

### Phase 1: 创建 Issues

**目标**：将任务转化为 Vibe-Kanban Issues

#### 步骤

```python
# 遍历 VK-Plan 输出的任务列表
for task in tasks:
    # 创建 Issue
    issue = mcp__vibe_kanban__create_issue(
        title=f"{task.id}: {task.title}",
        description=task.openspec_content,  # OpenSpec 文档内容
        priority=task.priority,             # urgent/high/medium/low
        project_id=project_id               # 可选
    )
    task.issue_id = issue.id

    # 设置依赖关系
    for dep in task.dependencies:
        mcp__vibe_kanban__create_issue_relationship(
            issue_id=task.issue_id,
            related_issue_id=dep.issue_id,
            relationship_type="blocking"
        )
```

#### Issue 创建模板

**独立任务命名格式**：`[阶段]-[功能名称]`

```json
// 正确示例：独立任务，带阶段前缀
{
  "title": "Foundation-TestHarness",
  "description": "# Foundation-TestHarness\n\n## Execution Order\n**RUN_FIRST**\n\n...\n\n{完整 OpenSpec 内容}",
  "priority": "urgent",
  "project_id": "{project_uuid}"
  // 注意：不设置 parent_issue_id
}

{
  "title": "Core-SpellWords",
  "description": "# Core-SpellWords\n\n## Execution Order\n**RUN_PARALLEL**\n\n...",
  "priority": "high"
}

{
  "title": "Integration-FullPipeline",
  "description": "# Integration-FullPipeline\n\n## Execution Order\n**RUN_AFTER: [Core-SpellWords, Core-SpellLower]**\n\n...",
  "priority": "high"
}
```

**❌ 禁止做法**：
```json
// 错误：使用父子关系
{
  "title": "子任务：实现登录",
  "parent_issue_id": "xxx"  // 禁止使用
}
```

**依赖关系通过 create_issue_relationship 设置**：
```python
# 设置依赖：Core-SpellWords 依赖 Foundation-TestHarness
mcp__vibe_kanban__create_issue_relationship(
    issue_id=core_spell_words_issue_id,
    related_issue_id=foundation_issue_id,
    relationship_type="blocking"  # 阻塞关系
)
```

---

### Phase 2: 执行 Batch 0 (Foundation)

**目标**：完成基础设施任务

#### 步骤

```python
# 获取 Foundation 任务
foundation_task = tasks[0]  # T00

# 启动 Workspace
workspace = mcp__vibe_kanban__start_workspace(
    name=f"VK-{foundation_task.id}",
    executor="CLAUDE_CODE",  # 或其他 executor
    repositories=[
        {
            "repo_id": repo_id,
            "branch": f"vk/{foundation_task.id}"
        }
    ],
    prompt=foundation_task.openspec_content,
    issue_id=foundation_task.issue_id  # 关联 Issue
)

foundation_task.workspace_id = workspace.id

# 等待完成
while True:
    sessions = mcp__vibe_kanban__list_sessions(workspace_id=workspace.id)
    if all(s.completed for s in sessions):
        break
    # 可选：添加超时机制

# 更新 Issue 状态
mcp__vibe_kanban__update_issue(
    issue_id=foundation_task.issue_id,
    status="tested_unit"  # 或根据实际结果
)
```

---

### Phase 3: 执行 Batch 1 (Core - 并行)

**目标**：并行执行核心任务

#### 步骤

```python
# 获取 Batch 1 的所有任务
core_tasks = [t for t in tasks if t.batch == 1]

# 同时启动所有 Workspace
for task in core_tasks:
    workspace = mcp__vibe_kanban__start_workspace(
        name=f"VK-{task.id}",
        executor="CLAUDE_CODE",
        repositories=[
            {
                "repo_id": repo_id,
                "branch": f"vk/{task.id}"
            }
        ],
        prompt=task.openspec_content,
        issue_id=task.issue_id
    )
    task.workspace_id = workspace.id

# 等待所有完成
while True:
    all_done = True
    for task in core_tasks:
        sessions = mcp__vibe_kanban__list_sessions(workspace_id=task.workspace_id)
        if not all(s.completed for s in sessions):
            all_done = False
            break
    if all_done:
        break

# 更新所有 Issue 状态
for task in core_tasks:
    mcp__vibe_kanban__update_issue(
        issue_id=task.issue_id,
        status="tested_unit"
    )
```

---

### Phase 4: 执行 Batch 2 (Integration)

**目标**：整合所有模块

#### 步骤

```python
# 获取 Integration 任务
int_task = tasks[-1]  # T04 或最后一个

# 启动 Workspace
workspace = mcp__vibe_kanban__start_workspace(
    name=f"VK-{int_task.id}",
    executor="CLAUDE_CODE",
    repositories=[
        {
            "repo_id": repo_id,
            "branch": f"vk/{int_task.id}"
        }
    ],
    prompt=int_task.openspec_content,
    issue_id=int_task.issue_id
)

# 等待完成
# ... 同上

# 更新状态
mcp__vibe_kanban__update_issue(
    issue_id=int_task.issue_id,
    status="tested_integration"
)
```

---

### Phase 5: 结果报告

**目标**：汇总执行结果

#### 输出

```markdown
## VK-Execute 执行报告

### 执行摘要
- 总任务数: {N}
- 成功: {M}
- 失败: {F}
- 总耗时: {X} 分钟

### Issue 状态
| Task | Issue ID | Status | Workspace |
|------|----------|--------|-----------|
| T00 | {uuid} | tested_unit | VK-T00 |
| T01 | {uuid} | tested_unit | VK-T01 |
| T02 | {uuid} | tested_unit | VK-T02 |
| T03 | {uuid} | needs_fix | VK-T03 |
| T04 | {uuid} | pending | - |

### 失败任务详情
- T03: {错误原因}
  - 建议: {修复建议}

### 下一步
1. 修复失败任务后重新执行
2. 或跳过失败任务继续 Integration
3. 准备发布流程
```

---

## Executor 选择

| Executor | 适用场景 | 能力 |
|----------|---------|------|
| CLAUDE_CODE | 通用开发 | 强，推荐 |
| AMP | 简单任务 | 中 |
| GEMINI | 简单任务 | 中 |
| CODEX | 简单任务 | 中 |

建议：
- Foundation / Integration → CLAUDE_CODE
- 简单 Core 任务 → 可用其他 executor

---

## 失败处理策略

| 失败类型 | 处理 |
|---------|------|
| Foundation 失败 | 停止整个流程，报告错误，等待修复 |
| Core Task 失败 | 单个任务重试，或标记为 needs_fix |
| Integration 失败 | 检查依赖任务，修复后重试 |
| MCP 连接失败 | 检查 MCP 配置，重试连接 |

---

## 配置选项

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| executor | 执行器类型 | CLAUDE_CODE |
| branch_prefix | 分支前缀 | vk/ |
| max_parallel | 最大并行数 | 5 |
| timeout | 单任务超时（秒） | 3600 |
| retry_on_fail | 失败重试次数 | 1 |

---

## 完成标志

- ✅ 所有 Batch 执行完成
- ✅ Issues 状态已更新
- ✅ 执行报告已生成

**下一步**：部署流程（可选，由用户决定）

---

## 与 VK-Plan 的协作

```
VK-Plan 输出              VK-Execute 输入
────────────────────────────────────────
功能点清单        →      (参考)
任务列表          →      创建 Issues
依赖图            →      create_issue_relationship
批次划分          →      Workspace 启动顺序
文件所有权矩阵    →      (参考)
OpenSpec 规格     →      prompt 内容
```

---

## 监控命令

```python
# 实时监控所有 Workspace
def monitor_workspaces():
    while True:
        workspaces = mcp__vibe_kanban__list_workspaces()
        for ws in workspaces:
            sessions = mcp__vibe_kanban__list_sessions(workspace_id=ws.id)
            print(f"{ws.name}: {len(sessions)} sessions, status: {ws.status}")
        time.sleep(30)
```