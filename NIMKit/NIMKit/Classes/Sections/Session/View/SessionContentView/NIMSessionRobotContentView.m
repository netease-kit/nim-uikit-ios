//
//  NIMSessionRobotContentView.m
//  NIMKit
//
//  Created by chris on 2017/6/27.
//  Copyright © 2017年 NetEase. All rights reserved.
//

#import "NIMSessionRobotContentView.h"
#import "UIView+NIM.h"
#import "NIMKitRobotDefaultTemplateParser.h"
#import "NIMKit.h"
#import "M80AttributedLabel+NIMKit.h"
#import "UIImageView+WebCache.h"
#import "NIMGlobalMacro.h"
#import "NIMKit.h"

@interface NIMSessionRobotButton : UIButton

@property (nonatomic,copy) NSString *target;

@property (nonatomic,copy) NSString *url;

@property (nonatomic,copy) NSString *param;

@property (nonatomic,assign) NIMKitRobotTemplateItemType type;


@end

@interface NIMSessionRobotContentView()

@property (nonatomic,strong) NSMutableSet *buttons;

@property (nonatomic,strong) NSMutableSet *labels;

@property (nonatomic,strong) NSMutableSet *imageViews;

@property (nonatomic,strong) UIButton *continueButton;

@property (nonatomic,strong) NIMKitRobotDefaultTemplateParser *parser;

@end

@implementation NIMSessionRobotContentView

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

- (void)onContinue:(UIButton *)button
{
    NIMKitEvent *event = [[NIMKitEvent alloc] init];
    event.eventName = NIMKitEventNameTapRobotContinueSession;
    event.messageModel = self.model;
    [self.delegate onCatchEvent:event];
}

- (void)refreshContineButton:(NIMMessageModel *)data
{
    if (data.message.session.sessionType == NIMSessionTypeTeam)
    {
        [self addSubview:self.continueButton];
    }
    else
    {
        [self.continueButton removeFromSuperview];
    }
    
    NIMKitSetting *setting = [[NIMKit sharedKit].config setting:data.message];
    self.continueButton.titleLabel.font = setting.font;
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
                label.textColor = NIMKit_UIColorFromRGB(0x248DFA);
            }
            [view addSubview:label];
        }
            break;
        case NIMKitRobotTemplateItemTypeImage:
        {
            UIImageView *imageView = [self genImageView];
            imageView.nim_size = CGSizeMake(item.width.floatValue, item.height.floatValue);
            imageView.image = nil;
            if (item.url.length)
            {
                [imageView sd_setImageWithURL:[NSURL URLWithString:[[NIMSDK sharedSDK].resourceManager normalizeURLString:item.thumbUrl]] placeholderImage:nil options:SDWebImageRetryFailed];
            }            
            [view addSubview:imageView];
        }
            break;
        case NIMKitRobotTemplateItemTypeLinkURL:
        case NIMKitRobotTemplateItemTypeLinkBlock:
        {
            NIMSessionRobotButton *button = [self genButton];
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
    CGFloat height = [NIMSessionRobotContentView itemSpacing];
    CGFloat width = 0;;
    for (UIView *view in self.subviews) {
        if (view == self.bubbleImageView)
        {
            continue;
        }
        width = MAX(width, view.nim_width);
        height += view.nim_height;
        if (view == self.continueButton)
        {
            height += [NIMSessionRobotContentView continueItemSpacing];
        }
        else
        {
            height += [NIMSessionRobotContentView itemSpacing];
        }
    }
    return CGSizeMake(width, height);
}

- (void)onTouchButton:(NIMSessionRobotButton *)button
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

    CGFloat top = [NIMSessionRobotContentView itemSpacing];
    for (UIView *view in self.subviews)
    {
        if (view == self.bubbleImageView)
        {
            continue;
        }
        if (view == self.continueButton)
        {
            CGFloat rightMargin = 16.f;
            self.continueButton.nim_right  = self.nim_width - rightMargin;
            self.continueButton.nim_bottom = self.nim_height;
            continue;
        }
        view.nim_left = self.model.contentViewInsets.left;
        view.nim_top = top;
        top = view.nim_bottom + [NIMSessionRobotContentView itemSpacing];
    }
}


- (void)resizeAllSubView:(UIView *)superView insets:(UIEdgeInsets)insets
{
    CGFloat width = superView.nim_width - insets.left - insets.right;
    
    for (UIView *subView in superView.subviews)
    {
        if (subView.nim_height == 0)
        {
            if ([subView isKindOfClass:[M80AttributedLabel class]])
            {
                M80AttributedLabel *label = (M80AttributedLabel *)subView;
                CGSize size = [label sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
                label.nim_size = CGSizeMake(size.width, size.height);
                
                [self resizeAllSubView:label insets:UIEdgeInsetsZero];
            }
            else if ([subView isKindOfClass:[UIImageView class]])
            {
                UIImageView *imageView = (UIImageView *)subView;
                CGFloat defaultImageWidth  = 75.f;
                CGFloat defaultImageHeight = 75.f;
                imageView.nim_size = CGSizeMake(defaultImageWidth, defaultImageHeight);
                
                [self resizeAllSubView:imageView insets:UIEdgeInsetsZero];
            }
            else if ([subView isKindOfClass:[NIMSessionRobotButton class]])
            {
                NIMSessionRobotButton *button = (NIMSessionRobotButton *)subView;
                button.nim_width = width;
                
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
        if ([subView isKindOfClass:[NIMSessionRobotButton class]])
        {
            NIMSessionRobotButton *btn = (NIMSessionRobotButton *)subView;
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
        label.textAlignment = kCTTextAlignmentLeft;
        
        label.backgroundColor = [UIColor clearColor];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    }

    NIMKitSetting *setting = [[NIMKit sharedKit].config setting:self.model.message];
    label.textColor = setting.textColor;
    label.font = setting.font;
    
    return label;
}

- (NIMSessionRobotButton *)genButton
{
    NIMSessionRobotButton *button = nil;
    if (self.buttons.count)
    {
        button = self.buttons.anyObject;
        [self.buttons removeObject:button];
    }
    else
    {
        button = [[NIMSessionRobotButton alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
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
    return 11.f;
}

+ (CGFloat)continueItemSpacing
{
    return 5.f;
}



@end

@implementation NIMSessionRobotButton

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.layer.borderColor = NIMKit_UIColorFromRGB(0x248DFA).CGColor;
        self.layer.borderWidth = 1.f;
        self.layer.cornerRadius = 22;
    }
    return self;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGFloat height = [NIMSessionRobotContentView itemSpacing];
    for (UIView *subView in self.subviews) {
        height += subView.nim_height;
        height += [NIMSessionRobotContentView itemSpacing];
    }
    return CGSizeMake(self.nim_width, height);
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    self.alpha = highlighted? 0.5f : 1.0f;
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat top = [NIMSessionRobotContentView itemSpacing];
    for (UIView *view in self.subviews)
    {
        view.nim_centerX = self.nim_width * .5;
        view.nim_top = top;
        top = view.nim_bottom + [NIMSessionRobotContentView itemSpacing];
    }
}

@end
