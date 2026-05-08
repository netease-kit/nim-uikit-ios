# NEConversationUIKit Changelog

## 10.9.25(2026-5-8)
* 跟随发版

## 10.9.20(2026-4-10)
### New Features
* 新增扫码功能（NEBaseScanQRViewController），支持 Normal/Fun 双主题
* 新增 scan_qr 图片资源
* 新增中英文国际化文案
### Behavior changes
* ConversationViewModel 优化
* NEBaseConversationController 优化

## 10.8.8(2025-11-21)
* 跟随发版

## 10.8.7(2025-10-17)
### Behavior changes
* 会话列表加载性能优化
  
## 10.8.6(2025-9-5)
### Behavior changes
* 优化会话排序规则，使用 sortOrder 排序

## 10.8.4(2025-8-20)
* 跟随发版

## 10.8.3(2025-7-3)
### Behavior changes
* 收到撤回通知插入本地提示消息逻辑下沉至 NEChatKit

## 10.8.2(2025-6-30)
### New Features
* 新增加入群组入口

## 10.8.1(2025-6-13)
### New Features
* 单聊（非数字人）新增在线状态

## 10.8.0(2025-4-27)
* 跟随发版

## 10.6.1(2025-3-26)
### Behavior changes
* 移除本地开关 enableLocalConversation，采用SDK参数 

## 10.5.0(2024-12-9)
### New Features
* 会话列表新增安全提示

## 10.4.0(2024-11-1)
### Behavior changes
* 自定义配置优化

## 10.3.0(2024-07-15)
### New Features
* 新增AI 数字人pin到顶部功能

## 10.0.0(2024-05-23)
### New Features
* 全量替换V2接口

# 9.6.4(2023-12-08)
### Behavior changes
* 添加是否显示创建群聊入口配置

## 9.6.3(Nov 06, 2023)

### Bug Fixes
- 修复删除会话后，未读数未清空的问题


## 9.6.0(2023-07-05)
### New Features
* 新增娱乐版UI
* 删除会话列表本地最近会话同时删除服务端最近会话
### Bug Fixes
* 多端登录其他端更改是否接受消息提醒会话列表动态变化

## 9.5.0(2023-04-20)
### New Features
* 会话列表页面新增消息已读回执的监听，用于刷新会话（目前只刷新 P2P 会话）
* 列表顶部新增 topView，可添加自定义 view
* 导航栏视图（navView）元素可自定义
* 支持自定义 cell 类型注册、解析

### Behavior changes
* "我的群聊"页面监听群信息更改和退出群事件，实时刷新
* 返回"通讯录"时从远端拉取好友信息，刷新本地数据

### Bug Fixes
* 修复多端登录下断网重连 会话置顶信息未同步的问题

## 9.4.0(2023-03-08)
### New Features
* conversationRepo 新增接口 clearAllUnreadCount()，用于清空所有未读数。    
### Bug Fixes
* 修复滑动搜索页面时搜索结果与“好友”等标签重叠的问题。
* 修复会话列表页好友昵称超长时未展示最后一条消息时间的问题。
* 修复单聊或群聊，免打扰和置顶打开，删除会话后，再接收消息时，免打扰和置顶会关闭的问题。
* 修复偶现会话icon上有小红点展示，但是会话列表没有会话有未读数展示的问题。
* 修复聊天消息列表，消息总数达到99+时，99+显示和群聊/讨论组/好友名称显示重叠的问题。
* 验证消息页面和好友资料页面、消息列表页面显示的头像逻辑对齐。
* 修复web端创建的群聊在移动端消息列表不会显示的问题。
* 首次登录或者切换账户会话列表数量异常优化。
* 修复未在最近会话列表中的群解散导致最近会话列表显示异常问题。
* 修复首次登录最近会话携带的last message错误问题。

## 9.3.1(2023-1-05)
*   - FIXED    修复 NEMapKit 组件的已知问题。

## 9.3.0(2022-12-05)
*   - NEW    新增地理位置消息功能，具体实现方法参见实现地理位置消息功能。
*   - NEW    新增文件消息功能（升级后可直接使用）。
*   - FIXED    修复更新讨论组/高级群头像失败的问题。
*   - FIXED    修复发送视频消息未显示首帧的问题。
*   - FIXED    修复表情和文案不一致的问题。
*   - FIXED    修复“正在输入中”的显示问题。
*   - FIXED    修复群聊消息已读按钮失效的问题。
*   - FIXED    修复其他已知问题。

## 9.2.11(2022-11-17)
*   - UPDATE   NIM SDK 版本升级到 V9.6.4    
*   - FIXED    修复好友名片中未显示基本信息的问题。
*   - FIXED    修复视频消息加载问题。
*   - FIXED    修复更新自己群昵称失败的问题。
*   - FIXED    修复加入他人圈组服务器的按钮失效问题。
*   - FIXED    修复圈组频道成员列表和频道黑白名单成员列表的展示问题。
*   - FIXED    修复无法退出图片详情页的问题。
*   - FIXED    修复历史图片未展示缩略图的问题。
*   - FIXED    修复黑名单成员列表头像与好友头像不一致的问题。
*   - FIXED    修复其他已知问题。


## 9.2.10(02-November-2022)
*   - FIXED    修复xcode 14编译错误问题

## 9.2.9(25-August-2022)
*   - NEW      iOS新增自定义用户信息功能。
*   - changed  IMKitEngine类中功能迁移至IMKitClient
*   - FIXED    修复OC工程调用UI库失败问题
*   - FIXED    统一接口层API
*   - FIXED    修复已知bug

## 9.2.8(19-September-2022)
*   - NEW    多语言能力支持
*   - FIXED  相机权限修改
*   - FIXED  历史遗留bug修改

## 9.2.7(25-August-2022)
*   - FIXED  修复 Swift 版本编译问题。
*   - FIXED  修复相册选择图片时图片展示问题。
*   - FIXED  修复圈组频道身份组权限信息展示问题。

## 9.2.6-rc01(02-August-2022)
*   - FIXED  修复导航控制器push 页面 页面卡顿问题

## 9.2.6-rc01(02-August-2022)
*   - FIXED  修复导航控制器push 页面 页面卡顿问题
*   - FIXED  修改错误emoji表情问题。
*   - FIXED  统一log命名->NELog
*   - FIXED  好友名片页去掉消息提醒开关
*   - FIXED  修复app端修改群组头像 web端不能展示问题
*   - FIXED  统一podspec依赖，三方库不设置固定版本
*   - NEW    添加Conversationrepo chatrepo 注解
*   - NEW    新增userInfoProvider功能类

## 9.2.4(28-June-2022)
*   - FIXED  修复客户反馈chat页面，无消息时下拉崩溃，新建群组下拉消息重复。
*   - FIXED  router路由对齐，contact主页面设置open。
*   - FIXED  修改Toast提示信息位置
*   - NEW    补充自定义消息逻辑

## 9.2.1(20-July-2022)
    - FIXED  低版本xcode编译低版本的包（xcode 13.2.1）

## 9.0.2(29-May-2022)
*   - FIXED  修复NEConversationUIKit,NEChatUIKit,NETeamUIKit,NEQChatUIKit,NEContactUIKit中作用域问题。

## 9.0.1(19-May-2022)
*   - NEW  我的->个人信息页 新增copy账号功能
*   - FIXED 修复头像被压缩问题
*   - FIXED 发送视屏压缩模糊问题修复
*   - FIXED 修复搜索框背景色,高度问题，修复会话列表首页弹窗阴影过重问题，修复alert弹窗色值问题，修复通讯录icon失真问题...
*   - FIXED 更新会话列表logo&title
*   - FIXED 修复圈组聊天页键盘偶现不能弹起问题。
*   - FIXED 修复图片预览被压缩变形问题

## 9.0.0(09-May-2022)
*   - NEW  swift新版本IM发布,包含消息，圈组，通讯录，我的版块。
