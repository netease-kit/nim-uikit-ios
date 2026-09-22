# Emoji Reaction Removal Inventory

## Boundary

移除范围只包括开源仓库 `nim-uikit-ios` 的 `NEChatUIKit/` 和 Demo `app/` 中的“表情评论”。`NEChatKit` 是闭源组件，禁止扫描或修改；只移除 UI/Demo 对其 Reaction API 的接线。旧 `IMUIKit/` 副本、Objective-C 和 SwiftUI 工程不属于本技能。

核心名称包括 `MessageReaction*`、`NEMessageReaction*`、`reactionGroups`、`reactionHeight`、`enableEmojiReaction`、Quick Comment。

## Delete Entirely

删除以下 Swift UIKit 专属路径：

- `NEChatUIKit/NEChatUIKit/Classes/Chat/View/Cell/Reaction/NEMessageReactionView.swift`
- `NEChatUIKit/NEChatUIKit/Assets/reaction_emoji/`，共 112 组 `1x/2x/3x` PNG
- `NEChatUIKit/NEChatUIKit/Assets/NEBaseChatUIKit.xcassets/operation/reaction_add_emoji.imageset/`
- `NEChatUIKit/NEChatUIKit/Assets/NEBaseChatUIKit.xcassets/operation/reaction_more_emoji.imageset/`
- `NEChatUIKit/NEChatUIKit/Assets/NEBaseChatUIKit.xcassets/operation/reaction_less_emoji.imageset/`

## Remove Demo Entries

- `app/Mine/Controller/ConfigTestViewController.swift`：删除 `showEmojiReaction` 配置块。
- `app/en.lproj/Localizable.strings`：删除 `emoji_reaction`。
- `app/zh-Hans.lproj/Localizable.strings`：删除 `emoji_reaction`。

本功能没有需要修改的 Demo 工程文件或依赖；不得因移除本功能修改 `app.xcodeproj/` 或 `Podfile`。

## Remove Swift UIKit Wiring

### Controller And ViewModel

- `ChatViewController.swift`
  - 删除 Reaction reload 队列字段：`pendingReactionReloadIndexPaths`、`isReactionReloadScheduled`、`isReactionReloadInProgress`、`keepsBottomPinnedForPendingReactionUpdates`。
  - 删除面板配置：`reactionPanelQuickIndexes`、`reactionShortcutIndexes`、`reactionErrorMessage`、`supportsReactionConversation`。
  - 删除 lifecycle 中 `startReactionManager` / `stopReactionManager`。
  - 删除长按面板 Reaction 配置、选择回调、`presentReactionPanel`、`showReactionError`。
  - 删除 `onReactionModifiedMessage`、`scheduleReactionReloadIfNeeded`、`flushPendingReactionReloads`、`finishPendingReactionReloads`、`cancelPendingReactionBottomPinning` 及其调用。
  - 保留普通长按菜单、回到底部、初始消息详情加载和最早未读定位；删除交叉 guard 时恢复这些流程的非 Reaction 路径。
- `ChatViewModel.swift`
  - 从 delegate 删除 `onReactionModifiedMessage`。
  - 删除 `reactionManager`、`setupReactionManager`、start/stop/load/apply Reaction 方法和 `NEMessageReactionObserver` 实现。
  - 删除发送成功、历史加载、消息更新中的 Reaction load/apply 调用，但保留原消息加载/发送完成逻辑。
- `NEBaseHistorySearchController.swift`：删除为隐藏搜索结果 Reaction 添加的 `viewModel.stopReactionManager()`；不要改变关键词/群成员搜索其他行为。

### Model And Operation Panel

- `MessageContentModel.swift`：删除 `reactionGroups`、`reactionHeight`、`hasReaction` 及撤回/复用时的 Reaction 清理；保持原始 `height` 计算和撤回状态。
- `MessageOperationView.swift`：删除 Reaction strip 的常量、collection views、展开按钮、provider/items、`configureReactions`、Reaction data source/delegate 分支和 `MessageReactionEmojiCell`。普通 operation grid 必须恢复为唯一布局来源。
- `NEChatUIKitObjCBridge.swift`：删除 `NEChatUIKitReactionProviderAdapter` 及 `MessageOperationView.objcConfigureReactions` 扩展。不要进入闭源组件追删其公开类型。

### Base Message Cell

在 `NEBaseChatMessageCell.swift` 删除完整 Reaction surface，而不是只隐藏：

- `NEMessageReactionViewDelegate` 遵循关系与 delegate 方法。
- `reactionViewLeft/Right`、`reactionBackdropLeft/Right`、所有 Reaction constraints 和尺寸缓存。
- `reactionTopAnchor*`、`reactionBackdrop*`、`reactionContent*` 等锚点。
- `supportsReactionLongPress`、`usesInlineReactionSurface`、`reactionTopSpacing`、`reactionBottomSpacing`、`reactionHorizontalInset` 等 overridable hooks。
- `configureReaction*`、`layoutReaction*`、`updateReaction*`、`resetReactionSurfaceForReuse`、backdrop image/copy helpers。
- Reaction 对 cell height、气泡宽高、已读状态位置、复用、撤回和长按手势的附加逻辑。

恢复布局时以无 Reaction 分支为基准，不能留下固定空白、透明 backdrop 或悬空约束。

### NormalUI

以下文件删除所有 `reaction*` override、Reaction 高度/宽度计算、backdrop 更新、bringSubview 和复用清理，同时保留各消息类型原有气泡、翻译、语音转文字、已读状态和点击行为：

- `Classes/NormalUI/Cell/NormalChatMessageBaseCell.swift`
- `Classes/NormalUI/Cell/ChatMessageTextCell.swift`
- `Classes/NormalUI/Cell/ChatMessageRichTextCell.swift`
- `Classes/NormalUI/Cell/ChatMessageAudioCell.swift`
- `Classes/NormalUI/Cell/ChatMessageImageCell.swift`
- `Classes/NormalUI/Cell/ChatMessageVideoCell.swift`
- `Classes/NormalUI/Cell/ChatMessageCallCell.swift`
- `Classes/NormalUI/Cell/ChatMessageMultiForwardCell.swift`
- `Classes/NormalUI/Cell/ChatMessageRevokeCell.swift`

上述路径均相对于 `NEChatUIKit/NEChatUIKit/`。

### FunUI

按相同原则处理：

- `Classes/FunUI/Cell/FunChatMessageBaseCell.swift`
- `Classes/FunUI/Cell/FunChatMessageTextCell.swift`
- `Classes/FunUI/Cell/FunChatMessageRichTextCell.swift`
- `Classes/FunUI/Cell/FunChatMessageAudioCell.swift`
- `Classes/FunUI/Cell/FunChatMessageImageCell.swift`
- `Classes/FunUI/Cell/FunChatMessageVideoCell.swift`
- `Classes/FunUI/Cell/FunChatMessageFileCell.swift`
- `Classes/FunUI/Cell/FunChatMessageLocationCell.swift`
- `Classes/FunUI/Cell/FunChatMessageCallCell.swift`
- `Classes/FunUI/Cell/FunChatMessageMultiForwardCell.swift`
- `Classes/FunUI/Cell/FunChatMessageRevokeCell.swift`

FunUI 必须恢复其微信气泡 tail、媒体遮罩和文本内边距，不要用 NormalUI 数值替换。

`OperationCell.swift` 的 plugin 文案缩放、两个 `ChatMessageAIStreamTextCell.swift` 的 topic regenerate 隐藏、`SceneDelegate.swift` 的会话分组/QA 路由都不是 Reaction 功能，必须保留。

## Closed And Out Of Scope

- 不搜索、不打开、不修改 `NEChatKit/`。`MessageReactionManager`、`enableEmojiReaction`、Reaction 专属 Quick Comment wrapper、事件转发及颜色 token 均视为闭源能力。
- UI/Demo 中对上述能力的 import、属性、回调和调用必须删除；闭源符号定义保留不动。
- 当前开源基线 `ChatViewModel` 中已有通用 Quick Comment 通知日志。不要仅因出现 `quickComment` / `QuickComment` 就删除；只有清单点名的 Reaction UI 接线才属于本功能。
- 不扫描或修改旧 `IMUIKit/` 副本、Objective-C 或 SwiftUI 工程。

## Verification

1. `audit_inventory.py emoji-reaction --phase after` 无非允许残留。
2. Swift UIKit 资源目录中不再有 `reaction_emoji` 和三个 operation imageset。
3. `git diff --check` 通过；对修改的 Swift 文件运行 `swiftc -frontend -parse` 或构建 `NEChatUIKit`。
4. 运行时检查 NormalUI/FunUI：普通长按菜单无 Reaction 区域；文本、富文本、语音转文字、图片、视频、文件、位置、合并转发、撤回、话单、AIStream 无额外空白或复用残影。
5. 最终业务 diff 只能位于 `NEChatUIKit/` 和 `app/`；只有真实 Demo 源码/资源引用需要时才允许 `app.xcodeproj/`。
