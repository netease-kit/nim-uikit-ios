# NIMKit 概述

## 前言

正所谓工欲善其事必先利其器，先要更好地使用 `NIMKit` 组件，了解其整体架构和构建思路是前提。这篇文章主要从架构设计的角度来解释 `NIMKit` 中的各个组成部分是如何协作，开发者应该如何进行流程跟踪。


## 组件结构

```
├── NIMSessionViewController                   # 核心会话类
│   ├── NIMSession                             # 所属会话
│   ├── UITableView                            # 聊天气泡聊表
│   ├── NIMSessionInteractor                   # 会话行为逻辑协议
│   ├── NIMSessionConfig                       # 会话参数配置协议
│   ├── NIMInputView                           # 输入框
│   └── UIRefreshControl                       # 下拉刷新控件
│
├── NIMSessionListViewController               # 最近会话列表页
│   ├── NSMutableArray<NIMRecentSession>       # 最近会话数据集合
│   └── UITableView                            # 最近会话列表
|
├── NIMContactSelectViewController             # 联系人选择器
│   ├── UITableView                            # 联系人选择器列表
│   └── NIMContactSelectConfig                 # 联系人选择器数据配置协议
│       ├── NIMContactFriendSelectConfig       # 内置配置 - 好友选择器
│       ├── NIMContactTeamMemberSelectConfig   # 内置配置 - 群成员选择器
│       └── NIMContactTeamSelectConfig         # 内置配置 - 群选择器
│
├── NIMNormalTeamCardViewController            # 普通群群名片
└── NIMAdvancedTeamCardViewController          # 高级群群名片

```

### 会话界面
* **概述**

	会话界面 `NIMSessionViewController` 继承 `UIViewController` ，由 `UITableView`(界面)，`NIMSessionConfig` (会话配置)， `NIMSessionInteractor` (逻辑控制器) 作为基本构成。
	
* **结构**

``` 
	 ┌──────────────────────────────────────────────┐
	 │                                              │               ┌────DataSource
	 │                                   ┌────────Interactor────────┤
	 │                                   │                          └────Layout
	 │                                   │
	SessionController────Configurator────┤
	 │      │                            │
	 │      │                            │      
	 │      │                            │                            
	 │   TableView                       └────────TableAdapter                           
	 │      │                                       │                            
	 │      └───────────────────────────────────────┘
	 │                                        
	Config───────MessageProvider
	 
```

* 会话类 `SessionController` 操作 `Interactor` 接口。
* `Configurator` 类为接口连接器，用来将接口与具体实现类相关联，实现与会话控制器的解耦。
     * 注入 `NIMSessionInteractor` 的具体实现类( 组件中为 `NIMSessionInteractorImpl`)
     * 注入 `UITableDataSource` 以及 `UITableDelegate` 的具体实现类 ( 组件中为 `NIMSessionTableAdapter`)

* **会话配置类**
   
   为了让开发者尽量少的修改源码，组件抽象出一些常用的配置接口以便于开发者简单修改界面。配置类不是必须实现的，如果不实现，则使用默认配置。
   
   配置类具体注入步骤为:
   * 继承会话类 `NIMSessionViewController` 。
   * 创建配置类，实现协议 `NIMSessionConfig`。
     * 协议接口都是选择实现的可以根据需求实现部分方法。
     * 具体实现还可以参考 Demo 中的配置类 `NTESSessionConfig` 。
   * 在继承的会话类中，重写父类接口 `- (id<NIMSessionConfig>)sessionConfig` 方法，返回创建的配置类。
 
 
   * 配置类结构

```
├── NIMSessionConfig                      
│   ├── #录音，文本，表情，更多 四个按钮的隐藏与排列
│   ├── #自定义动作菜单                        
│   ├── #禁用贴图                 
│   ├── #禁用语音红点                 
│   ├── #是否在贴耳的时候自动切换成听筒模式
│   ├── #进入会话的时候自动获取消息         
│   ├── #是否处理已读回执
│   ├── #录音类型
│   └── #消息数据提供器,需要实现 NIMKitMessageProvider 
│         ├── # 下拉时，提供的自定义历史数据
│         └── # 是否需要显示时间戳

```
   
   * 关于 消息数据提供器 NIMKitMessageProvider 的补充说明
     
     * 消息数据提供器用于一些对历史数据有特殊要求的界面场景。这些界面和正常的聊天界面非常相似，但是并不是用来聊天，只是用来展示一些特殊的消息数据，比如 Demo 中的云端历史聊天消息界面 ( `NTESSessionRemoteHistoryViewController` )。
     * 如果不实现数据提供方法 `- (void)pullDown:(NIMMessage *)firstMessage handler:(NIMKitDataProvideHandler)handler` , 则会默认抓取本地数据库中的历史消息数据。

* **逻辑实现类**

	由于会话界面比较复杂，组件抽象出了逻辑实现类接口 `NIMSessionInteractor`， 此接口在组件中的实现为 `NIMSessionInteractorImpl`。
	
	* `NIMSessionInteractorImpl` 由 数据逻辑 `NIMSessionDataSource` 和 排版逻辑 `NIMSessionLayout` 两部分接口组成。
	* 数据逻辑和排版逻辑接口的具体实现，在组件中分别是 `NIMSessionDataSourceImpl` 和 `NIMSessionLayoutImpl`，通过配置器 `NIMSessionConfigurator` 将实现类与接口注入关联。
	* 数据逻辑 `NIMSessionDataSource` 主要用于会话的数据的增删改查，作为界面的数据源，并缓存一些计算的中间数据，避免重复运算，提高性能。
	* 排版逻辑 `NIMSessionLayout` 主要用于会话的排版操作， `NIMSessionLayout` 不关心具体数据，只根据上层控制，对界面排版做出调整。
   
