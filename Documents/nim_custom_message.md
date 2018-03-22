# 自定义消息

## 前言

虽然云信 SDK 内置了包括 `图片`，`音频`，`视频` 等多媒体消息，但有时候总归不能很好满足用户的需求，用户基于自己的应用场景往往会需要提供特殊的消息类型，在这一篇文章里面，将为你介绍如何从 model 到 UI，一步步实现自定义消息。

## 自定义消息模型

在云信 SDK 中，我们会需要使用 `NIMCustomObject` 来实现自定义消息类型，内部包含一个实现 `NIMCustomAttachment` 协议的对象，开发者需要提供一个实现 `NIMCustomAttachment` 协议的对象来完成自定义消息的发送和收发。

### 创建协议对象

创建一个实现 `NIMCustomAttachment` 协议的对象

```objc
@interface Attachment : NSObject<NIMCustomAttachment>

//简单新建一个有标题和副标题的自定义消息

@property (nonatomic,copy) NSString *title;

@property (nonatomic,copy) NSString *subTitle;

@end
```

### 实现 NIMCustomAttachment 协议

当我们拥有一个消息对象后，我们需要将这个对象发送到对端。这里的问题是：网络层我们传输的是流式数据，我们怎么样才能将一个 `id<NIMCustomAttachment>` 转换为数据流。这需要我们的 `id<NIMCustomAttachment>` 提供序列化它自己的方法，而这个方法已经定义在 `NIMCustomAttachment` 中。即：

```objc
- (NSString *)encodeAttachment;
```

通过实现这个方法，最终将 `id<NIMCustomAttachment>` 转换为数据流，并由云信 SDK 进行投递。在实际场景下，一条自定义消息往往会附带多媒体信息，如图片，音频等，同样 `NIMCustomAttachment` 也提供了相应的接口，开发只需要实现相应接口，所有的上传下载操作都可以由云信 SDK 完成。

**上传**

```objc
#pragma mark - 上传相关接口
/**
 *  是否需要上传附件
 *
 *  @return 是否需要上传附件
 */
- (BOOL)attachmentNeedsUpload;

/**
 *  需要上传的附件路径
 *
 *  @return 路径
 */
- (NSString *)attachmentPathForUploading;

/**
 *  更新附件URL
 *
 *  @param urlString 附件url
 */
- (void)updateAttachmentURL:(NSString *)urlString;

```
**下载**

```objc
#pragma mark - 下载相关接口
/**
 *  是否需要下载附件
 *
 *  @return 是否需要上传附件
 */
- (BOOL)attachmentNeedsDownload;

/**
 *  需要下载的附件url
 *
 *  @return 附件url
 */
- (NSString *)attachmentURLStringForDownloading;

/**
 *  需要下载的附件本地路径
 *
 *  @return 附件本地路径
 *  @discussion 上层需要保证路径的
 */
- (NSString *)attachmentPathForDownloading;

```

### 发送自定义消息

自定义消息的发送和其他消息类型并没有任何不同，直接调用 `NIMChatManager` 的发送接口即可。

### 接收自定义消息

和发送自定义消息不同，接收自定义消息需要上层提供额外的支持。在构造消息时，我们提到上层需要提供将自定义消息转换二进制流的协议实现，而同样的，当收到一条自定义消息时，SDK 并不清楚如何将这一串二进制流转换为对应的对象模型，需要上层提供。

在云信 SDK 中，我们使用 `NIMCustomAttachmentCoding` 协议支持自定义消息的反序列化。开发者需要实现对应的方法

```objc
@interface AttachmentDecoder : NSObject<NIMCustomAttachmentCoding>
@end
@implementation AttachmentDecoder

- (id<NIMCustomAttachment>)decodeAttachment:(NSString *)content{
    //所有的自定义消息都会走这个解码方法，如有多种自定义消息请自行做好类型判断和版本兼容。这里仅演示最简单的情况。
    id<NIMCustomAttachment> attachment;
    NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
    if (data) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if ([dict isKindOfClass:[NSDictionary class]]) {
            NSString *title = dict[@"title"];
            NSString *subTitle = dict[@"subTitle"];
            Attachment *myAttachment = [[Attachment alloc] init];
            myAttachment.title = title;
            myAttachment.subTitle = subTitle;
            attachment = myAttachment;
        }
    }
    return attachment;
}

@end
```

并在  `- (BOOL)application: didFinishLaunchingWithOptions:` 中注入

```objc

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
...
[NIMCustomObject registerCustomDecoder:[[AttachmentDecoder alloc]init]];
... 
}
	
```

## 自定义消息界面

### 新建气泡内容
气泡内容类需要继承 `NIMSessionMessageContentView `，并使用 `- (instancetype)initSessionMessageContentView` 作为初始化方法。内容里根据业务需求自行排版。

示例内容：

```objc
@interface ContentView : NIMSessionMessageContentView

@property (nonatomic,strong) UILabel *titleLabel;

@property (nonatomic,strong) UILabel *subTitleLabel;

@end

```

```objc
@implementation ContentView

- (instancetype)initSessionMessageContentView{
    self = [super initSessionMessageContentView];
    if (self) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [UIFont systemFontOfSize:13.f];
        _subTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _subTitleLabel.font = [UIFont systemFontOfSize:12.f];
        [self addSubview:_titleLabel];
        [self addSubview:_subTitleLabel];
    }
    return self;
}

- (void)refresh:(NIMMessageModel*)data{
    //务必调用super方法
    [super refresh:data];
    
    NIMCustomObject *object = data.message.messageObject;
    Attachment *attachment = object.attachment;
    
    self.titleLabel.text = attachment.title;
    self.subTitleLabel.text = attachment.subTitle;
    
    if (!self.model.message.isOutgoingMsg) {
        self.titleLabel.textColor = [UIColor blackColor];
        self.subTitleLabel.textColor = [UIColor blackColor];
    }else{
        self.titleLabel.textColor = [UIColor whiteColor];
        self.subTitleLabel.textColor = [UIColor whiteColor];
    }
    
    [_titleLabel sizeToFit];
    [_subTitleLabel sizeToFit];
}
- (void)layoutSubviews{
    [super layoutSubviews];
    CGFloat titleOriginX = 10.f;
    CGFloat titleOriginY = 10.f;
    CGFloat subTitleOriginX = (self.frame.size.width  - self.subTitleLabel.frame.size.width) / 2;
    CGFloat subTitleOriginY = self.frame.size.height  - self.subTitleLabel.frame.size.height - 10.f;
    
    CGRect frame = self.titleLabel.frame;
    frame.origin = CGPointMake(titleOriginX, titleOriginY);
    self.titleLabel.frame = frame;
    
    frame = self.subTitleLabel.frame;
    frame.origin = CGPointMake(subTitleOriginX, subTitleOriginY);
    self.subTitleLabel.frame = frame;
}

@end
```

2.新建自定义消息气泡布局配置,配置需要实现 `NIMCellLayoutConfig` 协议。这里除自定义消息外，其他消息沿用内置配置，所以配置类继承基类 `NIMCellLayoutConfig` 。

```objc
@interface CellLayoutConfig : NIMCellLayoutConfig<NIMCellLayoutConfig>
@end
```

```objc
@implementation CellLayoutConfig

- (CGSize)contentSize:(NIMMessageModel *)model cellWidth:(CGFloat)width{
    //填入内容大小
    if ([self isSupportedCustomModel:model]) {
       //先判断是否是需要处理的自定义消息
       return CGSizeMake(200, 50);
    }
    //如果不是自己定义的消息，就走内置处理流程
    return [super contentSize:model
                    cellWidth:width];
}

- (NSString *)cellContent:(NIMMessageModel *)model{
    //填入contentView类型
    if ([self isSupportedCustomModel:model]) {
       //先判断是否是需要处理的自定义消息
       return @"ContentView";
    }
    //如果不是自己定义的消息，就走内置处理流程
    return [super cellContent:model];
}

- (UIEdgeInsets)cellInsets:(NIMMessageModel *)model{
    //填入气泡距cell的边距,选填
    if ([self isSupportedCustomModel:model]) {
       //先判断是否是需要处理的自定义消息
       return UIEdgeInsetsMake(5, 5, 5, 5);
    }
    //如果不是自己定义的消息，就走内置处理流程
    return [super cellInsets:model];
}


- (UIEdgeInsets)contentViewInsets:(NIMMessageModel *)model{
    //填入内容距气泡的边距,选填
    if ([self isSupportedCustomModel:model]) {
       //先判断是否是需要处理的自定义消息
       return UIEdgeInsetsMake(5, 5, 5, 5);
    }
    //如果不是自己定义的消息，就走内置处理流程
    return [super contentViewInsets:model];
}
@end
```

3.将创建好的布局配置类注入到组件中，保证在会话页实例化之前注入即可。
   
```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
   ...
   
    //注册 NIMKit 自定义排版配置
    [[NIMKit sharedKit] registerLayoutConfig:[CellLayoutConfig new]];
    
   ...
- }
```

## 自定义消息事件传递
在自定义消息中，常常会有一些按钮点击，长按等事件，在父类 NIMSessionMessageContentView 中，已经预置好一些事件，不再需要额外在子类中添加事件按钮实现,子类重写这些方法即可。

```objc
/**
 *  手指从contentView内部抬起
 */
- (void)onTouchUpInside:(id)sender;


/**
 *  手指从contentView外部抬起
 */
- (void)onTouchUpOutside:(id)sender;

/**
 *  手指按下contentView
 */
- (void)onTouchDown:(id)sender;
```



有的时候，需要将事件传递给视图控制器做业务处理，如预览大图，页面跳转等等。推荐的事件传递方式为:

 * 在需要传递事件的 MessageContentView 中定义点击事件
 
   ```objc
   //ExampleMessageContentView.h
   
   extern NSString *const NIMDemoEventNameExample;
   
   ```
   
   ```objc
   //ExampleMessageContentView.m
   
   NSString *const NIMDemoEventNameExample  = @"NIMDemoEventNameExample";
   
   ```

   
* MessageContentView 的父类有事件上抛引用 delegate 。点击事件触发时，通过 delegate 发起 `onCatchEvent` 回调

  ```objc
    NIMKitEvent *event = [[NIMKitEvent alloc] init];
    event.eventName = NIMDemoEventNameExample;
    event.messageModel = self.model;
    event.data = self;
    [self.delegate onCatchEvent:event];
  ```
  推荐 NIMKitEvent 的 messageModel 中将消息 model 传入， data 中将需要的数据传入

* 回调传递到 NIMMemssageCell ，Cell 会自动发起 onTapCell: 回调
* 在对应的 SessionViewController 进行处理回调即可，具体可以参考 NTESSessionViewController 的 `onTapCell:` 方法

