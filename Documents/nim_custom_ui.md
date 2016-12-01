# 聊天界面排版自定义

## 前言

针对开发者对组件的不同定制需求，云信 iOS UI 组件提供了大量配置可以让开发者便捷的修改或自定义排版。根据定制的深度，大体可以分为两种：

 * **聊天气泡的简单布局定制**

   关于内置聊天气泡的各种内间距，组件均已提出并组成 `plist` 配置文件供开发者直接设置。开发者不需要关心具体的界面实现代码，只需要在配置文件上改一些间距值，即可进行界面调试。
   
   这种定制适用于开发者满足于内置的消息类型，并不需要对消息气泡的界面布局做出很大改变的情况。
   
 * **聊天界面的深度定制**
   
   有的时候，需要根据具体的消息类型并结合业务逻辑的上下文定制聊天界面，这个时候一个简单的配置文件就不再适用了。UI 组件提供一个全局的排版控制器注入接口 `- (void)registerLayoutConfig:(Class)layoutConfigClass` 来让上层开发者自行注入排版配置器。
   
   排版配置器需要实现 `NIMCellLayoutConfig` 协议。

 
## NIMMessageCell

UI 组件的消息绘制都是统一由 `NIMMessageCell` 类完成的，因此，了解 `NIMMessageCell` 的大致组成，对排版是很有帮助的。

<img src="https://github.com/netease-im/NIM_Resources/blob/master/iOS/Images/nimkit_cell.jpg" width="550" height="210" />

    * 蓝色区域：为具体内容 ContentView，如文字 UILabel ,图片 UIImageView 等。

    * 绿色区域：为消息的气泡，具体的内容和气泡之间会有一定的内间距，这里为 contentViewInsets 。

    * 紫色区域：为整个 UITableViewCell ，具体的气泡和整个cell会有一定的内间距，这里为 cellInsets 。

    * 红色区域：为用户的头像。
    
 在刷新数据时，会调用方法并 `-(void)refresh` 将界面模型 `NIMMessageModel` 传入。
    
 当第一次调用这个方法（即不是复用生成），会调用 `- (void)addContentViewIfNotExist` 方法，根据 `NIMMessageModel` 找到对应的布局配置(如果找不到则按未知类型消息处理)。
 
 Tips：开发者在第一次接入的时候，可能由于协议实现不全或者注入布局配置有误等原因，导致消息在界面上显示为 `未知类型消息`，这个时候可以尝试从 `NIMMessageCell` 的 `- (void)addContentViewIfNotExist` 方法入手调试，查看`NIMMessageModel` 对应的布局配置以及协议的返回值是否正确。


## 聊天气泡的简单布局定制
   
   通过修改组件中的配置文件可以进行简单的布局定制，配置文件分为全局配置和气泡配置。
   
   * 全局配置文件 `NIMKitGlobalSetting.plist`
   
   
   |**名称** | **定义** | 
	|:----- | :-----|
	|**Message_Interval** | 每隔多久显示一条时间戳，秒为单位 |
	|**Message_Limit** | 每次抓取消息的数量限制，用于分页 |
	|**Record\_Max\_Duration** | 最大录音时长 |
	|**Placeholder**  | 输入框中的占位提示文字 |
	|**Max_Length**   | 输入框字符最大长度 |
	|**Bubble**  | 消息气泡的通用背景 |
     
   * 气泡配置文件 `NIMKitBubbleSetting.plist`
    
    其中 `Root` 下的 `key` 为内置消息类型，不可更改。

    具体为
    
    |**名称** | **定义** | 
	|:----- | :-----|
	|**Text** | 文本消息 |
	|**Audio** | 音频消息 |
	|**Video** | 视频消息 |
	|**File**  | 文件消息 |
	|**Image** | 图片消息 |
	|**Location** | 位置消息 |
	|**Tip** | 提醒消息 |
	|**Team_Notification** | 群通知消息 |
	|**Chatroom_Notification** | 聊天室通知消息 |
	|**Netcall_Notification** | 网络电话通知消息 |
	|**Unsupport** | 未知类型消息 |
	
	
	具体配置参数为
	
	|**名称** | **定义** | 
	|:----- | :-----|
	|**Content_Insets** | 消息内容距离气泡的内边距 |
	|**Content_Color**  | 消息文本的颜色 |
	|**Content\_Font\_Size** | 消息文本字体大小 |
	|**Show_Avatar**  | 是否显示头像 |
	|**Bubble**  | 消息气泡的背景 |

	

## 聊天界面的深度定制
   如果需要结合一些上下文定制聊天界面，就需要采用深度定制。在进入会话页之前，注入布局布局配置到 `NIMKit` 即可
   
   ```objc
//注册 NIMKit 自定义排版配置
[[NIMKit sharedKit] registerLayoutConfig:[NTESCellLayoutConfig class]];
   ```  
   
   布局配置器可以选择实现 `NIMCellLayoutConfig` 接口所定义的方法，不实现的接口，会采用内置的默认布局参数进行处理。
   
   在很多场景下，只是在特殊消息场景下需要修正一下排版配置，其他情况还是沿用默认配置，因此强烈建议自定义的排版控制器继承内置的排版实现 `NIMCellLayoutConfig` 协议。这样在开发者需要自定义布局的场景下，填入自定义配置，其他情况只需调用 `super` 方法即可。
   
   具体实现逻辑示范见 Demo 中 `NTESCellLayoutConfig` 类。
   
   
 