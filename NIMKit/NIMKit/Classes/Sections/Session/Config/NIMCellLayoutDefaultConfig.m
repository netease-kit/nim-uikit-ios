//
//  NIMSessionDefaultConfig.m
//  NIMKit
//
//  Created by chris.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#import "NIMCellLayoutDefaultConfig.h"
#import "NIMSessionMessageContentView.h"
#import "NIMSessionUnknowContentView.h"
#import "NIMAttributedLabel+NIMKit.h"
#import "NIMKitUtil.h"
#import "UIImage+NIM.h"
#import "NIMMessageModel.h"
#import "NIMBaseSessionContentConfig.h"

@implementation NIMCellLayoutDefaultConfig

- (CGSize)contentSize:(NIMMessageModel *)model cellWidth:(CGFloat)cellWidth{
    
    id<NIMSessionContentConfig>config = [[NIMSessionContentConfigFactory sharedFacotry] configBy:model.message];
    return [config contentSize:cellWidth];
}

- (NSString *)cellContent:(NIMMessageModel *)model{
    
    id<NIMSessionContentConfig>config = [[NIMSessionContentConfigFactory sharedFacotry] configBy:model.message];
    NSString *cellContent = [config cellContent];
    return cellContent ? : @"NIMSessionUnknowContentView";
}


- (UIEdgeInsets)contentViewInsets:(NIMMessageModel *)model{
    
    id<NIMSessionContentConfig>config = [[NIMSessionContentConfigFactory sharedFacotry] configBy:model.message];
    return [config contentViewInsets];
}


- (UIEdgeInsets)cellInsets:(NIMMessageModel *)model
{
    if ([[model.layoutConfig cellContent:model] isEqualToString:@"NIMSessionNotificationContentView"]) {
        return UIEdgeInsetsZero;
    }
    CGFloat cellTopToBubbleTop           = 3;
    CGFloat otherNickNameHeight          = 20;
    CGFloat otherBubbleOriginX           = 55;
    CGFloat cellBubbleButtomToCellButtom = 13;
    if (model.message.session.sessionType == NIMSessionTypeTeam) {
        //要显示名字。。
        return UIEdgeInsetsMake(cellTopToBubbleTop + otherNickNameHeight ,otherBubbleOriginX,cellBubbleButtomToCellButtom, 0);
    }
    return UIEdgeInsetsMake(cellTopToBubbleTop,otherBubbleOriginX,cellBubbleButtomToCellButtom, 0);
}

- (BOOL)shouldShowAvatar:(NIMMessageModel *)model
{
    if ([[model.layoutConfig cellContent:model] isEqualToString:@"NIMSessionNotificationContentView"]) {
        return NO;
    }
    return YES;
}


- (BOOL)shouldShowNickName:(NIMMessageModel *)model{
    NIMMessage *message = model.message;
    if (message.messageType == NIMMessageTypeNotification)
    {
        NIMNotificationType type = [(NIMNotificationObject *)message.messageObject notificationType];
        if (type == NIMNotificationTypeTeam) {
            return NO;
        }
    }
    return (!message.isOutgoingMsg && message.session.sessionType == NIMSessionTypeTeam);
}


- (NSString *)formatedMessage:(NIMMessageModel *)model{
    return [NIMKitUtil formatedMessage:model.message];
}




@end
