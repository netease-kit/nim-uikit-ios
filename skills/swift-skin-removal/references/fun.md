# 移除 FunUI（微信/娱乐风格），保留 NormalUI

下列路径相对源码根；完整路径枚举及定向审计见 `skin-inventory.json`。按清单处理，不要重扫全仓。审计输出中的 `MOVED`、`PROJECT REFS clean` 和 `KEEP` 是预期成功状态。

## 专属删除项

- `NEBaseUIKit` 的 `Classes/FunUI/` 和 `FunBaseUI.xcassets`；五个 UI 组件的 `Classes/FunUI/` 与各自 `FunChatUIKit.xcassets`、`FunContactUIKit.xcassets`、`FunConversationUIKit.xcassets`、`FunLocalConversationUIKit.xcassets`、`FunTeamUIKit.xcassets`。保留公共 `NEBase*.xcassets` 与 Normal 目录。
- Demo `app/Custom/CustomFunChatViewController.swift`；`app/Assets.xcassets/Tabbar/funChat/funChatSelect/funContact/funContactSelect/funPerson/funPersonSelect.imageset`；`Mine/clicked_fun.imageset`、`Mine/style_fun.imageset`。
- 删除样式选择页面两个 Swift 文件和它们以及 `CustomFunChatViewController.swift` 的 `app.xcodeproj/project.pbxproj` 四处引用（file reference、build file、group、Sources），移除设置页入口。`Mine/unclicked.imageset` 只在选择页无别处引用时删。

## 必须编辑的接线

- `app/Main/UIStyleManager.swift` 兼容 `isNormalStyle()` 固定返回 `true`，旧 `UserDefaults` 值为 2 也必须启动存活皮肤；`SceneDelegate.swift` 固定 `setupInit(isFun: false)`，只注册 `registerNormalCustom()`，移除 Fun 自定义聊天路由；`NETabBarController.swift` 只保留 Normal 分支；`Constant.swift` 的样式缓存键与通知若不再使用可删。
- `app/Mine/ViewModel/MineSettingViewModel.swift` 删除皮肤选择数据行及 `didStyleClick` 委托，`MineSettingViewController.swift` 删除跳转；`MeViewController.swift` 保留 Normal 收藏入口；`app/Custom/CustomConfig.swift`、其他 `Mine/Controller/` 和 `Mine/View/Theme/` 中的二分支只保留 Normal；本地化 `style_selection`、`style_default`、`style_fun` 需清理。`ConfigTestViewController.swift` 仍发出 `CHANGE_UI` 以刷新全局配置，不能未经确认就删掉这条通知。
- 五个 UI 服务的 `registerRouter` 固定普通 `register()`，保留共享初始化和需要兼容的 `setupInit` 入参；`ChatMessageHelper.swift` 三张 cell 注册表只保留 Normal 类型，保留兼容入口时忽略 `isFun`，ObjC wrapper 仍须能调用。`NEChatUIKitClient.swift` 当前在共享默认按钮中加载 `fun_chat_photo`、`fun_chat_aiChat`，先替换为仍存在的公共 `NEBaseChatUIKit.xcassets/Chat/photo.imageset` 和 Normal 的 `NormalChatUIKit.xcassets/Chat/AIChat/ai_icon_default.imageset`（结合 UI 效果确认适合）；没有可用图时把必需图片迁到公共目录并改为中性名称。`ChatCellConstantValue.swift` 的 `fun_chat_min_h`、`fun_chat_reply_height` 及 ObjC bridge 只有在仍有存活调用者或明确外部兼容要求时才保留，否则随 FunUI 一起删除。
- `NEConversationGroupUIStyle.swift` 只保留 `.normal`，调整组管理/添加/设置/Bar 及 `NEBaseConversationController.swift`；检查 `SelectLanguageViewModel.swift`、收藏 cell 的 `setFunStyle()` 以及 Chat/Contact 基类的 Fun 专属默认值。共享聊天历史搜索 `NEHistorySearchFileCell.swift`、`NEHistorySearchMonthHeaderView.swift` 引用 `.funChatLineBorderColor`，联系人 AI 基类引用 `.funContactLineBorderColor` / `.funContactNavigationBackgroundColor`；这些定义在被删除的 Fun 色值文件中，必须改为存活颜色。NormalUI 的 `CreateAIRobotController.swift` 自身也引用 `.funContactNavigationBackgroundColor`，需定点编辑这一个存活皮肤文件。`TranslationSettingViewController.swift` 的 `FunTranslation*Cell` 继承 FunTeam cell，删除 Fun 分支时一并去掉；共用基类不能删。`NEBaseTeamRouter.swift` 的 `iconUrlsFun` 清理前确认不再有调用。JSON 中登记了这些共享编辑文件。
- `NEBaseUIKit/Classes/FunUI/FunSearchView.swift` 中的 `SearchSessionBaseView` 是 NormalUI 搜索头部仍使用的共享类型；移除 FunUI 时将它迁移到 `NEBaseUIKit/Classes/CommonView/SearchSessionBaseView.swift`，而不是随目录删除。该迁移已登记在 `skin-inventory.json`，审计 `--phase after` 必须输出 `MOVED`。
- 本仓库当前没有存活代码调用 `fun_chat_min_h`、`fun_chat_reply_height` 或 `NEChatUIKitObjCBridge` 的 Fun 对应属性，因此移除 FunUI 时一并删除这些 Fun 专属公开符号；只有确认存在外部兼容约束时，才将具体符号登记为 `accepted_candidates`。

## 不得删除

`NEBase*.xcassets` 与 app 通用图片不能按色调删除；`NEBaseTeamUIKit.xcassets/common/clear_btn.imageset` 虽然内部文件叫 `fun_clear_btn@2x/3x.png`，仍是共用 asset，不随 Fun 目录整体删除。`NECommonUIKit/` 不在 Podfile 的活跃皮肤依赖链。`Common/NECommonUIKit/`、`IMUIKit/`、闭源 `NEChatKit` 不在本次移除范围。移除后其他 ObjC/SwiftUI 工程仍可能维护 FunUI，不能因同名追删。
