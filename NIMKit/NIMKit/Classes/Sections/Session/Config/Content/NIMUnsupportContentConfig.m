//
//  NIMUnsupportContentConfig.m
//  NIMKit
//
//  Created by amao on 9/15/15.
//  Copyright (c) 2015 NetEase. All rights reserved.
//

#import "NIMUnsupportContentConfig.h"
#import "NIMKit.h"

@interface NIMUnsupportContentConfig ()

@property (nonatomic,strong) UILabel *label;

@end

@implementation NIMUnsupportContentConfig

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _label = [[UILabel alloc] initWithFrame:CGRectZero];
        _label.text = @"未知类型消息".nim_localized;
    }
    return self;
}

- (CGSize)contentSize:(CGFloat)cellWidth message:(NIMMessage *)message
{
    CGSize size = [self.label sizeThatFits:CGSizeMake(CGFLOAT_MAX, 40.f)];
    return CGSizeMake(size.width, 40.f);
}

- (NSString *)cellContent:(NIMMessage *)message
{
    NIMKitSetting *setting = [[NIMKit sharedKit].config setting:message];
    self.label.textColor = setting.textColor;
    self.label.font = setting.font;
    
    return @"NIMSessionUnknowContentView";
}

- (UIEdgeInsets)contentViewInsets:(NIMMessage *)message
{
    NIMKitSettings *settings = message.isOutgoingMsg? [NIMKit sharedKit].config.rightBubbleSettings : [NIMKit sharedKit].config.leftBubbleSettings;
    return settings.unsupportSetting.contentInsets;
}

@end
