# 机器人消息排版

## 前言

机器人消息作为云信内置的一种基本消息，有其不一样的特殊性如下：

 * **机器人的上下行消息**
 
   机器人的消息分上行和下行两种。用户发给机器人的消息称为上行消息，通常以纯文本形式展现，在组件中，复用了和文本消息同样的配置；机器人发给用户的消息称为下行消息，消息在界面上的表现形式比较繁多，通常会以文本，图片，按钮的形式进行随机组合。
   
 * **机器人消息交互层面的迷惑性**
   
   机器人消息经常会和文本消息有一定的类似，特定的交互形式下，两者还会由于用户的输入进行改变，以组件的交互举例：
   * 当用户在输入框中 @ 的用户不包括机器人时，组件认为这是一条文本，以文本消息形式发出。
   * 当用户在输入框中 @ 的用户包括机器人时，组件认为这是一段需要和机器人交互的内容，会自动以机器人消息形式发出。

   虽然在界面展示形式上都是一个气泡中包含了一些文字，但由于 @ 的对象不同，实际上消息类型是有一定差异的。
   
 * **机器人下行消息模板界面**
   
   机器人消息模板由用户在管理后台，机器人知识库中自行配置。一般以 xml 布局文件形式下发到客户端，这个时候客户端需要解析整个模板数据，构造出适合的布局模型，再传入视图进行渲染。

 
## 机器人模板布局数据解析

   由于机器人后台可提供的数据形式比较灵活，数据可以由后台内置的类型机型有限的组合，也可以由开发者进行完全的自定义。这里组件针对前一种有限组合的情况，提供了一套快速集成的模板数据转换到视图的方案。
   
   总体数据转换能力由 `NIMKit.h` 中定义的 `robotTemplateParser` 提供。通过给定消息（必须为机器人下行消息）输出布局模型数据来实现。
   
   ```objc
   - (NIMKitRobotTemplate *)robotTemplate:(NIMMessage *)message;
   ```
   
   `robotTemplateParser` 默认实现为 `NIMKitRobotDefaultTemplateParser` 类，如果开发者需要微调的话，只需要继承这个类，重写其中的部分方法，然后赋值到 `NIMKit` 单例中即可。
   
   `robotTemplateParser` 会缓存每个机器人消息的数据解析，数据缓存会在退出会话界面的时候清除。
   
   机器人视图数据配置定义在 `NIMRobotContentConfig` 中。
   
   机器人下行数据视图定义在 `NIMSessionRobotContentView` 中。
   
### 模板模型数据

   * 解析数据的模型为 单条机器人下行消息对应一个 `NIMKitRobotTemplate`。
   * `NIMKitRobotTemplate` 中包含多个 `NIMKitRobotTemplateLayout` 数据。
   * `NIMKitRobotTemplateLayout` 包含多个 `NIMKitRobotTemplateItem`
   * 当 `NIMKitRobotTemplateItem` 为 NIMKitRobotTemplateItemTypeLinkURL 或者 NIMKitRobotTemplateItemTypeLinkBlock 类型时，可包含其他 `NIMKitRobotTemplateItem`，此时 UI 表现形式为包含了文字或者图片的按钮。
   * 当 `NIMKitRobotTemplateItem` 为 其他形式时，表型形式为文字或者图片。
   * 每个 `NIMKitRobotTemplateItem` 为单独一行。

 
   
 
