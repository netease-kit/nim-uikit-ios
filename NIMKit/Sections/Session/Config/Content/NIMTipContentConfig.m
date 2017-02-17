//
//  NIMTipContentConfig.m
//  NIMKit
//
//  Created by chris on 16/1/21.
//  Copyright © 2016年 NetEase. All rights reserved.
//

#import "NIMTipContentConfig.h"
#import "NIMKitUtil.h"
#import "NIMKitUIConfig.h"
#import "NIMKitUIConfig.h"

@implementation NIMTipContentConfig

- (CGSize)contentSize:(CGFloat)cellWidth message:(NIMMessage *)message
{
    CGFloat TeamNotificationMessageWidth  = cellWidth;
    UILabel *label = [[UILabel alloc] init];
    label.text  = [NIMKitUtil messageTipContent:message];
    label.font = [UIFont boldSystemFontOfSize:NIMKit_Notification_Font_Size];
    label.numberOfLines = 0;
    CGFloat padding = [NIMKitUIConfig sharedConfig].maxNotificationTipPadding;
    CGSize size = [label sizeThatFits:CGSizeMake(cellWidth - 2 * padding, CGFLOAT_MAX)];
    CGFloat cellPadding = 11.f;
    CGSize contentSize = CGSizeMake(TeamNotificationMessageWidth, size.height + 2 * cellPadding);;
    return contentSize;
}

- (NSString *)cellContent:(NIMMessage *)message
{
    return @"NIMSessionNotificationContentView";
}

- (UIEdgeInsets)contentViewInsets:(NIMMessage *)message
{
    NIMKitBubbleConfig *config = [[NIMKitUIConfig sharedConfig] bubbleConfig:message];
    return config.contentInset;
}

@end
