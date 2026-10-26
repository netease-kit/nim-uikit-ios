# Adaptive Shell 可选接线移除清单

## 范围

本清单仅覆盖开源根目录的 `NEChatUIKit/` 和 `app/` 中自适应呈现接线。没有本范围内的整文件删除项。此登记不授权删除 `NEAdaptiveUIKit/`、云端/本地会话组件或其他 UIKit；这些组件的接入与依赖由客户在明确的额外范围中处理。不扫描闭源 `NEChatKit`、旧副本、OC 或 SwiftUI。

## 局部编辑

- `app/Main/NETabBarController.swift`：移除 `NEAdaptiveUIKit` import、`NEAdaptiveDemoNavigationController` 的 root push 前置接线及 `presentSectionChild` 绑定/解绑、`adaptiveShell`、`installAdaptiveShell`、`restoreLegacyShell`、`makeAdaptiveConversation`、`makeAdaptiveEmptyDetail`、配置（包含 railBackTopInset 返回位置）、onContentLayout 中根列表 listSelectionBackgroundColor 绑定、updateTableContentInsets 接线及旧布局恢复时的清理和绑定/解绑；恢复原三个导航栈的 tab 宿主。保留原 unread/contact/team listener、皮肤资源、角标、语言更新及旧路由行为。
- `app/Main/SceneDelegate.swift`：移除 shell window refresh 与通知入口选择 shell section；通知使用原 tab 消息导航栈。保留呼叫的模拟器编译保护、登录和通知业务逻辑。
- `app/en.lproj/Localizable.strings`、`app/zh-Hans.lproj/Localizable.strings`：删除 `adaptive_back`，保留既有返回文案。
- `NEChatUIKit/NEChatUIKit/Classes/ChatRouter/NEBaseChatRouter.swift`：移除 `NEConversationPresentationBlock`、关联对象 key、`setConversationPresentationHandler`、`presentConversationIfHandled`、`applyPresentationParameters`。保留 registerCommon 与原业务路由。
- `NEChatUIKit/NEChatUIKit/Classes/NormalUI/NormalChatRouter.swift`、`NEChatUIKit/NEChatUIKit/Classes/FunUI/FunChatRouter.swift`：删除四类默认会话路由开头的 optional presentation 拦截，完整保留默认 handler 创建、anchor、新消息恢复、旧栈回收以及客户 Router 覆盖机制。
- `NEChatUIKit/NEChatUIKit.podspec`：仅在确认本模块剩余源码没有实际依赖后删除 `NEAdaptiveUIKit` 依赖。其他依赖不变。

没有专属图片或 asset，没有新增 Demo Xcode 文件引用需要删除。

## 必须保留

`listSelectionBackgroundColor` 与 `ne_setSelectionBackgroundColor` 是默认关闭的通用列表样式能力，保留其实现，以及云端/本地会话和通讯录根页点击时保存稳定标识、刷新后在选中色非 nil 时恢复选中行的逻辑；只移除 Demo 外壳接线。该恢复不触发点击回调、路由或滚动，选中色为 nil 时不执行。资料表头、菜单 footer、网格及多选 tab 的父容器宽度约束属于通用响应式修复，不回滚。

`NEChatViewport`、`applyViewport`、宽度失效/重算、消息与衍生列表布局、键盘/safe-area/菜单/录音布局均是共享呈现能力，但 Demo 仅在 `NEAdaptiveDeviceGate.isFoldableDevice` 为真时启用其中的 Duo 分支；普通设备继续执行原有 legacy 计算和生命周期。删除 Reaction 或最早未读时同样保留这些能力及门禁。宿主横屏支持及 AppDelegate/Info.plist 方向声明、调用组件的 arm64 模拟器保护属于独立能力，不回滚。

云端/本地会话 `onOpenConversation` 是外部模块可选公开 hook，不在本 skill 范围；Demo 默认不直接安装此 hook，默认路由在注册 Router 执行之后捕获呈现，因此客户替换 handler 保持优先。删除完整功能前需客户明确外部模块清理范围，不得暗中扩展本技能。

## 验证

执行登记定向 before/after 审计、Swift 解析及构建；检查两皮肤的旧 tab、云端/本地会话、搜索/联系人/通知入口、自定义 Router 覆盖、旧栈返回与重复点击。检查通讯录/我的根导航恢复原 push，删除后不再调用 `presentSectionChild`；删除前 Medium/Expanded 启动即保持根页面/空详情双栏、打开子页面直接更新右栏、返回根页面保留双栏。编译不能替代实际运行。删除后不得留下本清单唯一指纹。通用 viewport 与外部模块不作为 required-remove 指纹。

只做局部删除，不整体 revert 历史提交。
