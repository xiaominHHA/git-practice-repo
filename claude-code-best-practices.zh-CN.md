# Claude Code：代理式编程最佳实践

发布日期：2025年4月18日

摘要：Claude Code 是用于代理式编程的命令行工具。本文汇总在不同代码库、语言与环境中使用 Claude Code 被证明有效的技巧与方法。

我们最近发布了 [Claude Code](https://www.anthropic.com/news/claude-3-7-sonnet)，这是一个面向代理式编程的命令行工具。作为研究项目开发，Claude Code 为 Anthropic 的工程师和研究人员提供了更原生的方式，将 Claude 集成到他们的编码工作流中。

Claude Code 有意保持低层且不带强观点，提供接近原始模型的访问方式，而不强制特定工作流。这种设计理念带来了灵活、可定制、可脚本化且安全的强力工具。但正因为灵活，它对刚接触代理式编码工具的工程师有一定学习曲线——至少在他们形成自己的最佳实践之前。

本文概述了一些被证明有效的通用模式，既适用于 Anthropic 内部团队，也适用于外部工程师在不同代码库、语言和环境中使用 Claude Code 的场景。清单中的建议并非固定不变，也不一定适用于所有人；把它们当作起点即可。我们鼓励你亲自试验，找到最适合自己的做法！

*想了解更详细的信息？我们的完整文档 [claude.ai/code](https://claude.ai/code) 覆盖了本文提到的全部功能，并提供更多示例、实现细节和高级技巧。*

## 1. 自定义你的设置

Claude Code 是一个代理式编码助手，会自动把上下文拉入提示词。这种上下文收集会消耗时间和 token，但你可以通过调整环境来优化它。

### a. 创建 `CLAUDE.md` 文件

`CLAUDE.md` 是一个特殊文件，Claude 在开启对话时会自动拉入上下文。这使它成为记录以下内容的理想位置：

- 常用 bash 命令
- 核心文件与工具函数
- 代码风格指南
- 测试说明
- 仓库协作规范（例如分支命名、merge 与 rebase 的约定等）
- 开发环境设置（例如 pyenv 的使用、哪些编译器可用）
- 项目特有的意外行为或警告
- 其他希望 Claude 记住的信息

`CLAUDE.md` 文件没有强制格式。我们建议保持简洁、易读。例如：

```
# Bash 命令
- npm run build: 构建项目
- npm run typecheck: 运行类型检查

# 代码风格
- 使用 ES modules (import/export) 语法，而不是 CommonJS (require)
- 尽可能解构导入（例如 import { foo } from 'bar'）

# 工作流
- 完成一系列代码改动后务必进行类型检查
- 为了性能，优先运行单个测试而不是整个测试集
```

你可以在多个位置放置 `CLAUDE.md` 文件：

- **仓库根目录**，或你运行 `claude` 的位置（最常见）。命名为 `CLAUDE.md` 并提交到 git，便于团队共享（推荐）；或命名为 `CLAUDE.local.md` 并加入 `.gitignore`

- **运行 `claude` 的目录的任意父级目录**。这对单体仓库很有用，例如你在 `root/foo` 运行 `claude`，同时在 `root/CLAUDE.md` 与 `root/foo/CLAUDE.md` 放置文件，它们都会自动进入上下文

- **运行 `claude` 的目录的任意子目录**。这是上一条的反向：在这种情况下，Claude 会在你处理子目录文件时按需拉入对应的 `CLAUDE.md`

- **你的主目录**（`~/.claude/CLAUDE.md`），让它应用到你所有的 *claude* 会话

当你运行 `/init` 命令时，Claude 会自动为你生成 `CLAUDE.md`。

### b. 调整你的 `CLAUDE.md` 文件

你的 `CLAUDE.md` 会成为 Claude 提示词的一部分，所以它应像任何高频提示词一样不断打磨。一个常见错误是添加大量内容却不迭代其效果。花些时间试验，找到能让模型最好地遵循指令的写法。

你可以手动给 `CLAUDE.md` 添加内容，也可以按 `#` 键向 Claude 下达指令，它会自动把指令纳入相应的 `CLAUDE.md`。许多工程师会频繁使用 `#` 在编码过程中记录命令、文件和风格指南，并在提交中包含 `CLAUDE.md` 的更新，让团队成员也能受益。

在 Anthropic，我们会偶尔把 `CLAUDE.md` 交给 [prompt improver](https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/prompt-improver) 处理，并常通过强调（例如加入 “IMPORTANT” 或 “YOU MUST”）来提升指令遵循度。

![Claude Code 工具允许列表](https://cdn.sanity.io/images/4zrzovbb/website/6961243cc6409e41ba93895faded4f4bc1772366-1600x1231.png)

### c. 整理 Claude 的允许工具列表

默认情况下，Claude Code 会对任何可能修改系统的动作请求权限：文件写入、许多 bash 命令、MCP 工具等。我们刻意采用这种保守策略以优先保障安全。你可以自定义允许列表，放行你确定安全的工具，或放行那些即使不安全也容易回滚的工具（例如文件编辑、`git commit`）。

管理允许工具有四种方式：

- 在会话提示时选择 “Always allow”

- 启动 Claude Code 后使用 `/permissions` 命令添加或移除允许的工具。例如添加 `Edit` 以始终允许文件编辑，添加 `Bash(git commit:*)` 以允许 git 提交，或添加 `mcp__puppeteer__puppeteer_navigate` 以允许通过 Puppeteer MCP 服务器进行导航

- 手动编辑 `.claude/settings.json` 或 `~/.claude.json`（我们建议将前者纳入版本控制以便团队共享）

- 使用 `--allowedTools` CLI 标志设置会话级权限

### d. 如果使用 GitHub，安装 gh CLI

Claude 知道如何使用 `gh` CLI 与 GitHub 交互，以创建 issue、打开 PR、读取评论等。即便没有安装 `gh`，Claude 仍然可以使用 GitHub API 或 MCP 服务器（若已安装）。

## 2. 给 Claude 更多工具

Claude 可以访问你的 shell 环境，你可以像为自己一样构建一套便捷脚本和函数让它使用。它还可以通过 MCP 和 REST API 利用更复杂的工具。

### a. 使用 Claude 配合 bash 工具

Claude Code 会继承你的 bash 环境，从而访问你所有工具。Claude 了解常见的 unix 工具和 `gh`，但对你的自定义 bash 工具并不了解，除非你明确说明：

1. 告诉 Claude 工具名称并给出用法示例
2. 告诉 Claude 运行 `--help` 查看工具文档
3. 在 `CLAUDE.md` 里记录常用工具

### b. 使用 Claude 与 MCP

Claude Code 同时扮演 MCP 服务器与客户端。作为客户端，它可连接多个 MCP 服务器，以三种方式访问它们的工具：

- **项目配置**（在该目录运行 Claude Code 时可用）

- **全局配置**（在所有项目中可用）

- **提交到仓库的 `.mcp.json` 文件**（代码库中所有成员都可用）。例如你可以在 `.mcp.json` 中加入 Puppeteer 和 Sentry 服务器，让团队里的每位工程师开箱即用

使用 MCP 时，还可以带上 `--mcp-debug` 标志启动 Claude，帮助定位配置问题。

### c. 使用自定义斜杠命令

对于重复性流程（调试循环、日志分析等），可将提示模板放在 `.claude/commands` 文件夹中的 Markdown 文件里。当你输入 `/` 时，这些命令会出现在斜杠命令菜单中。你也可以将它们提交到 git，供团队其他成员使用。

自定义斜杠命令可以包含特殊关键字 `$$ARGUMENTS`，用于从调用中传入参数。

例如，下面是一条用于自动拉取并修复 GitHub issue 的斜杠命令：

```
请分析并修复 GitHub issue：$ARGUMENTS。

按以下步骤执行：

1. 使用 `gh issue view` 获取 issue 详情
2. 理解 issue 中描述的问题
3. 在代码库中搜索相关文件
4. 实现必要的改动以修复问题
5. 编写并运行测试以验证修复
6. 确保代码通过 lint 和类型检查
7. 创建清晰的提交信息
8. 推送并创建 PR

记得使用 GitHub CLI (`gh`) 完成所有 GitHub 相关任务。
```

将上述内容放入 `.claude/commands/fix-github-issue.md` 后，它会在 Claude Code 中以 `/project:fix-github-issue` 命令可用。例如你可以执行 `/project:fix-github-issue 1234` 让 Claude 修复 issue #1234。同样地，你也可以把个人常用命令放在 `~/.claude/commands` 文件夹中，让它们在所有会话里可用。

## 3. 尝试常见工作流

Claude Code 不强制你遵循某个固定工作流，让你可以按自己的方式使用。在这种灵活空间内，用户社区已经沉淀出一些高效使用 Claude Code 的常见模式：

### a. 探索、规划、编码、提交

这种通用流程适用于许多问题：

1. **让 Claude 阅读相关文件、图片或 URL**，可以给出泛化提示（“读处理日志的文件”）或具体文件名（“读 logging.py”），但要明确告诉它此时不要写代码。

  1. 这一阶段很适合强力使用子代理，尤其是复杂问题。让 Claude 使用子代理去核对细节或调查它可能提出的问题，尤其是在对话或任务的早期，往往能在几乎不损失效率的情况下保留更多上下文空间。

1. **让 Claude 为具体问题制定计划**。我们建议使用 “think” 触发扩展思考模式，让 Claude 获得额外计算时间以更充分地评估方案。这些特定短语在系统中对应递增的思考预算："think" < "think hard" < "think harder" < "ultrathink"。每一级都会为 Claude 分配更高的思考预算。

  1. 如果这一步的结果看起来合理，你可以让 Claude 把计划写成文档或 GitHub issue，便于你在实现（步骤 3）不理想时回退到这一位置。

1. **让 Claude 用代码实现方案**。这也是一个适合让它在实现过程中明确验证方案合理性的阶段。

1. **让 Claude 提交结果并创建 PR**。如果相关，也可以让它更新 README 或 changelog，说明刚刚做了什么。

步骤 #1-#2 非常关键——否则 Claude 往往会直接跳到写代码。虽然有时这正是你想要的，但对需要更深入前期思考的问题来说，先让 Claude 研究并规划会显著提升效果。

### b. 写测试、提交；写代码、迭代、提交

这是 Anthropic 最喜欢的流程之一，适用于可通过单元测试、集成测试或端到端测试验证的改动。代理式编码让 TDD 更加强大：

1. **让 Claude 基于预期输入/输出对编写测试**。明确告诉它你正在进行 TDD，以避免它为尚不存在的功能写出 mock 实现。

1. **让 Claude 运行测试并确认失败**。此阶段明确要求它不要写实现代码通常很有帮助。

1. **在你满意后让 Claude 提交测试**。

1. **让 Claude 编写通过测试的代码**，并要求它不要修改测试。告诉 Claude 一直迭代直到所有测试通过。通常它会经历多轮：写代码、跑测试、调整代码、再跑测试。

  1. 在这一阶段，可以让它用独立子代理验证实现是否对测试过拟合。

1. **当你对改动满意后让 Claude 提交代码**。

当 Claude 有清晰的目标可迭代时表现最好——比如视觉稿、测试用例或其他输出。通过提供期望输出（如测试），Claude 可以不断修改、评估结果，并逐步改进直到成功。

### c. 写代码、截图结果、迭代

与测试流程类似，你可以给 Claude 视觉目标：

1. **给 Claude 提供截图能力**（例如使用 [Puppeteer MCP server](https://github.com/modelcontextprotocol/servers/tree/c19925b8f0f28155ad72b08d2368f0007c86eb8e6/src/puppeteer)、[iOS simulator MCP server](https://github.com/joshuayoes/ios-simulator-mcp)，或手动把截图复制/粘贴进 Claude）。

1. **给 Claude 提供视觉稿**，通过复制/粘贴或拖拽图片，或提供图片文件路径。

1. **让 Claude 用代码实现设计**，截图结果，并不断迭代直到与视觉稿匹配。

1. **满意后让 Claude 提交**。

与人类类似，Claude 的输出通常会随着迭代显著提升。第一版可能已经不错，但经过 2-3 轮迭代通常会更好。让 Claude 能看到自己的输出，效果最佳。

![安全 YOLO 模式](https://cdn.sanity.io/images/4zrzovbb/website/6ea59a36fe82c2b3300bceaf3b880a4b4852c552d-1600x1143.png)

### d. 安全 YOLO 模式

你也可以不去监督 Claude，而使用 `claude --dangerously-skip-permissions` 跳过所有权限检查，让 Claude 不中断地工作直到完成。它适用于修复 lint 错误或生成样板代码等流程。

让 Claude 执行任意命令存在风险，可能导致数据丢失、系统损坏，甚至数据外泄（例如通过提示注入攻击）。为降低风险，请在无网络访问的容器中使用 `--dangerously-skip-permissions`。你可以参考这个基于 Docker Dev Containers 的[实现](https://github.com/anthropics/claude-code/tree/main/.devcontainer)。

### e. 代码库问答

当你接手一个新的代码库时，可以用 Claude Code 来学习与探索。你可以问 Claude 与结对编程时会问项目工程师的那些问题。Claude 可以代理式地搜索代码库，回答如下通用问题：

- 日志是如何工作的？
- 我该如何新增一个 API 端点？
- `foo.rs` 的第 134 行里 `async move { ... }` 是什么意思？
- `CustomerOnboardingFlowImpl` 处理了哪些边缘情况？
- 为什么在第 333 行我们调用的是 `foo()` 而不是 `bar()`？
- `baz.py` 第 334 行在 Java 中的等价实现是什么？

在 Anthropic，以这种方式使用 Claude Code 已成为我们的核心入职上手流程，显著提升了上手速度并减轻了其他工程师的负担。不需要特殊提示！只需提出问题，Claude 就会探索代码并给出答案。

![使用 Claude 与 git 交互](https://cdn.sanity.io/images/4zrzovbb/website/a08ea13c2359aac0eceacebf2e15f81e8e8ec8d2-1600x1278.png)

### f. 使用 Claude 与 git 交互

Claude 能高效完成许多 git 操作。许多 Anthropic 工程师用 Claude 处理我们 90% 以上的 *git* 交互：

- **搜索 git 历史**，回答诸如“哪些改动进入了 v1.2.3？”、“谁负责这个功能？”或“为什么这个 API 这样设计？”等问题。最好明确提示 Claude 查看 git 历史来回答这类问题。

- **编写提交信息**。Claude 会自动查看你的改动与近期历史，综合相关上下文生成提交信息。

- **处理复杂 git 操作**，例如回滚文件、解决 rebase 冲突、比较并嫁接补丁等

### g. 使用 Claude 与 GitHub 交互

Claude Code 能处理许多 GitHub 交互：

- **创建 PR**：Claude 能理解 “pr” 缩写，并会根据 diff 与周边上下文生成合适的提交信息。

- **一键解决简单 code review 评论**：只需让它修复 PR 上的评论（可选地提供更具体指令），完成后将改动推回 PR 分支。

- **修复构建失败** 或 lint 警告

- **对开放 issue 进行分类与分诊**：让 Claude 遍历开放的 GitHub issues

这样可以在自动化日常任务的同时，不必记住 `gh` 的命令行语法。

### h. 使用 Claude 处理 Jupyter notebooks

Anthropic 的研究员和数据科学家使用 Claude Code 读写 Jupyter notebook。Claude 能解释输出（包括图片），提供快速探索与交互数据的方式。不需要固定提示或流程，但我们推荐让 Claude Code 与 `.ipynb` 文件在 VS Code 中并排打开。

在展示给同事前，你也可以让 Claude 清理或美化 Jupyter notebook。明确要求它让 notebook 或可视化“更美观”通常能提醒它在优化人类观看体验。

## 4. 优化你的工作流

以下建议适用于所有工作流：

### a. 指令要具体

更具体的指令能显著提升 Claude Code 的成功率，尤其在首次尝试时。提前给出清晰方向，能减少后续纠偏。

例如：

| 较差 | 较好 |
| --- | --- |
| 为 foo.py 添加测试 | 为 foo.py 新增一个测试用例，覆盖用户已登出这一边缘情况。避免使用 mock。 |
| 为什么 ExecutionFactory 的 API 这么奇怪？ | 查看 ExecutionFactory 的 git 历史并总结它的 API 是如何形成的。 |
| 添加一个日历小组件 | 先看看主页上已有小组件的实现方式，理解代码与界面是如何分离的。HotDogWidget.php 是一个很好的起点。然后遵循该模式实现一个新的日历小组件：允许用户选择月份，并能前后翻页选择年份。请在不引入除现有依赖之外的库的前提下从头实现。 |

Claude 能推断意图，但无法读心。越具体，越能对齐预期。

![给 Claude 提供图片](https://cdn.sanity.io/images/4zrzovbb/website/75e1b57a0b6996e7aafeca1ed5fa6ba7c601a5953-1360x1126.png)

### b. 给 Claude 提供图片

Claude 在图片与图示方面表现很强，可通过以下方式使用：

- **粘贴截图**（小技巧：在 macOS 上按 *cmd+ctrl+shift+4* 截图到剪贴板，再按 *ctrl+v* 粘贴。注意这不是你常用的 *cmd+v*，而且远程环境下不可用。）

- **直接拖拽图片**到提示输入框

- **提供图片文件路径**

这对以设计稿作为 UI 开发参考、或用可视化图表进行分析与调试特别有用。如果你没有把视觉信息加入上下文，也可以明确告诉 Claude 结果需要“好看”到什么程度。

![提及希望 Claude 查看或处理的文件](https://cdn.sanity.io/images/4zrzovbb/website/7372868757dd17b6f2d3fef98d499d7991d89800-1450x1164.png)

### c. 提及希望 Claude 查看或处理的文件

使用 tab 补全快速引用仓库中任意文件或文件夹，帮助 Claude 找到或更新正确的资源。

![给 Claude 提供 URL](https://cdn.sanity.io/images/4zrzovbb/website/e071de707f209bbbaa7f16b593cc7ed0739875dae-1306x1088.png)

### d. 给 Claude 提供 URL

在提示中附上具体 URL，让 Claude 抓取并阅读。为避免同一域名（例如 docs.foo.com）的重复权限提示，可使用 `/permissions` 将域名加入允许列表。

### e. 尽早并频繁纠偏

虽然自动接受模式（shift+tab 切换）让 Claude 可以自主工作，但通常你作为积极的协作者、引导 Claude 的方法会获得更好的结果。你可以在一开始就详尽说明任务以获取最佳效果，也可以随时纠偏。

以下四个工具有助于纠偏：

- **让 Claude 在编码前先制定计划**，并明确要求它在你确认计划前不要写代码。

- **按下 Escape 打断** Claude 的任何阶段（思考、工具调用、文件编辑），保留上下文以便你调整或补充指令。

- **双击 Escape 回到历史**，编辑之前的提示并探索不同方向。你可以反复编辑提示直到得到想要的结果。

- **让 Claude 撤销改动**，常与第 2 点结合使用，以尝试不同方案。

尽管 Claude Code 偶尔能一次性完美解决问题，但使用这些纠偏工具通常能更快产出更好的方案。

### f. 使用 `/clear` 保持上下文聚焦

在长会话中，Claude 的上下文窗口可能被无关对话、文件内容和命令填满，降低性能并分散注意力。请在不同任务之间频繁使用 `/clear` 重置上下文。

### g. 对复杂工作流使用清单和草稿板

对于步骤繁多或需要穷举式解决的大任务——例如代码迁移、修复大量 lint 错误、运行复杂构建脚本——可以让 Claude 使用一个 Markdown 文件（甚至 GitHub issue）作为清单和工作草稿，从而提升表现：

例如，为修复大量 lint 问题，你可以这样做：

1. **让 Claude 运行 lint 命令**，并把所有错误（含文件名与行号）写入 Markdown 清单

1. **让 Claude 逐条处理问题**，修复并验证后勾选，再继续下一条

### h. 把数据传给 Claude

向 Claude 提供数据有多种方式：

- **直接复制粘贴**到提示中（最常见）

- **通过管道传给 Claude Code**（例如 `cat foo.txt | claude`），尤其适合日志、CSV 和大体量数据

- **让 Claude 通过 bash 命令、MCP 工具或自定义斜杠命令获取数据**

- **让 Claude 读取文件或抓取 URL**（对图片也适用）

大多数会话都会混合使用这些方法。例如，你可以先把日志文件通过管道传入，再让 Claude 使用工具拉取额外上下文来排查日志。

## 5. 使用无头模式自动化基础设施

Claude Code 提供了 [headless mode](https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/overview#automate-ci-and-infra-workflows)，用于 CI、pre-commit hooks、构建脚本和自动化等非交互场景。用 `-p` 搭配提示词启用无头模式，并使用 `--output-format stream-json` 输出流式 JSON。

注意：无头模式不会跨会话持久化。每次会话都需要重新启用。

### a. 使用 Claude 进行 issue 分诊

无头模式可以驱动由 GitHub 事件触发的自动化，例如你的仓库创建新 issue 时。比如公开的 [Claude Code 仓库](https://github.com/anthropics/claude-code/blob/main/.github/actions/claude-issue-triage-action/action.yml) 使用 Claude 检查新 issue 并分配合适的标签。

### b. 使用 Claude 作为 linter

Claude Code 能提供传统 lint 工具无法发现的[主观性代码审查](https://github.com/anthropics/claude-code-action/blob/main/action.yml)，识别错别字、过期注释、误导性的函数或变量名等问题。

## 6. 多 Claude 工作流进阶

除了单实例使用外，更强大的做法之一是并行运行多个 Claude 实例：

### a. 让一个 Claude 写代码，另一个 Claude 验证

一种简单而有效的方法是让一个 Claude 写代码，另一个 Claude 审查或测试。类似多人协作，分离上下文有时更有利：

1. 让 Claude 写代码
2. 运行 `/clear` 或在另一个终端启动第二个 Claude
3. 让第二个 Claude 审查第一个 Claude 的工作
4. 再启动一个 Claude（或再次 `/clear`），读取代码与审查反馈
5. 让这个 Claude 根据反馈修改代码

你也可以对测试做类似分工：一个 Claude 写测试，另一个 Claude 写代码让测试通过。你甚至可以让不同 Claude 通过各自的草稿板互相“通信”，明确哪个负责写、哪个负责读。

这种分离通常比让单个 Claude 处理所有事情效果更好。

### b. 对仓库进行多个检出

与其等待 Claude 完成每一步，Anthropic 的许多工程师会这样做：

1. **在不同文件夹创建 3-4 个 git 检出**
2. **在不同终端标签页打开每个文件夹**
3. **在每个文件夹启动 Claude 并分配不同任务**
4. **轮询查看进度并批准/拒绝权限请求**

### c. 使用 git worktree

这个方法适合并行的独立任务，且比多个检出更轻量。git worktree 允许你从同一仓库检出多个分支到不同目录。每个 worktree 有独立的工作目录和文件，但共享相同的 Git 历史与 reflog。

使用 git worktree 可以让你在项目的不同部分同时运行多个 Claude 会话，各自专注于独立任务。例如，一个 Claude 重构认证系统，另一个开发完全无关的数据可视化组件。因为任务互不重叠，每个 Claude 都能全速工作，无需等待对方改动或处理合并冲突：

1. **创建 worktree**：`git worktree add ../project-feature-a feature-a`

1. **在每个 worktree 中启动 Claude**：`cd ../project-feature-a && claude`

1. **按需创建更多 worktree**（在新终端标签页重复步骤 1-2）

一些小提示：

- 使用一致的命名规范

- 每个 worktree 保持一个终端标签页

- 如果你在 Mac 上使用 iTerm2，可[设置通知](https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/overview#notification-setup)以便 Claude 需要关注时提醒你

- 为不同 worktree 使用独立 IDE 窗口

- 完成后清理：`git worktree remove ../project-feature-a`

### d. 使用自定义调度器的无头模式

`claude -p`（无头模式）可将 Claude Code 以程序化方式融入更大的工作流，同时沿用其内置工具与系统提示。使用无头模式主要有两种模式：

1. **扇出（Fanning out）**：处理大规模迁移或分析（例如分析数百份日志的情感，或分析数千个 CSV）：

1. 让 Claude 写脚本生成任务清单。例如生成需要从框架 A 迁移到框架 B 的 2000 个文件列表。

1. 遍历任务，逐个以程序化方式调用 Claude，并给它任务与可用工具。例如：`claude -p "migrate foo.py from React to Vue. When you are done, you MUST return the string OK if you succeeded, or FAIL if the task failed." --allowedTools Edit Bash(git commit:*)`

1. 多次运行脚本并不断调整提示词，直到达到期望效果。

2. **流水线（Pipelining）**：把 Claude 接入现有数据/处理流水线：

1. 调用 `claude -p "<your prompt>" --json | your_command`，其中 `your_command` 是流水线的下一步

1. 就这么简单！JSON 输出（可选）可提供结构化结果，便于自动化处理。

对这两种用例而言，使用 `--verbose` 标志有助于调试 Claude 调用。我们通常建议在生产环境中关闭 verbose，以获得更干净的输出。

你有哪些使用 Claude Code 的技巧和最佳实践？欢迎 @AnthropicAI 与我们分享你的成果！

## 致谢

作者：Boris Cherny。本工作汇集了更广泛 Claude Code 用户社区中的最佳实践，社区中富有创造力的方法和工作流不断启发我们。特别感谢 Daisy Hollman、Ashwin Bhat、Cat Wu、Sid Bidasaria、Cal Rueb、Nodir Turakulov、Barry Zhang、Drew Hodun 以及其他众多 Anthropic 工程师，他们关于 Claude Code 的宝贵洞见与实践经验帮助塑造了这些建议。

> **想了解更多？**
> Anthropic Academy 提供 API 开发、Model Context Protocol 与 Claude Code 课程，完成后可获得证书。
> [浏览课程](https://anthropic.skilljar.com/)
