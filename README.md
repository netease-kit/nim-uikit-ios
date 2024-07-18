
网易云信 IM UIKit是基于 NIM SDK（网易云信 IM SDK）开发的一款即时通讯 UI 组件库，包括聊天、会话、圈组、搜索、群管理等组件。通过 IM UIKit，可快速集成包含 UI 界面的即时通讯应用。

IM UIKit 简化了基于 NIM SDK 的应用开发过程。它不仅能助您快速实现 UI 功能，也支持调用 NIM SDK 相应的接口实现即时通讯业务逻辑和数据处理。因此，您在使用 IM UIKit 时仅需关注自身业务。

im-uikit-uniapp 界面效果如下图所示：

<img src="https://yx-web-nosdn.netease.im/common/7ffe6a8afe28b48405b41fb3313d1fa2/uniapp.png" width="800" height="550" />
<br>
<img src="https://yx-web-nosdn.netease.im/common/895963a051a2ae1fae685cfd1682a6bf/%E9%80%9A%E8%AE%AF%E6%A8%A1%E5%9D%97%E4%B8%BB%E8%A6%81%E7%95%8C%E9%9D%A2.png" width="800" height="500" />


## 功能优势

优势 | 说明
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
<br>
![im-demo.png](https://yx-web-nosdn.netease.im/common/a1a63e6b32886e7e35af1b4ea974af44/imuikitios.png)


详见[IM UIKit介绍](https://doc.yunxin.163.com/messaging-uikit/concept/zc3MDc4Nzk?platform=iOS)。


## IM UIKit 集成

具体的集成流程，请参见[快速集成 IM UIKit](https://doc.yunxin.163.com/messaging-uikit/guide?platform=iOS)。
