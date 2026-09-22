# Feature Registry

当前清单以承载本技能的源码仓库根目录为相对路径基准，只覆盖正式发布的 `NEChatUIKit/` 和 Demo `app/`。复制或发布本技能时，目录结构应保持为 `skills/swift-feature-removal/`，审计脚本即可从自身位置识别仓库根目录。

| Slug | 用户名称与别名 | 默认范围 | 清单 |
| --- | --- | --- | --- |
| `emoji-reaction` | 表情评论、Reaction、Emoji Reaction、快捷表情评论 | Swift UIKit + Swift Demo | [features/emoji-reaction.md](features/emoji-reaction.md) |
| `earliest-unread` | 跳转最早未读、最早未读、上次阅读位置、Last Read Position | Swift UIKit + Swift Demo | [features/earliest-unread.md](features/earliest-unread.md) |

`NEChatKit` 是闭源组件，禁止纳入扫描、清单或修改。仓库中的 `IMUIKit/` 是旧副本，也不得作为发现、审计或修改目标；Objective-C 和 SwiftUI 工程同样不属于这个 Swift 技能。用户使用“移除...功能”“去掉...功能”“删除...功能”等表达并命中上表名称或别名时，应自动调用本技能。
