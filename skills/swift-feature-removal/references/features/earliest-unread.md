# Earliest Unread Removal Inventory

## Boundary

移除范围只包括开源仓库 `nim-uikit-ios` 的 `NEChatUIKit/` 和 Demo `app/` 中的“跳转最早未读/上次阅读位置”。`NEChatKit` 是闭源组件，禁止扫描或修改；只移除 UI/Demo 对其 Last Read API 的接线。旧 `IMUIKit/` 副本、Objective-C 和 SwiftUI 工程不属于本技能。

核心名称包括 `NELastReadPosition*`、`LastReadPositionState`、`lastReadPosition*`、`enableLastReadPosition`。

## Delete Entirely

删除以下 Swift UIKit 专属路径：

- `NEChatUIKit/NEChatUIKit/Classes/Chat/View/ChatView/NEBaseChatLastReadPositionView.swift`

## Remove Demo And Localization Entries

- `app/Mine/Controller/ConfigTestViewController.swift`：删除 `showLastReadPosition` 配置块。
- `NEChatUIKit/NEChatUIKit/Assets/en.lproj/Localizable.strings`：删除 `last_read_position_count`、`last_read_position_overflow`、`last_read_position_accessibility_hint`。
- `NEChatUIKit/NEChatUIKit/Assets/zh-Hans.lproj/Localizable.strings`：删除同名三个 key。

本功能没有需要修改的 Demo 工程文件或依赖；不得因移除本功能修改 `app.xcodeproj/` 或 `Podfile`。

## Remove Swift UIKit Wiring

### ChatViewModel

在 `ChatViewModel.swift` 删除：

- `LastReadPositionState` enum。
- delegate 的 `lastReadPositionStateChanged`。
- `lastReadPositionState`、generation、prepare/settle/snapshot、anchor suppression、timeout、read-flow 等状态字段。
- `prepareLastReadPosition`、`findFirstUnreadMessage` 注入闭包。
- `enterConversation` / `leaveConversation` 中的 Last Read 准备、冻结 read time、状态恢复和 generation 逻辑；恢复原有 set-current-conversation / clear-unread 流程。
- `refreshLastReadPositionAnchorSuppression`、`updateLastReadPositionVisibility`、`supportsLastReadPosition`、`locateLastReadPosition`、`completeLastReadPositionLocation`、`loadAroundLastReadAnchor`、`updateLastReadPositionState`。
- `anchor.didSet`、deinit、消息分页/合并中仅为 Last Read 存在的调用或 guard。

不能删除普通历史分页、锚点加载、消息去重、稳定 ID 查找或会话未读清零本身；只移除 Last Read 对这些能力的包装和分支。

### ChatViewController

在 `ChatViewController.swift` 删除：

- `isLocatingLastReadPosition`。
- `lastReadPositionTopAnchor`、`lastReadPositionView`、tap recognizer 和布局约束。
- lifecycle 的 `renderLastReadPositionState`。
- 多选进入/退出时对该入口的隐藏与恢复。
- 历史预加载、Reaction reload、初始消息详情和回到底部流程中仅针对 `isLocatingLastReadPosition` 的 guard。
- `getLastReadPositionView`、`jumpToLastReadPosition`、`scrollToLastReadPosition`、`lastReadPositionStateChanged`、`renderLastReadPositionState`、`refreshLastReadPositionVisibility`、`updateLastReadPositionTopConstraint` 及所有调用。
- 顶部置顶消息变化时专为 Last Read 入口调整 top constraint 的调用。

移除 guard 后要保留 Reaction reload、初始详情加载、普通历史预加载、回到底部按钮和多选状态机的原有行为。

### Skin And Conversation Special Cases

- `FunChatViewController.swift`：删除 `getLastReadPositionView()` override。保留 `fun_chat_jump_to_new` 资源，它仍由 `FunChatNewMessageView` 使用，不是 Last Read 专属资源。
- `TopicChatViewModel.swift`：删除 `supportsLastReadPosition = false` override；删除基类能力后它已无意义。
- NormalUI 没有单独 override，使用基类默认视图；不要为删除功能新增空 override。

### Objective-C Compatibility Bridge

`NEChatUIKitObjCBridge.swift` 同时服务 OC，不能整段盲删：

- 删除依赖 Swift `LastReadPositionState` / Swift `ChatViewModel` 的 adapter：`LastReadPositionStateObjC.init(_ state:)`、`ChatViewModel` 的 `objcLastReadPositionState`、`objcIsLastReadPositionSuppressed`、`objcUpdateLastReadPositionVisibility`、`objcLocateLastReadPosition`、`objcCompleteLastReadPositionLocation`。
- 保留 OC 仍使用的 `LastReadPositionStateKindObjC`、`LastReadPositionStateObjC` 基础容器及其 `NELastReadPositionSnapshot` 属性/普通 initializer。

如果未来 OC 不再依赖这些类型，再由三端清单删除；Swift-only 移除不能造成 OC 编译断链。

## Cross-Feature Content

`ChatViewController.swift` 中 Reaction reload 的底部固定逻辑曾增加 `!isLocatingLastReadPosition` guard。移除 Last Read 时只删除该 guard，不得删除 Reaction 队列。反过来移除 Reaction 时也不得删除 Last Read 定位流程。

## Closed And Out Of Scope

- 不搜索、不打开、不修改 `NEChatKit/`。`NELastReadPositionService` 和 `enableLastReadPosition` 均视为闭源能力。
- UI/Demo 中对上述能力的 import、状态、回调和调用必须删除；闭源符号定义保留不动。
- 不扫描或修改旧 `IMUIKit/` 副本、Objective-C 或 SwiftUI 工程。

## Verification

1. `audit_inventory.py earliest-unread --phase after` 只允许 `NEChatUIKitObjCBridge.swift` 中列明的 OC 基础容器残留。
2. Swift UIKit 本地化文件不再包含三个 `last_read_position_*` key。
3. `git diff --check` 通过；对修改的 Swift 文件运行 `swiftc -frontend -parse` 或构建 `NEChatUIKit`。
4. 运行时检查 NormalUI/FunUI：聊天页无最早未读入口；顶部置顶、回到底部、多选、历史分页、Reaction 更新仍正常。
5. 最终业务 diff 只能位于 `NEChatUIKit/` 和 `app/`；只有真实 Demo 源码/资源引用需要时才允许 `app.xcodeproj/`。
