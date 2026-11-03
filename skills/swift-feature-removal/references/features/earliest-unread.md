# Earliest Unread Removal Inventory

## Boundary

移除范围只包括开源仓库 `nim-uikit-ios` 的 `NEChatUIKit/` 和 Demo `app/` 中的“跳转最早未读/上次阅读位置”。`NEChatKit` 是闭源组件，禁止扫描或修改；只移除 UI/Demo 对其 Last Read API 的接线。Objective-C 和 SwiftUI 工程不属于本技能。

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
- 保留通用属性 `anchor` 本身（历史跳转仍在用），只删除 `didSet` 内的 `refreshLastReadPositionAnchorSuppression()` 调用；deinit、消息分页/合并中仅为 Last Read 存在的调用或 guard 一并删除。

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

本功能移除后不留 ObjC 兼容外壳，客户应得到干净的最终代码：

- `NEChatUIKitObjCChat.swift`：删除 `ChatViewModel` 上的全部 Last Read `@objc` 适配：`objcLastReadPositionState`、`objcIsLastReadPositionSuppressed`、`objcUpdateLastReadPositionVisibility`、`objcLocateLastReadPosition`、`objcCompleteLastReadPositionLocation`，以及仅被它们引用的私有辅助。
- `NEChatUIKitObjCModels.swift`：删除 `LastReadPositionStateKindObjC`、`LastReadPositionStateObjC` 及其 `kind` / `snapshot` 属性与 initializer。当前仓库中它们只被上述适配器引用，删除后无其他引用；不得为了"兼容"保留空壳。
- `NEChatUIKitObjCBridge.swift`：不承担本功能兼容职责；若业务版本中在该文件出现 Last Read 声明，同样删除。
- 若删除后仍有其他功能引用这些类型（后续版本可能变化），以 `grep -rn "LastReadPositionStateObjC" NEChatUIKit` 的实际结果为准，只保留其他功能仍在用的最小集合，并在提交说明中写明。

## Cross-Feature Content

`ChatViewController.swift` 中 Reaction reload 的底部固定逻辑曾增加 `!isLocatingLastReadPosition` guard。移除 Last Read 时只删除该 guard，不得删除 Reaction 队列。反过来移除 Reaction 时也不得删除 Last Read 定位流程。

## Closed And Out Of Scope

- 不搜索、不打开、不修改 `NEChatKit/`。`NELastReadPositionService` 和 `enableLastReadPosition` 均视为闭源能力。
- UI/Demo 中对上述能力的 import、状态、回调和调用必须删除；闭源符号定义保留不动。
- 不扫描或修改 Objective-C 或 SwiftUI 工程。

## Verification

交叉边界：保留 `NEChatViewport`、`applyViewport` 和窗口宽度变化引起的通用布局失效；只移除本功能的测量/布局分支。可选 adaptive shell 的 Router 接线属于独立 `adaptive-shell` 清单，不随本功能删除。

1. `audit_inventory.py earliest-unread --phase after` 不允许任何残留：ObjC 兼容层（`NEChatUIKitObjCChat.swift`、`NEChatUIKitObjCModels.swift`）随功能一并删除，审计不得出现 allowed 残留。
2. Swift UIKit 本地化文件不再包含三个 `last_read_position_*` key。
3. `git diff --check` 通过；对修改的 Swift 文件运行 `swiftc -frontend -parse` 或构建 `NEChatUIKit`。
4. 运行时检查 NormalUI/FunUI：聊天页无最早未读入口；顶部置顶、回到底部、多选、历史分页、Reaction 更新仍正常。
5. 最终业务 diff 只能位于 `NEChatUIKit/` 和 `app/`；只有真实 Demo 源码/资源引用需要时才允许 `app.xcodeproj/`。
