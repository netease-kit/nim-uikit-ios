---
name: swift-skin-removal
description: 按维护清单从 nim-uikit-ios 开源 Swift UIKit UI 组件和示例 App 完整移除 NormalUI（飞书风格）或 FunUI（微信风格）皮肤，包括专属源码、资源、路由和选择入口，并验证保留皮肤可构建运行。用户明确要求移除某一套 Swift UIKit 皮肤时使用；不适用于移除功能、Objective-C、SwiftUI 或闭源 NEChatKit。
---

# Swift Skin Removal

本 skill 随开源源码发布。用户只需说“移除 Swift UIKit 的飞书/NormalUI 皮肤”或“移除微信/FunUI 皮肤”，无需提供路径。删除的是**点名皮肤**，保留另一套的 UI/消息业务能力。仅处理仓库根的 `NEBaseUIKit/`、`NEChatUIKit/`、`NEContactUIKit/`、`NEConversationUIKit/`、`NELocalConversationUIKit/`、`NETeamUIKit/` 和演示 UI `app/`（必要时 `app.xcodeproj/`）；不扫描、不修改 `IMUIKit/` 旧副本、`Common/NECommonUIKit/` 旧资源、`NEChatKit`、其他端或客户自己的 App。不得因名字含 `Normal` 就删除系统控件状态、普通群语义或第三方类。

## 使用

1. 确定用户点名的皮肤：飞书/通用/NormalUI -> `normal`；微信/娱乐/FunUI -> `fun`。未点名时**先询问选哪套**，不可默认删除。读取对应 [NormalUI 清单](references/normal.md) 或 [FunUI 清单](references/fun.md)，以及 [结构化清单](references/skin-inventory.json)。无需做全仓二次发现。若仓库存在 `RULES.md`、模块 README 或更具体的 `AGENTS.md`，先遵循它们；缺失不阻塞。
2. 从本 skill 所在仓库定位源码根，检查 `git status --short`。有重叠改动逐段保留。运行 `python3 skills/swift-skin-removal/scripts/audit_inventory.py normal --phase before`（或 `fun`；技能尚未复制进目标仓库可加 `--repo /path/to/checkout`）。输出只读，专属目录、已登记的共享迁移、工程引用清理项和共享候选都会按清单列出；不需要再做全仓关键词扫描。若 `before` 报 `MISSING`，先判定是版本漂移还是已部分移除，不能凭关键词扩大范围。
3. 按清单处理：先改保留皮肤的入口/路由/消息注册和共享视图，再删除目标皮肤的专属路径和 Demo 对应类/资源；移除 Demo 工程对已删除 Swift 文件的引用。使用 `apply_patch` 编辑；删除前逐一确认清单路径，保留无关工作树修改。共享类型/API（例如 `isFun` 参数或聊天 ObjC 桥）只有在仍有存活调用者或明确外部兼容要求时才保留；如果符号仅被目标皮肤使用，则随目标皮肤一起删除。不要通过修改闭源能力实现删除。
4. 再运行审计脚本 `--phase after`，必须没有存活的专属路径、未完成的共享迁移、工程残留引用或未登记的共享候选；清单中明确保留的兼容 API 会显示为 `KEEP`，不应删除。检查 `git diff --check`。目标 checkout 结构或代码若漂移，针对**报告的具体路径**修正，并在同次改动更新两个清单文件，不能退化成客户每次全仓扫描。
5. 源码删除后重新 `pod install --no-repo-update`，因为 Podspec 的 `Classes/**/*` 和 `Assets/**/*` 通配符会在生成的 Pods 工程中缓存旧文件。首次安装若本地 Specs 不完整，先说明依赖阻塞，再尝试常规 `pod install`；不要改成本地不存在的二进制 UI Pod。构建所有六个受影响 UI Pod target 和 `app`（可先构建完整 workspace，再单独定位失败 target），运行可用的单测；检查删除资源后的 `actool`/构建日志是否有 asset 名冲突或缺失。`xcodebuild -list -workspace app.xcworkspace` 和 `xcrun simctl list devices available` 获取真实 scheme/模拟器；例如 `xcodebuild -workspace app.xcworkspace -scheme app -configuration Debug -destination 'platform=iOS Simulator,id=<实际UDID>' -derivedDataPath <独立构建目录> CODE_SIGNING_ALLOWED=NO build`。不可把 `swiftc -parse` 或编译部分目标描述成完整 App 可运行。
6. 在模拟器或设备启动**保留皮肤**，覆盖启动和登录后路由、云端/本地会话、联系人、单群聊、消息收发、搜索结果、标记/收藏、群设置、样式入口消失；检查图片/音频/富文本/回复等不同消息以及皮肤资源实际显示。没有登录凭证、依赖或设备时明确列出未验证项目；只有编译通过并实际启动/互动之后才能声称“正常编译、运行”。不要提交/推送，除非另有明确要求。

## 清单维护

新增 UI 页面、Demo 入口或皮肤资源时，同一变更维护 `references/skin-inventory.json` 及对应皮肤说明；维护者可做一次范围发现，终端客户执行移除时只跑定向审计。若删除皮肤目录会暴露共享类型，登记 `shared_migrations`；若公开兼容符号必须保留，登记 `accepted_candidates`，让审计明确输出 `KEEP`；若 Demo 工程有显式文件引用，登记 `project_cleanup`。脚本只审计登记的路径和行，不做全仓 `rg`，也不会自动删除文件。`before` 遇到预期路径缺失要查明是版本漂移或已部分移除；`after` 的候选行需结合上下文判断，不可凭关键词盲删。`NEChatKit` 为闭源依赖，永不纳入清单。
