# 移除 NormalUI（飞书/通用风格），保留 FunUI

下列路径相对源码根；完整路径枚举及定向审计见 `skin-inventory.json`。按清单处理，不要重扫全仓。审计输出中的 `PROJECT REFS clean` 和 `KEEP` 是预期成功状态。

## 专属删除项

- 五个业务 UI 组件各自的 `Classes/NormalUI/`（`NEBaseUIKit` 没有此目录），及基础 UI 的 `NormalBaseUI.xcassets`、其余五个组件的 `NormalChatUIKit.xcassets`、`NormalContactUIKit.xcassets`、`NormalConversationUIKit.xcassets`、`NormalLocalConversationUIKit.xcassets`、`NormalTeamUIKit.xcassets`。保留相邻 `NEBase*.xcassets` 和 Fun 目录。
- Demo `app/Custom/CustomNormalChatViewController.swift`；`app/Assets.xcassets/Tabbar/` 的 `chat/chatSelect/contact/contactSelect/person/personSelect.imageset`；`Mine/clicked_normal.imageset`、`Mine/style_normal.imageset`。`Mine/unclicked.imageset` 是选择组件通用态，仅在整个选择页删除后才能删。
- Demo 的 `StyleSelectionViewController.swift`、`StyleSelectionCell.swift` 可在双皮肤选择入口撤除后删除（两种移除方向通用），同时删 `app.xcodeproj/project.pbxproj` 对上述 3 个 Swift 文件的 file reference、build file、group、Sources 条目。只移除目标类型和样式选择页，不删保留皮肤的配置页。

## 必须编辑的接线

- `app/Main/UIStyleManager.swift`：保留 `isNormalStyle()` 的兼容调用可固定返回 `false`；禁止旧 `UserDefaults` 的值为 1 时重新选中已删除皮肤。`app/Main/Constant.swift` 的 `IMUIKit_Style_Key` 和 `CHANGE_UI` 只有不再有其他用户后才删；`SceneDelegate.swift` 的 `loadService` 固定 `setupInit(isFun: true)`，只注册 `registerFunCustom()`，移除 `registerNormalCustom()` 和样式切换通知/刷新逻辑中不再需要的部分；`NETabBarController.swift` 保留 Fun 分支。已有客户集成用到的 `setupInit` 参数签名不要猜测改变。
- `app/Mine/ViewModel/MineSettingViewModel.swift` 撤销样式选择数据行及 `didStyleClick` 委托、`MineSettingViewController.swift` 撤销跳转；`MeViewController.swift` 保留 Fun 收藏入口。`app/Custom/CustomConfig.swift`、`Mine/Controller/` 下已登记的其他样式判断及 `Mine/View/Theme/` 的适配 cell 改为 Fun 样式；移除选择页后清理 `style_selection`、`style_default`、`style_fun` 文案。`ConfigTestViewController.swift` 仍通过 `CHANGE_UI` 触发全局配置刷新，不能只因移除皮肤选择器就删整个通知。
- 五个 UI 服务 `NEChatService`、`NEContactService`、`NEConversationService`、`NELocalConversationService`、`NETeamService` 的 `registerRouter` 保留现有 API 但固定注册 `registerFun()`；保留会话 @ 消息初始化和聊天表情初始化等共享业务。`ChatMessageHelper.swift` 的聊天/标记/收藏三张 cell 注册表只保留 Fun 类型，兼容 `isFun` / ObjC wrapper 入参时仍返回存活的类型。
- `NEConversationGroupUIStyle.swift` 只保留 `.fun` 所需值；其 `NEConversationGroupAddConversationController.swift`、`NEConversationGroupManageController.swift`、`NEConversationGroupSettingController.swift`、`NEConversationGroupBar.swift` 清理 `.normal` 默认值和二选一渲染；同时检查登记的 `NEBaseConversationController.swift` 初始化样式。`NEChatUIKitClient.swift` 中 Fun 图片是存活皮肤资源，勿误删。
- `NEChatUIKit` 的日期选择/历史搜索 (`normalSearchDateButtonBg`, `normalChatNavigationDivideBg`)、`ReplyView.swift` (`normalChatReplyViewBg`) 在共享源码引用 Normal 专属颜色，需换成保留皮肤的 UI 值；共享 `ChatCellConstantValue.swift`、`MessageContentModel.swift`、`MessageTextModel.swift`、`NEBaseChatMessageCell.swift` 中的专属布局/注释须核对。
- `NEContactUIKit` 的 AI Robot 基类和多选基类 `NEBaseSelectCell.swift` / `NEBaseMultiSelectViewController.swift` 默认引用 `normalContactThemeColor`，该颜色定义随 Normal 目录删除后必须替换为保留皮肤的颜色/稳定公共值，不能直接删基类；`NETeamUIKit/Classes/Base/NEBaseTeamRouter.swift` 的 `iconUrlsFun` 要保留。详见 JSON 列出的共享编辑文件。

## 不得删除

`isNormalTeam()` 是普通群判断，`MJRefreshNormalHeader` 是第三方类型，UIKit 的 `.normal` 是控件状态，`NIMKit_ChartletChartletCatalogIconsSuffixNormal` 是表情包资源协议；都与 NormalUI 皮肤删除无关。公共 `NIMKitEmoticon.bundle/Emoji/*_normal@2x.png` 和 `NEBaseChatUIKit.xcassets/Map/map_reset_normal.imageset` 是表情/地图状态资源，保留。`Common/NECommonUIKit/`、`IMUIKit/` 和闭源 `NEChatKit` 不在此清单。`FunUI` 的 `restoreNormalInputStyle`、`setRecordNormalStyle` 是录音/输入状态方法，不是 NormalUI 皮肤依赖。
