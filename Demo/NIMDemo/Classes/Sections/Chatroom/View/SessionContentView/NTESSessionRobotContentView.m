//
//  NTESSessionRobotContentView.m
//  NIMDemo
//
//  Created by chris on 2017/6/27.
//  Copyright © 2017年 NetEase. All rights reserved.
//

#import "NTESSessionRobotContentView.h"
#import "UIView+NTES.h"
#import "NIMKitRobotDefaultTemplateParser.h"
#import "NIMKit.h"
#import "M80AttributedLabel+NIMKit.h"
#import "UIImageView+WebCache.h"
#import "NIMGlobalMacro.h"


@interface NTESSessionRobotButton : UIButton

@property (nonatomic,copy) NSString *target;

@property (nonatomic,copy) NSString *url;

@property (nonatomic,copy) NSString *param;

@property (nonatomic,assign) NIMKitRobotTemplateItemType type;


@end

@interface NTESSessionRobotContentView()

@property (nonatomic,strong) NSMutableSet *buttons;

@property (nonatomic,strong) NSMutableSet *labels;

@property (nonatomic,strong) NSMutableSet *imageViews;

@property (nonatomic,strong) UIButton *continueButton;

@property (nonatomic,strong) NIMKitRobotDefaultTemplateParser *parser;

@end

@implementation NTESSessionRobotContentView

- (instancetype)initSessionMessageContentView
{
    self = [super initSessionMessageContentView];
    if (self)
    {
        _buttons    = [[NSMutableSet alloc] init];
        _labels     = [[NSMutableSet alloc] init];
        _imageViews = [[NSMutableSet alloc] init];
        _parser     = [[NIMKitRobotDefaultTemplateParser alloc] init];
        
        _continueButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_continueButton setTitle:@"继续对话" forState:UIControlStateNormal];
        [_continueButton setTitleColor:NIMKit_UIColorFromRGB(0x168cf6) forState:UIControlStateNormal];
        [_continueButton addTarget:self action:@selector(onContinue:) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}


- (void)refresh:(NIMMessageModel *)data
{
    [super refresh:data];
    [self setupRobot:data];
}


- (UIImage *)chatBubbleImageForState:(UIControlState)state outgoing:(BOOL)outgoing
{
    return nil;
}


- (void)onContinue:(UIButton *)button
{
    NIMKitEvent *event = [[NIMKitEvent alloc] init];
    event.eventName = NIMKitEventNameTapRobotContinueSession;
    event.messageModel = self.model;
    [self.delegate onCatchEvent:event];
}

- (void)refreshContineButton:(NIMMessageModel *)data
{
    if (!self.continueButton.superview)
    {
        [self addSubview:self.continueButton];
    }
    NIMKitBubbleConfig *config = [[NIMKitUIConfig sharedConfig] bubbleConfig:data.message];
    self.continueButton.titleLabel.font = [UIFont systemFontOfSize:config.textFontSize];
    [self.continueButton sizeToFit];
}


- (void)setupRobot:(NIMMessageModel *)data
{
    //上行消息交给 TextContentView 处理了
    //一定是机器人下行消息
    [self recycleAllSubViews:self];
    NIMKitRobotTemplate *template = [[NIMKit sharedKit].robotTemplateParser robotTemplate:data.message];
    if (![template.version isEqualToString:@"0.1"])
    {
        NSLog(@"robot template version incompatible!");
    }
    for (NIMKitRobotTemplateLayout *layout in template.items)
    {
        for (NIMKitRobotTemplateItem *item in layout.items)
        {
            [self applyItem:item inView:self];
        }
    }
    
    [self refreshContineButton:data];
}


- (void)applyItem:(NIMKitRobotTemplateItem *)item
           inView:(UIView *)view
{
    switch (item.itemType) {
        case NIMKitRobotTemplateItemTypeText:
        {
            M80AttributedLabel *label = [self genLabel];
            label.text = item.content;
            if ([view isKindOfClass:[UIButton class]])
            {
                // button 里头的 title 全部居中
                label.textAlignment = kCTTextAlignmentCenter;
                label.textColor = UIColorFromRGB(0x333333);
                label.font = [UIFont systemFontOfSize:Message_Font_Size];
            }
            [view addSubview:label];
        }
            break;
        case NIMKitRobotTemplateItemTypeImage:
        {
            UIImageView *imageView = [self genImageView];
            imageView.size = CGSizeMake(item.width.floatValue, item.height.floatValue);
            imageView.image = nil;
            if (item.url.length)
            {
                [imageView sd_setImageWithURL:[NSURL URLWithString:[[NIMSDK sharedSDK].resourceManager convertHttpToHttps:item.thumbUrl]] placeholderImage:nil options:SDWebImageRetryFailed];
            }            
            [view addSubview:imageView];
        }
            break;
        case NIMKitRobotTemplateItemTypeLinkURL:
        case NIMKitRobotTemplateItemTypeLinkBlock:
        {
            NTESSessionRobotButton *button = [self genButton];
            NIMKitRobotTemplateLinkItem *link = (NIMKitRobotTemplateLinkItem *)item;
            button.target = link.target;
            button.param  = link.params;
            button.url    = link.url;
            button.type   = link.itemType;
            
            for (NIMKitRobotTemplateItem *linkItem in link.items)
            {
                [self applyItem:linkItem inView:button];
            }
            [view addSubview:button];
        }
            break;
        
        default:
            break;
    }
}


- (CGSize)sizeThatFits:(CGSize)size
{
    CGFloat height = [NTESSessionRobotContentView itemSpacing];
    CGFloat width = 0;;
    for (UIView *view in self.subviews) {
        if (view == self.bubbleImageView)
        {
            continue;
        }
        width = MAX(width, view.width);
        height += view.height;
        if (view == self.continueButton)
        {
            height += [NTESSessionRobotContentView continueItemSpacing];
        }
        else
        {
            height += [NTESSessionRobotContentView itemSpacing];
        }
    }
    UIEdgeInsets contentInsets = self.model.contentViewInsets;
    height += (contentInsets.top + contentInsets.bottom);
    return CGSizeMake(width, height);
}

- (void)onTouchButton:(NTESSessionRobotButton *)button
{
    NIMKitEvent *event = [[NIMKitEvent alloc] init];
    if (button.type == NIMKitRobotTemplateItemTypeLinkURL)
    {
        event.eventName = NIMKitEventNameTapRobotLink;
        event.data = button.target;
    }
    else
    {
        event.eventName = NIMKitEventNameTapRobotBlock;
        NSMutableDictionary *data = [@{@"target":button.target} mutableCopy];
        NIMRobotObject *object = (NIMRobotObject *)self.model.message.messageObject;
        [data setObject:object.robotId forKey:@"robotId"];
        if (button.param)
        {
            [data setObject:button.param forKey:@"param"];
        }
        NSString *text = @"";
        for (M80AttributedLabel *label in button.subviews)
        {
            if ([label isKindOfClass:[M80AttributedLabel class]])
            {
                text = [text stringByAppendingFormat:@"%@ ",label.text];
            }
        }
        [data setObject:text forKey:@"text"];
        event.data = data;
    }
    [self.delegate onCatchEvent:event];
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    [self resizeAllSubView:self insets:self.model.contentViewInsets];
    
    UIEdgeInsets contentInsets = self.model.contentViewInsets;
    CGFloat top = [NTESSessionRobotContentView itemSpacing] + contentInsets.top;
    for (UIView *view in self.subviews)
    {
        if (view == self.bubbleImageView)
        {
            continue;
        }
        if (view == self.continueButton)
        {
            CGFloat rightMargin = 16.f;
            self.continueButton.right  = self.width - rightMargin;
            self.continueButton.bottom = self.height;
            continue;
        }
        view.left = self.model.contentViewInsets.left;
        view.top = top;
        top = view.bottom + [NTESSessionRobotContentView itemSpacing];
    }
}


- (void)resizeAllSubView:(UIView *)superView insets:(UIEdgeInsets)insets
{
    CGFloat width = superView.width - insets.left - insets.right;
    
    for (UIView *subView in superView.subviews)
    {
        if (subView.height == 0)
        {
            if ([subView isKindOfClass:[M80AttributedLabel class]])
            {
                M80AttributedLabel *label = (M80AttributedLabel *)subView;
                CGSize size = [label sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
                label.size = CGSizeMake(size.width, size.height);
                
                [self resizeAllSubView:label insets:UIEdgeInsetsZero];
            }
            else if ([subView isKindOfClass:[UIImageView class]])
            {
                UIImageView *imageView = (UIImageView *)subView;
                CGFloat defaultImageWidth  = 75.f;
                CGFloat defaultImageHeight = 75.f;
                imageView.size = CGSizeMake(defaultImageWidth, defaultImageHeight);
                
                [self resizeAllSubView:imageView insets:UIEdgeInsetsZero];
            }
            else if ([subView isKindOfClass:[NTESSessionRobotButton class]])
            {
                NTESSessionRobotButton *button = (NTESSessionRobotButton *)subView;
                button.width = width;
                
                [self resizeAllSubView:button insets:UIEdgeInsetsZero];
                
                [button sizeToFit];
            }
        }
    }
}


- (void)recycleAllSubViews:(UIView *)view
{
    for (UIView *subView in view.subviews)
    {
        if (subView == self.bubbleImageView || subView == self.continueButton) {
            continue;
        }
        [subView removeFromSuperview];
        
        subView.frame = CGRectZero;
        if ([subView isKindOfClass:[NTESSessionRobotButton class]])
        {
            NTESSessionRobotButton *btn = (NTESSessionRobotButton *)subView;
            btn.target = nil;
            btn.url    = nil;
            btn.param  = nil;
            [btn removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
            [_buttons addObject:subView];
        }
        if ([subView isKindOfClass:[UILabel class]])
        {
            [_labels addObject:subView];
        }
        if ([subView isKindOfClass:[UIImageView class]])
        {
            [_imageViews addObject:subView];
        }
        
        [self recycleAllSubViews:subView];
    }
}

- (M80AttributedLabel *)genLabel
{
    M80AttributedLabel *label = nil;
    if (self.labels.count)
    {
        label = self.labels.anyObject;
        [self.labels removeObject:label];
    }
    else
    {
        label = [[M80AttributedLabel alloc] initWithFrame:CGRectZero];
        label.numberOfLines = 0;
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.backgroundColor = [UIColor clearColor];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    }
    label.textAlignment = kCTTextAlignmentLeft;
    label.font = [UIFont systemFontOfSize:Chatroom_Message_Font_Size];
    label.textColor = [UIColor blackColor];

    return label;
}

- (NTESSessionRobotButton *)genButton
{
    NTESSessionRobotButton *button = nil;
    if (self.buttons.count)
    {
        button = self.buttons.anyObject;
        [self.buttons removeObject:button];
    }
    else
    {
        button = [[NTESSessionRobotButton alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        button.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    }
    [button addTarget:self action:@selector(onTouchButton:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UIImageView *)genImageView
{
    UIImageView *view = nil;
    if (self.imageViews.count)
    {
        view = self.imageViews.anyObject;
        [self.imageViews removeObject:view];
    }
    else
    {
        view = [[UIImageView alloc] initWithFrame:CGRectZero];
    }
    return view;
}

+ (CGFloat)itemSpacing
{
    return 7.f;
}

+ (CGFloat)continueItemSpacing
{
    return 5.f;
}



@end

@implementation NTESSessionRobotButton

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.layer.borderColor = [UIColor clearColor].CGColor;
        self.layer.borderWidth = 1.f;
        self.layer.cornerRadius = 18;
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGFloat height = [self itemSpacing];
    for (UIView *subView in self.subviews) {
        height += subView.height;
        height += [self itemSpacing];
    }
    return CGSizeMake(self.width, height);
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    self.alpha = highlighted? 0.5f : 1.0f;
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat top = [self itemSpacing];
    for (UIView *view in self.subviews)
    {
        view.centerX = self.width * .5;
        view.top = top;
        top = view.bottom + [self itemSpacing];
    }
}

- (CGFloat)itemSpacing
{
    return 5.f;
}

@end
