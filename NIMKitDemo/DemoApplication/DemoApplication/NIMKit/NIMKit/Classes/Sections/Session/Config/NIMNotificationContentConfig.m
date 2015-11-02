//
//  NIMNotificationContentConfig.m
//  NIMKit
//
//  Created by amao on 9/15/15.
//  Copyright (c) 2015 NetEase. All rights reserved.
//

#import "NIMNotificationContentConfig.h"
#import "NIMAttributedLabel+NIMKit.h"
#import "NIMKitUtil.h"
#import "NIMUnsupportContentConfig.h"
#import "NIMDefaultValueMaker.h"

@implementation NIMNotificationContentConfig
- (CGSize)contentSize:(CGFloat)cellWidth
{
    CGSize contentSize = CGSizeZero;
    NIMNotificationObject *object = self.message.messageObject;
    switch (object.notificationType) {
        case NIMNotificationTypeTeam:{
            CGFloat TeamNotificationMessageWidth  = cellWidth;
            UILabel *label = [[UILabel alloc] init];
            label.text  = [NIMKitUtil formatedMessage:self.message];
            label.font = [UIFont boldSystemFontOfSize:NIMKit_Notification_Font_Size];
            label.numberOfLines = 0;
            CGFloat padding = [NIMDefaultValueMaker sharedMaker].maxNotificationTipPadding;
            CGSize size = [label sizeThatFits:CGSizeMake(cellWidth - 2 * padding, CGFLOAT_MAX)];
            CGFloat cellPadding = 11.f;
            contentSize = CGSizeMake(TeamNotificationMessageWidth, size.height + 2 * cellPadding);
            break;
        }
        case NIMNotificationTypeNetCall:{
            NIMAttributedLabel *label = [[NIMAttributedLabel alloc] initWithFrame:CGRectZero];
            label.font = [UIFont systemFontOfSize:NIMKit_Message_Font_Size];
            NSString *text = [NIMKitUtil formatedMessage:self.message];
            [label nim_setText:text];
            
            CGFloat msgBubbleMaxWidth    = (cellWidth - 130);
            CGFloat bubbleLeftToContent  = 14;
            CGFloat contentRightToBubble = 14;
            CGFloat msgContentMaxWidth = (msgBubbleMaxWidth - contentRightToBubble - bubbleLeftToContent);
            contentSize = [label sizeThatFits:CGSizeMake(msgContentMaxWidth, CGFLOAT_MAX)];
            break;
        }
        default:
        {
            NIMUnsupportContentConfig *config = [NIMUnsupportContentConfig sharedConfig];
            config.message = self.message;
            contentSize = [config contentSize:cellWidth];
            NSAssert(0, @"not supported notification type %zd",object.notificationType);
        }
            break;
    }
    return contentSize;
}


- (NSString *)cellContent
{
    NSString *cellContent = nil;
    NIMNotificationObject *object = (NIMNotificationObject *)self.message.messageObject;
    switch (object.notificationType)
    {
        case NIMNotificationTypeTeam:
            cellContent = @"NIMSessionNotificationContentView";
            break;
        case NIMNotificationTypeNetCall:
            cellContent = @"NIMSessionNetChatNotifyContentView";
            break;
        default:
        {
            NIMUnsupportContentConfig *config = [NIMUnsupportContentConfig sharedConfig];
            config.message = self.message;
            cellContent = [config cellContent];
            NSAssert(0, @"not supported notification type %zd",object.notificationType);
        }
            break;
    }
    return cellContent;
}


- (UIEdgeInsets)contentViewInsets
{
    UIEdgeInsets edgeInsets = UIEdgeInsetsZero;
    NIMNotificationObject *object = (NIMNotificationObject *)self.message.messageObject;
    switch (object.notificationType) {
        case NIMNotificationTypeTeam:
            edgeInsets = UIEdgeInsetsZero;
            break;
        case NIMNotificationTypeNetCall:
            edgeInsets = self.message.isOutgoingMsg ? UIEdgeInsetsMake(11,11,9,15) : UIEdgeInsetsMake(11,15,9,9);
            break;
        default:
        {
            NIMUnsupportContentConfig *config = [NIMUnsupportContentConfig sharedConfig];
            config.message = self.message;
            edgeInsets = [config contentViewInsets];
            NSAssert(0, @"not supported notification type %zd",object.notificationType);
        }
            
            break;

    }
    return edgeInsets;
}
@end
