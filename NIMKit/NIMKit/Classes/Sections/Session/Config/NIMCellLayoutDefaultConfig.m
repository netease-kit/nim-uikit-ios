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

@implementation NIMCellLayoutDefaultConfig

- (CGSize)contentSize:(NIMMessageModel *)model cellWidth:(CGFloat)cellWidth{
    NIMMessage *message = model.message;
    CGFloat UnknowMessageWidth = 100.f;
    CGFloat UnknowMessageHeight = 40.f;
    CGSize  contentSize = CGSizeMake(UnknowMessageWidth, UnknowMessageHeight);
    switch (message.messageType) {
        case NIMMessageTypeText:{
            NIMAttributedLabel *label = [[NIMAttributedLabel alloc] initWithFrame:CGRectZero];
            label.font = [UIFont systemFontOfSize:NIMKit_Message_Font_Size];
            NSString *text = message.text;
            [label nim_setText:text];
            
            CGFloat msgBubbleMaxWidth    = (cellWidth - 130);
            CGFloat bubbleLeftToContent  = 14;
            CGFloat contentRightToBubble = 14;
            CGFloat msgContentMaxWidth = (msgBubbleMaxWidth - contentRightToBubble - bubbleLeftToContent);
            contentSize = [label sizeThatFits:CGSizeMake(msgContentMaxWidth, CGFLOAT_MAX)];
            break;
        }
        case NIMMessageTypeAudio:{
            NIMAudioObject *audioContent = (NIMAudioObject*)[message messageObject];
            //使用公式 长度 = (最长－最小)*(2/pi)*artan(时间/10)+最小，在10秒时变化逐渐变缓，随着时间增加 无限趋向于最大值
            CGFloat value  = 2*atan((audioContent.duration/1000.0-1)/10.0)/M_PI;
            
            NSInteger audioContentMinWidth = (cellWidth - 280);
            NSInteger audioContentMaxWidth = (cellWidth - 170);
            NSInteger audioContentHeight   = 30;
            contentSize.width = (audioContentMaxWidth - audioContentMinWidth)* value + audioContentMinWidth;
            contentSize.height = audioContentHeight;
            break;
        }
        case NIMMessageTypeVideo:{
            CGFloat attachmentImageMinWidth  = (cellWidth / 4.0);
            CGFloat attachmentImageMinHeight = (cellWidth / 4.0);
            CGFloat attachmemtImageMaxWidth  = (cellWidth - 184);
            CGFloat attachmentImageMaxHeight = (cellWidth - 184);
            contentSize = CGSizeMake(attachmentImageMinWidth, attachmentImageMinHeight);
            NIMVideoObject *videoObject = (NIMVideoObject*)[message messageObject];
            if (!CGSizeEqualToSize(videoObject.coverSize, CGSizeZero)) {
                //有封面就直接拿封面大小
                contentSize = [UIImage nim_sizeWithImageOriginSize:videoObject.coverSize minSize:CGSizeMake(attachmentImageMinWidth, attachmentImageMinHeight) maxSize:CGSizeMake(attachmemtImageMaxWidth, attachmentImageMaxHeight )];
            }
            break;
        }
        case NIMMessageTypeImage:{
            CGFloat attachmentImageMinWidth  = (cellWidth / 4.0);
            CGFloat attachmentImageMinHeight = (cellWidth / 4.0);
            CGFloat attachmemtImageMaxWidth  = (cellWidth - 184);
            CGFloat attachmentImageMaxHeight = (cellWidth - 184);
            contentSize = CGSizeMake(attachmentImageMinWidth, attachmentImageMinHeight);
            NIMImageObject *imageObject = (NIMImageObject*)[message messageObject];
            if (!CGSizeEqualToSize(imageObject.size, CGSizeZero)) {
                contentSize = [UIImage nim_sizeWithImageOriginSize:imageObject.size minSize:CGSizeMake(attachmentImageMinWidth, attachmentImageMinHeight) maxSize:CGSizeMake(attachmemtImageMaxWidth, attachmentImageMaxHeight )];
            }
            break;
        }
        case NIMMessageTypeFile:{
            CGFloat FileMessageWidth             = 220;
            CGFloat FileMessageHeight            = 110;
            contentSize = CGSizeMake(FileMessageWidth, FileMessageHeight);
            break;
        }
        case NIMMessageTypeNotification:{
            NIMNotificationObject *object = message.messageObject;
            switch (object.notificationType) {
                case NIMNotificationTypeTeam:{
                    CGFloat TeamNotificationMessageWidth  = cellWidth;
                    CGFloat TeamNotificationMessageHeight = 40;
                    contentSize = CGSizeMake(TeamNotificationMessageWidth, TeamNotificationMessageHeight);
                    break;
                }
                case NIMNotificationTypeNetCall:{
                    NIMAttributedLabel *label = [[NIMAttributedLabel alloc] initWithFrame:CGRectZero];
                    label.font = [UIFont systemFontOfSize:NIMKit_Message_Font_Size];
                    NSString *text = [NIMKitUtil formatedMessage:message];
                    [label nim_setText:text];
                    
                    CGFloat msgBubbleMaxWidth    = (cellWidth - 130);
                    CGFloat bubbleLeftToContent  = 14;
                    CGFloat contentRightToBubble = 14;
                    CGFloat msgContentMaxWidth = (msgBubbleMaxWidth - contentRightToBubble - bubbleLeftToContent);
                    contentSize = [label sizeThatFits:CGSizeMake(msgContentMaxWidth, CGFLOAT_MAX)];
                    break;
                }
                default:
                    contentSize = CGSizeZero;
                    break;
            }
            break;
        }
        case NIMMessageTypeLocation:{
            CGFloat locationMessageWidth  = 110.f;
            CGFloat locationMessageHeight = 105.f;
            contentSize = CGSizeMake(locationMessageWidth, locationMessageHeight);
            break;
        }
        default:
            break;
    }
    return contentSize;
}

- (NSString *)cellContent:(NIMMessageModel *)model{
    NSString *contentStr;
    NIMMessage *message = model.message;
    if (message.messageType == NIMMessageTypeNotification) {
        NIMNotificationObject *notificationObject = message.messageObject;
        contentStr                      = self.supportType[@(notificationObject.notificationType)];
    }else{
        contentStr = self.contentClass[@(message.messageType)];
    }
    contentStr = contentStr.length ? contentStr : @"NIMSessionUnknowContentView";
    return contentStr;
}


- (UIEdgeInsets)contentViewInsets:(NIMMessageModel *)model{
    NIMMessage *message = model.message;
    if (message.messageType == NIMMessageTypeNotification) {
        if (message.isOutgoingMsg) {
            return [self myNotificationContentViewInsets:message];
        }else{
            return [self otherNotificationContentViewInsets:message];
        }
    }
    NSDictionary *dict;
    if (message.isOutgoingMsg) {
        dict = [self myContentViewInsets];
    }else{
        dict = [self otherContentViewInsets];
    }
    
    if ([dict.allKeys indexOfObject:@(message.messageType)] != NSNotFound ) {
        return [dict[@(message.messageType)] UIEdgeInsetsValue];
    }else{
        return [self unSupportContentViewInsets:message];
    }
}


- (UIEdgeInsets)cellInsets:(NIMMessageModel *)model{
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

- (BOOL)shouldShowAudioPlayedStatusIcon:(NIMMessageModel *)model{
    return YES;
}

- (NSString *)formatedMessage:(NIMMessageModel *)model{
    return [NIMKitUtil formatedMessage:model.message];
}

#pragma mark - Private

- (NSDictionary *)contentClass{
    static NSDictionary *nimkit_contentClass;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        nimkit_contentClass = @{
                                  @(NIMMessageTypeText):@"NIMSessionTextContentView",
                                  @(NIMMessageTypeAudio):@"NIMSessionAudioContentView",
                                  @(NIMMessageTypeVideo):@"NIMSessionVideoContentView",
                                  @(NIMMessageTypeFile):@"NIMSessionFileTransContentView",
                                  @(NIMMessageTypeImage):@"NIMSessionImageContentView",
                                  @(NIMMessageTypeLocation):@"NIMSessionLocationContentView",
                                };
    });
    return nimkit_contentClass;
}


- (NSDictionary *)myContentViewInsets{
    static NSDictionary *nimkit_myContentViewInsets;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        nimkit_myContentViewInsets = @{
                                @(NIMMessageTypeText):[NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(11,11,9,15)],
                                @(NIMMessageTypeAudio):[NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(8,12,9,14)],
                                @(NIMMessageTypeVideo):[NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(3,3,3,8)],
                                @(NIMMessageTypeFile):[NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(3,3,3,8)],
                                @(NIMMessageTypeImage):[NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(3,3,3,8)],
                                @(NIMMessageTypeLocation):[NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(3,3,3,8)],
                                };
    });
    return nimkit_myContentViewInsets;
}

- (NSDictionary *)otherContentViewInsets{
    static NSDictionary *nimkit_otherContentViewInsets;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        nimkit_otherContentViewInsets = @{
                                       @(NIMMessageTypeText):[NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(11,15,9,9)],
                                       @(NIMMessageTypeAudio):[NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(8,13,9,12)],
                                       @(NIMMessageTypeVideo):[NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(3,8,3,3)],
                                       @(NIMMessageTypeFile):[NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(3,8,3,3)],
                                       @(NIMMessageTypeImage):[NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(3,8,3,3)],
                                       @(NIMMessageTypeLocation):[NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(3,8,3,3)],
                                       };
    });
    return nimkit_otherContentViewInsets;
}


- (UIEdgeInsets)myNotificationContentViewInsets:(NIMMessage *)message{
    NIMNotificationType type = [(NIMNotificationObject *)message.messageObject notificationType];
    switch (type) {
        case NIMNotificationTypeNetCall:
            return UIEdgeInsetsMake(11,11,9,15);
        case NIMNotificationTypeTeam:
            return UIEdgeInsetsZero;
        default:
            return [self unSupportContentViewInsets:message];
    }
}

- (UIEdgeInsets)otherNotificationContentViewInsets:(NIMMessage *)message{
    NIMNotificationType type = [(NIMNotificationObject *)message.messageObject notificationType];
    switch (type) {
        case NIMNotificationTypeNetCall:
            return UIEdgeInsetsMake(11,15,9,9);
        case NIMNotificationTypeTeam:
            return UIEdgeInsetsZero;
        default:
            return [self unSupportContentViewInsets:message];
    }
}


- (NSDictionary *)supportType{
    static NSDictionary *supportType;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        supportType = @{@(NIMNotificationTypeTeam):@"NIMSessionNotificationContentView",
                        @(NIMNotificationTypeNetCall):@"NIMSessionNetChatNotifyContentView"};
    });
    return supportType;
}


- (UIEdgeInsets)unSupportContentViewInsets:(NIMMessage *)message
{
    CGFloat selfBubbleTopToContentForText     = 11.f;
    CGFloat selfBubbleLeftToContentForText    = 11.f;
    CGFloat selfContentButtomToBubbleForText  = 9.f;
    CGFloat selfBubbleRightToContentForText   = 15.f;
    
    CGFloat otherBubbleTopToContentForText    = 11.f;
    CGFloat otherBubbleLeftToContentForText   = 15.f;
    CGFloat otherContentButtomToBubbleForText = 9.f;
    CGFloat otherContentRightToBubbleForText  = 9.f;
    
    BOOL isFromMe = message.isOutgoingMsg;
    return isFromMe ? UIEdgeInsetsMake(selfBubbleTopToContentForText,
                                       selfBubbleLeftToContentForText,
                                       selfContentButtomToBubbleForText,
                                       selfBubbleRightToContentForText):
    UIEdgeInsetsMake(otherBubbleTopToContentForText,
                     otherBubbleLeftToContentForText,
                     otherContentButtomToBubbleForText,
                     otherContentRightToBubbleForText);
    
}
@end
