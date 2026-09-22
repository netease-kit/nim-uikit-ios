---
name: swift-feature-removal
description: 按维护清单完整移除 nim-uikit-ios Swift 开源 UI 组件和 Demo 中的已登记功能，包括入口、资源、接线和功能专属代码。当用户说“移除...功能”“去掉...功能”“删除...功能”且目标匹配登记名称或别名时自动使用，也支持显式调用 $swift-feature-removal；不要用于普通重构、未登记功能、旧 IMUIKit 副本或闭源 NEChatKit 修改。
---

# Swift Feature Removal

这个技能用于“按已维护清单移除功能”，不是在删除时重新发现功能范围。清单路径均相对于承载本技能的源码仓库根目录，唯一业务代码范围是 Swift UI 组件 `NEChatUIKit/` 和 Demo `app/`。`NEChatKit` 是闭源组件，不扫描、不修改。

## Invocation Contract

- 用户使用“移除...功能”“去掉...功能”“删除...功能”等明确删除表达，且目标命中登记名称或别名时，自动调用本技能；无需用户写 `$swift-feature-removal`。
- 用户也可以显式调用 `$swift-feature-removal`。上述两种调用都已授权移除点名功能，不要重复询问是否删除。
- 仅扫描和修改开源仓库的 `NEChatUIKit/` 与 `app/`。只有清单明确记录了真实 Demo 源码或资源引用时，才修改 `app.xcodeproj/`。
- 不扫描、不打开、不修改 `NEChatKit/`、旧副本 `IMUIKit/`、Objective-C 或 SwiftUI 工程，也不得离开当前源码 checkout 追删其他实现。
- 未登记功能不要自动套用本技能；先按“Register Future Features”建立 UI/Demo 清单。
- 不提交、不推送，除非用户另外明确要求。
- 保留 dirty worktree 中与目标需求无关的改动；禁止 reset、checkout 或按历史提交整体 revert。

## Registered Features

先读 [references/registry.md](references/registry.md)，再完整读取目标需求清单：

- 表情评论 / Emoji Reaction / Reaction：`references/features/emoji-reaction.md`
- 跳转最早未读 / 上次阅读位置：`references/features/earliest-unread.md`

结构化审计数据位于 `references/feature-registry.json`。运行：

```bash
python3 skills/swift-feature-removal/scripts/audit_inventory.py --list
python3 skills/swift-feature-removal/scripts/audit_inventory.py <feature> --phase before
# skill 尚未放入目标仓库时：追加 --repo /absolute/path/to/checkout
```

## Removal Workflow

1. 从登记表解析用户点名的需求，只加载这一份清单。不要重新对整个仓库做功能发现扫描。
2. 从脚本自动识别的源码 Git 根目录检查 `git status --short`，记录用户已有改动；只有审计其他 checkout 时才传 `--repo`。目标文件有重叠时逐段编辑，不能覆盖现有修改。
3. 运行 `audit_inventory.py <feature> --phase before`。它只按登记的路径和指纹审计；缺失项表示清单可能漂移，针对该项查看当前文件和当前仓库的 `git log -S`/`git blame`，不要扩大为全盘扫描。如果专属路径和残留均为零，确认清单列出的入口文件也不含目标符号后，报告该 checkout 已不包含此功能，不要转向其他仓库继续搜索。
4. 按清单依次处理：入口和配置 UI、闭源能力在 UI 层的接线、视图/资源、必要的 Demo 工程引用、功能专属文件。不得进入 `NEChatKit` 追删底层实现。
5. 同一文件包含其他需求时只移除目标符号和调用链。尤其不要按某个历史 commit 整体反向应用；历史提交经常混有无关修复。
6. 运行 `audit_inventory.py <feature> --phase after`。必须清除所有非允许残留，并删除清单列出的功能专属路径。
7. 执行 `git diff --check`、相关 Swift 源码解析/编译和 `git status --short`。编译不能替代 NormalUI/FunUI 运行时检查；若未运行 UI 验证要明确说明。
8. 如果定向审计发现清单遗漏或代码迁移，先完成本次移除，再同步更新该需求的 Markdown 清单与 `feature-registry.json`，保证下一次仍可直接执行。

## Completeness Rules

一次移除只有同时满足以下条件才算完成：

- 用户可见入口、配置开关和长按/点击入口消失。
- 功能专属 View、ViewModel、Controller 接线、状态字段和回调全部从 UI/Demo 移除。
- NormalUI 与 FunUI 中的布局、复用和消息类型特化代码全部移除。
- 功能专属图片、asset catalog、原始资源、本地化 key 全部移除。
- UI/Demo 中不留下仅为该功能存在的兼容桥、协议或闭源 API 调用；闭源实现本身不在处理范围。
- 定向残留审计通过，受影响模块至少通过语法/静态检查。

## Register Future Features

用户要求把新需求纳入本技能时，只在开源仓库 `NEChatUIKit/` 和 `app/` 内按 [references/manifest-template.md](references/manifest-template.md) 做一次完整发现并建立清单。不要扫描 `IMUIKit/` 或 `NEChatKit/`。新增需求必须同时：

- 在 `references/registry.md` 登记名称和别名。
- 新建 `references/features/<slug>.md`，记录删除项、共享边界、交叉需求和验证条件。
- 在 `references/feature-registry.json` 增加专属路径、编辑路径、残留指纹和允许残留。
- 运行审计脚本的 `before` 模式以及 skill-creator 提供的 `quick_validate.py`（如果目标环境已安装其 YAML 依赖）。

后续该需求发生新增入口、资源或接线变化时，在同一变更中更新清单；不要等到移除时再重新扫描。
