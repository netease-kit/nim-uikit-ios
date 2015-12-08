# 自定义消息气泡 UI 构建示例

##自定义消息排版
1.新建气泡内容，内容需要继承 `NIMSessionMessageContentView `，并使用 `- (instancetype)initSessionMessageContentView` 作为初始化方法。内容里根据业务需求自行排版。

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

2.新建自定义消息气泡布局配置,配置需要实现 `NIMCellLayoutConfig` 协议。

```objc
@interface CellLayoutConfig : NSObject<NIMCellLayoutConfig>
@end
```

```objc
@implementation CellLayoutConfig

- (CGSize)contentSize:(NIMMessageModel *)model cellWidth:(CGFloat)width{
    //填入内容大小
    return CGSizeMake(200, 50);
}

- (NSString *)cellContent:(NIMMessageModel *)model{
    //填入自定义的气泡contentView类型
    return @"ContentView";
}

- (UIEdgeInsets)cellInsets:(NIMMessageModel *)model{
    //填入气泡距cell的边距,选填
    return UIEdgeInsetsMake(5, 5, 5, 5);
}


- (UIEdgeInsets)contentViewInsets:(NIMMessageModel *)model{
    //填入内容距气泡的边距,选填
    return UIEdgeInsetsMake(5, 5, 5, 5);
}
@end
```

3.将创建好的布局配置填入[第一节](/NIM_Guide_For_Custom_Message.md#NIMSessionConfig)配置的 `SessionConfig` 中。

```objc
@interface SessionConfig : NSObject<NIMSessionConfig>
@end
```
   
```objc
@implementation SessionConfig
...
- (id<NIMCellLayoutConfig>)layoutConfigWithMessage:(NIMMessage *)message{
    if (message.messageType == NIMMessageTypeCustom) {
        return [[CellLayoutConfig alloc] init];
    }
    //其他内置消息类型，如果需沿用预定义的组件布局，则返回nil。
    return nil;
}
...
@end
```


