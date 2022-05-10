
网易云信 IM UIKit是基于 NIM SDK（网易云信 IM SDK）开发的一款即时通讯 UI 组件库，包括聊天、会话、圈组、搜索、群管理等组件。通过 IM UIKit，可快速集成包含 UI 界面的即时通讯应用。

IM UIKit 简化了基于 NIM SDK 的应用开发过程。它不仅能助您快速实现 UI 功能，也支持调用 NIM SDK 相应的接口实现即时通讯业务逻辑和数据处理。因此，您在使用 IM UIKit 时仅需关注自身业务。

## 功能优势

<div style="width:100px" align="left">优势</div> | <div style="width:120px" align="left">说明</div>
---- | --------------
UI 组件解耦 | IM UIKit 不同组件可相互独立运行使用。您可按需选择组件，将其快速集成到您的应用，实现相应的 UI 功能，减少无用依赖。
UI 能力简洁易用 |IM UIKit 的业务逻辑层与 UI 层相互独立。在 UI 层，您仅需关注视图展示和事件处理。IM UIKit 清晰的数据流转处理，让 UI 层代码更简洁易懂。
完善的业务逻辑处理 | IM UIKit 业务逻辑层提供完善的业务逻辑处理能力。您无需关心 SDK 层不同接口间的复杂处理逻辑，业务逻辑层一个接口帮您搞定所有。
  






## 技术原理

### 工作原理

IM UIKit 采用 （Model–View–ViewModel）MVVM 架构模型，实现 UI 展示与业务逻辑开发的相互独立。

![IMuikitDataFlow_iOS.png](https://yx-web-nosdn.netease.im/common/4526057a8ef3f59f6c65c56c42991de9/IMuikitDataFlow_iOS.png)

流程 | 说明
---- | --------------
1 | IM UIKit 展示层的 UIViewController/View 向响应层的 ViewModel 发送请求。
2 | ViewModel 将请求经由业务逻辑层转发至 NIM SDK。
3 | NIM SDK 接收请求后触发回调，回调数据经由业务逻辑层和响应层发送至 UIViewController/View。
4 | UIViewController/View 将回调数据发送至 UITableViewDelegate 和 UItableViewDataSource。后两者根据需在界面上展示的不同实体的 identifier，判定具体的 UI 样式。例如，SDK 返回的回调数据为消息数据时，UITableViewDelegate 和 UItableViewDataSource 可通过消息数据中包含的代表消息类型的 identifier，将消息在 UI 上展示为对应类型的样式。

### 产品架构



![app_structure_foure_iOS.png](https://yx-web-nosdn.netease.im/common/28d91f74b198c2ba1f1bdfabf19fdc06/app_structure_foure_iOS.png)

上图中：

- UIKit UI 层的 `NEContactUIKit`、`NEChatUIKit`、`NEConversationUIKit` 和 `NEQChatUIKit` 等，对应上述工作原理图中的 Activity/Fragment/View。
- UIKit UI 层的 `NEContactKit`、`NEChatKit` 和 `NEQChatKit` 等，对应上述工作原理图中的 Repository。
- NECoreKit 层对应上述工作原理图中的 Provider。

## 示例项目下载

扫描如下二维码下载和体验示例项目。


![iOS二维码.png](https://yx-web-nosdn.netease.im/common/9179ca9460368d1bf73775da9a32bb0c/iOS二维码.png)


## 示例项目效果展示


如下动图展示了 UIKit 示例项目的主要功能。

<div style="display:flex;width:100%;justify-content:space-between;background-color:#F0F0F0;">
    <div style="width:30%; text-align:center;">
        <p><b>圈组相关</b></p>
        <img style="width:100%" src="https://yx-web-nosdn.netease.im/common/455613865e80a9b342588228bb1c0bc8/创建服务器.gif" alt="image" />
    </div>
    <div style="width:30%;text-align:center;">
        <p><b>通讯录相关</b></p>
        <img style="width:100%" src="https://yx-web-nosdn.netease.im/common/c0a3237dcc4319d81bc2cab7d62b460a/通讯录.gif" alt="image" />
    </div>
    <div style="width:30%;text-align:center;">
        <p><b>消息相关</b></p>
        <img style="width:100%" src="https://yx-web-nosdn.netease.im/common/88eb27b848c619150131f989303c3eb3/消息相关.gif" alt="image" />
    </div>
</div>


## 示例项目功能清单

IM UIKit 示例项目包含四大功能模块，即**消息**、**圈组**、**通讯录**和**我的**。您可参考[示例项目](https://github.com/netease-kit/nim-uikit-ios)快速集成含 UI 界面的即时通讯应用。


<div style="width:40px" align="left">界面模块</div> | <div style="width:160px" align="left">功能项 </div>
---- | -------------- 
消息| <div> <ul> <li>消息（文本、语音、表情、图片、视频）收发</li><li>复制消息</li><li>显示对方正在输入</li><li>对消息进行回复</li><li>转发消息</li><li>标记消息</li><li>多选消息</li><li>收藏消息</li><li>删除消息</li><li>撤回消息</li><li>消息提醒</li><li>根据关键字搜索单聊和群聊</li><li>Pin 消息</li><li>清理聊天记录</li><li>历史消息</li><li>会话管理</li><li>创建讨论组</li><li>创建高级群</li><li>设置群昵称</li><li>展示群组列表</li><li>开启消息提醒</li><li>聊天置顶</li></ul></div>
圈组 | <div> <ul><li>创建服务器</li><li>加入别人的服务器</li><li>服务器信息设置</li><li>身份组管理</li><li>成员特殊权限管理</li><li>创建频道</li><li>频道消息收发</li><li>频道信息设置</li><li>频道权限设置</li><li>频道黑名单设置</li><li>频道白名单设置</li><li>频道内选择成员单聊</li></ul></div>
通讯录 | <div> <ul> <li>添加好友</li><li>好友验证</li><li>好友备注</li><li>删除好友</li><li>好友排序</li><li>我的群聊列表</li><li>黑名单管理</li></ul></div>
我的 | <div> <ul> <li>个人信息设置</li><li>查看收藏</li><li>消息提醒设置</li><li>清理缓存</li><li>开启/关闭听筒模式</li><li>删除好友是否同步删除备注</li><li>消息已读未读功能</li></ul></div>


## IM UIKit 集成

具体的集成流程，请参见[快速集成 IM UIKit](https://doc.yunxin.163.com/docs/TM5MzM5Njk/zg2ODA0ODQ)。