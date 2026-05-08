# NEChatKit Changelog

## 10.9.25(2026-5-8)
### New Features
* ChatRepo 新增消息翻译相关接口

## 10.9.20(2026-4-10)
### New Features
* 新增 NEAIRobotManager 机器人缓存管理器，支持全量加载、单条增删改查、异步精确判断机器人账号
* 新增 AIRepo 机器人相关接口（getUserAIBotList、getUserAIBot 等）
* ChatRepo、ContactRepo、ConversationRepo、TeamRepo 新增多个 API 接口

## 10.8.8(2025-11-21)
### New Features
* IMKitConfigCenter 新增配置项 enableAntiSpamTipMessage，控制是否插入反垃圾提示消息

## 10.8.7(2025-10-17)
### New Features
* OperationType 新增 .earpiece（听筒）、.speaker（扬声器）
### Behavior changes
* SettingRepo 新增推送配置设置、获取接口
* ChatRepo 的消息推送配置默认从 SettingRepo 中取
* IM SDK 升级至 10.9.51

## 10.8.6(2025-9-5)
### Behavior changes
* 优化获取本人账号信息逻辑，避免重复获取

## 10.8.4(2025-8-20)
### Behavior changes
* beforeSend return nil 时逻辑优化
* 登录状态变更回调移至各管理、缓存类内部

## 10.8.3(2025-7-3)
### New Features
* 新增收到撤回通知插入本地提示消息逻辑和开关 enableInsertLocalMsgWhenRevoke

## 10.8.2(2025-6-30)
### New Features
* 新增是否展示群聊入群申请配置
* TeamRepo 新增申请加入群组接口 applyJoinTeam
* TeamRepo 新增更改群组申请入群模式接口 updateTeamJoinMode
* TeamRepo 新增更改群组被邀请人同意入群模式接口 updateTeamAgreeMode
* TeamRepo 新增获取群加入相关信息接口 getTeamJoinActionInfoList
* TeamRepo 新增清空所有入群申请接口 clearAllTeamJoinActionInfo
* TeamRepo 新增同意邀请入群接口 acceptInvitation
* TeamRepo 新增拒绝邀请入群请求接口 rejectInvitation
* TeamRepo 新增接受入群申请请求接口 acceptJoinApplication
* TeamRepo 新增拒绝入群申请接口 rejectJoinApplication
### Behavior changes
* 配置发送消息默认 pushConfig，包含 "sessionId"、"sessionType"

## 10.8.1(2025-6-13)
### New Features
* 新增回复消息接口
### Behavior changes
* 回复消息默认使用 thread 方案

## 10.8.0(2025-4-27)
### New Features
* 新增群可添加管理员人数配置项，默认 10
* 新增流式消息类型：MessageType.aiStreamText
* 新增消息流式开关，默认开启
* 新增消息流式相关接口

## 10.6.1(2025-3-26)
### Behavior changes
* 移除本地开关 enableLocalConversation，采用SDK参数 

## 10.6.0(2025-2-19)
### New Features
* 新增本地会话接口

## 10.5.3(2025-1-13)
### New Features
* 新增本端发送消息接口的全局回调 sendMessageCallback，可在回调中获取消息反垃圾结果

## 10.5.0(2024-12-9)
### New Features
* 新增语音转文字接口

## 10.4.0(2024-11-1)
### New Features
* 新增消息发送前回调，可在消息发送前修改消息、更改发送配置或者拦截发送

## 10.3.0(2024-07-15)
### New Features
* 新增数字人接口

## 10.0.0(2024-05-23)
### New Features
* 升级SDK V2 接口

## 9.7.0(2024-1-25)
### New Features
* 新增用户信息缓存类，可先于 SDK 回调刷新 UI
* 新增获取用户信息接口(旧的接口只能获取本地用户信息，新增接口本地查询不到会再次向服务端查询)
* 新增批量删除消息接口
* 新增查询最近会话接口
* 新增添加空白会话接口
* 删除某个会话的所有本地和云端的历史消息。删除后，查询云端消息历史的接口将不能返回这些消息
* 新增移除管理员接口
* 新增添加管理员接口
* 新增移除群成员接口

### Behavior changes
* User对象添加前缀，类名变更为NEKitUser，防止与用户类名冲突
* XNotification 类名变更为 NENotification
* AddFriendRequest 类名变更为 NEAddFriendRequest

### Bug Fixes



## 9.6.3(Nov 06, 2023)

### Behavior changes
- repo 层提供单例 shared，不提供实例化接口
### New Features

## 9.6.x(2023-)
### Behavior changes
* repo 层提供单例 shared，不再允许调用实例化方法

## 9.6.0(2023-07-05)
### Behavior changes
* NEContactKit NETeamKit NEConversationKit Repo 合并到此Kit，其他Kit废弃
* ConversationRepo().searchContact(searchStr:)搜索通讯录群聊默认不再匹配群ID

## 9.5.0(2023-04-20)
### New Features
* 新增获取所有pin消息列表接口

9.3.1(2023-1-05)
    - FIXED    修复 NEMapKit 组件的已知问题。

9.3.0(2022-12-05)
    - NEW    新增地理位置消息功能，具体实现方法参见实现地理位置消息功能。
    - NEW    新增文件消息功能（升级后可直接使用）。
    - FIXED    修复更新讨论组/高级群头像失败的问题。
    - FIXED    修复发送视频消息未显示首帧的问题。
    - FIXED    修复表情和文案不一致的问题。
    - FIXED    修复“正在输入中”的显示问题。
    - FIXED    修复群聊消息已读按钮失效的问题。
    - FIXED    修复其他已知问题。

9.2.11(2022-11-17)
    - UPDATE   NIM SDK 版本升级到 V9.6.4    
    - FIXED    修复好友名片中未显示基本信息的问题。
    - FIXED    修复视频消息加载问题。
    - FIXED    修复更新自己群昵称失败的问题。
    - FIXED    修复加入他人圈组服务器的按钮失效问题。
    - FIXED    修复圈组频道成员列表和频道黑白名单成员列表的展示问题。
    - FIXED    修复无法退出图片详情页的问题。
    - FIXED    修复历史图片未展示缩略图的问题。
    - FIXED    修复黑名单成员列表头像与好友头像不一致的问题。
    - FIXED    修复其他已知问题。

9.2.10(02-November-2022)
    - FIXED    修复xcode 14编译错误问题

9.2.9(25-August-2022)
    - NEW      iOS新增自定义用户信息功能。
    - changed  IMKitEngine类中功能迁移至IMKitClient
    - FIXED    修复OC工程调用UI库失败问题
    - FIXED    统一接口层API
    - FIXED    修复已知bug

9.2.8(19-September-2022)
    - NEW    多语言能力支持
    - FIXED  相机权限修改
    - FIXED  历史遗留bug修改

9.2.7(25-August-2022)
    - FIXED  修复 Swift 版本编译问题。
    - FIXED  修复相册选择图片时图片展示问题。
    - FIXED  修复圈组频道身份组权限信息展示问题。

9.2.6-rc01(02-August-2022)
    - FIXED  修复导航控制器push 页面 页面卡顿问题
    - FIXED  修改错误emoji表情问题。
    - FIXED  统一log命名->NELog
    - FIXED  好友名片页去掉消息提醒开关
    - FIXED  修复app端修改群组头像 web端不能展示问题
    - FIXED  统一podspec依赖，三方库不设置固定版本
    - NEW    添加Conversationrepo chatrepo 注解
    - NEW    新增userInfoProvider功能类

9.2.4(28-June-2022)
    - FIXED  修复客户反馈chat页面，无消息时下拉崩溃，新建群组下拉消息重复。
    - FIXED  router路由对齐，contact主页面设置open。
    - FIXED  修改Toast提示信息位置
    - NEW    补充自定义消息逻辑

9.2.1(20-July-2022)
    - FIXED  低版本xcode编译低版本的包（xcode 13.2.1）

9.0.2(29-May-2022)
    - FIXED  修复NEConversationUIKit,NEChatUIKit,NETeamUIKit,NEQChatUIKit,NEContactUIKit中作用域问题。

9.0.1(19-May-2022)
    - NEW  我的->个人信息页 新增copy账号功能
    - FIXED 修复头像被压缩问题
    - FIXED 发送视屏压缩模糊问题修复
    - FIXED 修复搜索框背景色,高度问题，修复会话列表首页弹窗阴影过重问题，修复alert弹窗色值问题，修复通讯录icon失真问题...
    - FIXED 更新会话列表logo&title
    - FIXED 修复圈组聊天页键盘偶现不能弹起问题。
    - FIXED 修复图片预览被压缩变形问题

9.0.0(09-May-2022)
    - NEW  swift新版本IM发布,包含消息，圈组，通讯录，我的版块。
9.3.1(2023-1-05)
- FIXED    修复 NEMapKit 组件的已知问题。
9.3.0(2022-12-05)
- NEW    新增地理位置消息功能，具体实现方法参见实现地理位置消息功能。
- NEW    新增文件消息功能（升级后可直接使用）。
- FIXED    修复更新讨论组/高级群头像失败的问题。
- FIXED    修复发送视频消息未显示首帧的问题。
- FIXED    修复表情和文案不一致的问题。
- FIXED    修复“正在输入中”的显示问题。
- FIXED    修复群聊消息已读按钮失效的问题。
- FIXED    修复其他已知问题。
9.2.11(2022-11-17)
- UPDATE   NIM SDK 版本升级到 V9.6.4
- FIXED    修复好友名片中未显示基本信息的问题。
- FIXED    修复视频消息加载问题。
- FIXED    修复更新自己群昵称失败的问题。
- FIXED    修复加入他人圈组服务器的按钮失效问题。
- FIXED    修复圈组频道成员列表和频道黑白名单成员列表的展示问题。
- FIXED    修复无法退出图片详情页的问题。
- FIXED    修复历史图片未展示缩略图的问题。
- FIXED    修复黑名单成员列表头像与好友头像不一致的问题。
- FIXED    修复其他已知问题。
9.2.10(02-November-2022)
- FIXED    修复xcode 14编译错误问题
9.2.9(25-August-2022)
- NEW      iOS新增自定义用户信息功能。
- changed  IMKitEngine类中功能迁移至IMKitClient
- FIXED    修复OC工程调用UI库失败问题
- FIXED    统一接口层API
- FIXED    修复已知bug
9.2.8(19-September-2022)
- NEW    多语言能力支持
- FIXED  相机权限修改
- FIXED  历史遗留bug修改
9.2.7(25-August-2022)
- FIXED  修复 Swift 版本编译问题。
- FIXED  修复相册选择图片时图片展示问题。
- FIXED  修复圈组频道身份组权限信息展示问题。
9.2.6-rc01(02-August-2022)
- FIXED  修复导航控制器push 页面 页面卡顿问题
- FIXED  修改错误emoji表情问题。
- FIXED  统一log命名->NELog
- FIXED  好友名片页去掉消息提醒开关
- FIXED  修复app端修改群组头像 web端不能展示问题
- FIXED  统一podspec依赖，三方库不设置固定版本
- NEW    添加Conversationrepo chatrepo 注解
- NEW    新增userInfoProvider功能类
9.2.4(28-June-2022)
- FIXED  修复客户反馈chat页面，无消息时下拉崩溃，新建群组下拉消息重复。
- FIXED  router路由对齐，contact主页面设置open。
- FIXED  修改Toast提示信息位置
- NEW    补充自定义消息逻辑
9.2.1(20-July-2022)
- FIXED  低版本xcode编译低版本的包（xcode 13.2.1）
9.0.2(29-May-2022)
- FIXED  修复NEConversationUIKit,NEChatUIKit,NETeamUIKit,NEQChatUIKit,NEContactUIKit中作用域问题。
9.0.1(19-May-2022)
- NEW  我的->个人信息页 新增copy账号功能
- FIXED 修复头像被压缩问题
- FIXED 发送视屏压缩模糊问题修复
- FIXED 修复搜索框背景色,高度问题，修复会话列表首页弹窗阴影过重问题，修复alert弹窗色值问题，修复通讯录icon失真问题...
- FIXED 更新会话列表logo&title
- FIXED 修复圈组聊天页键盘偶现不能弹起问题。
- FIXED 修复图片预览被压缩变形问题
9.0.0(09-May-2022)
- NEW  swift新版本IM发布,包含消息，圈组，通讯录，我的版块。
