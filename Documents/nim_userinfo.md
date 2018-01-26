# 用户信息显示

## 前言

云信 SDK 遵循尽量少侵入开发者业务逻辑的原则，用户 Id 和云信 Id 仅做了绑定关系，相应的用户信息也不需要暴露给云信，相对应的 `NIMKit` 也遵循这个原则，它并不关心业务逻辑信息，但在做界面显示时不可避免需要由上层提供相应的用户昵称，头像等信息。这种情况下，开发者可以采取两种策略进行相应信息的提供：

* 服务器同步信息
* 客户端同步信息

## 服务器信息同步

这是最为常见的一种策略，`NIMKit` 只需要开发者保证两个字段信息和云信服务器保持同步即可：用户昵称，用户头像。具体服务器接口参考[这里](http://dev.netease.im/docs?doc=server&#用户名片)。这意味着，当一个 App 的真实用户进行昵称，头像信息的调整后，App 应用服务器需要同步调用云信服务器接口进行对应信息的更新。一旦 App 应用服务器完成这一步，云信 SDK 就会在必要的时候从云信服务器更新到相应数据，并由 `NIMKit` 进行获取显示。


## 客户端提供信息

一般而言，我们都推荐用户使用第一种方式进行信息同步。但是也有产品更看中用户隐私，仅仅将云信 SDK 作为一个消息的通道，而不愿意让它获取任何应用信息，对于这种情况，则需要由 App 提供 `NIMKit`显示时需要的信息。

开发者需要提供一个 `NIMKitDataProvider`的协议实现类，并通过 `NIMKit` 进行注册。

```objc
 [[NIMKit sharedKit] setProvider:[NTESDataProvider new]]; 
```

`NIMKitDataProvider` 协议定义如下

``` objc
@protocol NIMKitDataProvider <NSObject>

@optional

/**
 *  上层提供用户信息的接口
 *
 *  @param userId  用户ID
 *  @param option  获取选项
 *
 *  @return 用户信息
 */
- (NIMKitInfo *)infoByUser:(NSString *)userId
                    option:(NIMKitInfoFetchOption *)option;


/**
 *  上层提供群组信息的接口
 *
 *  @param teamId 群组ID
 *  @param option 获取选项
 *
 *  @return 群组信息
 */
- (NIMKitInfo *)infoByTeam:(NSString *)teamId
                    option:(NIMKitInfoFetchOption *)option;
                    

@end

```

其中，`NIMKitInfoFetchOption` 为抓取选项，定义了需要抓取信息所属的会话，或者所属的消息，是否需要屏蔽备注名等等，字段非必填，此对象在抓取时自行创建，并根据场景需求赋值。

例如，在最近会话列表中，需要显示用户的头像，这个时候只需要在 `NIMKitInfoFetchOption` 里定义所属会话即可。

```objc
NIMKitInfoFetchOption *option = [[NIMKitInfoFetchOption alloc] init];
option.session = session;
NIMKitInfo *info = [[NIMKit sharedKit] infoByUser:fromUid option:option];
```


在使用 `NIMKit` 进行用户信息显示时，`NIMKit` 将回调相应协议，从上层获取到相应的信息 `NIMKitInfo` 进行显示。在理想状态下，我们认为 App 都应该合理缓存用户信息，在收到回调时能够立刻返回。但实际环境下，由于各个 App 缓存用户信息策略不同，网络状况影响等多种原因将影响用户信息的同步获取。这意味着，App 需要在被回调时立刻提供一份 `占位信息` 供界面使用，并通过一定手动进行用户信息的获取，并在获取后通知 `NIMKit`。`NIMKit` 在 `NIMKit` 这个类中提供了如下接口用于用户信息的更新通知。

```objc
/**
 *  用户信息变更通知接口
 *
 *  @param userIds 用户 id 集合
 */
- (void)notfiyUserInfoChanged:(NSArray *)userIds;

/**
 *  群信息变更通知接口
 *
 *  @param teamIds 群 id 集合
 */
- (void)notifyTeamInfoChanged:(NSArray *)teamIds;

```

需要注意的是，由于界面刷新可能比较频繁，如果开发者每收到回调且发现信息缺失时就进行异步请求，有可能导致单位时间内用户信息请求过多，导致自身应用服务器承受不住压力。推荐参考 `NIMKit` 中 `NIMKitDataProviderImpl` 的写法。

