//
//  NIMTipContentConfig.m
//  NIMKit
//
//  Created by chris on 16/1/21.
//  Copyright © 2016年 NetEase. All rights reserved.
//

#import "NIMTipContentConfig.h"
#import "NIMKitUtil.h"
#import "NIMDefaultValueMaker.h"

@implementation NIMTipContentConfig

- (CGSize)contentSize:(CGFloat)cellWidth
{
    CGFloat TeamNotificationMessageWidth  = cellWidth;
    UILabel *label = [[UILabel alloc] init];
    label.text  = [NIMKitUtil messageTipContent:self.message];
    label.font = [UIFont boldSystemFontOfSize:NIMKit_Notification_Font_Size];
    label.numberOfLines = 0;
    CGFloat padding = [NIMDefaultValueMaker sharedMaker].maxNotificationTipPadding;
    CGSize size = [label sizeThatFits:CGSizeMake(cellWidth - 2 * padding, CGFLOAT_MAX)];
    CGFloat cellPadding = 11.f;
    CGSize contentSize = CGSizeMake(TeamNotificationMessageWidth, size.height + 2 * cellPadding);;
    return contentSize;
}


- (NSString *)cellContent
{
    return @"NIMSessionNotificationContentView";
}


- (UIEdgeInsets)contentViewInsets
{
    return UIEdgeInsetsZero;
}

@end
