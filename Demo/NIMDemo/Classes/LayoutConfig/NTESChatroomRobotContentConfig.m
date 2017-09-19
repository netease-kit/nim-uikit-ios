//
//  NTESChatroomRobotContentConfig.m
//  NIM
//
//  Created by chris on 2017/8/21.
//  Copyright © 2017年 Netease. All rights reserved.
//

#import "NTESChatroomRobotContentConfig.h"
#import "M80AttributedLabel+NIMKit.h"
#import "NIMKitUIConfig.h"
#import "NTESSessionRobotContentView.h"
#import "UIView+NIM.h"

@interface NTESChatroomRobotContentConfig()

@property (nonatomic,strong) M80AttributedLabel *label;

@property (nonatomic,strong) NTESSessionRobotContentView *robotContentView;

@property (nonatomic,strong) NIMMessageModel *robotModel;
@end

@implementation NTESChatroomRobotContentConfig

- (CGSize)contentSize:(CGFloat)cellWidth message:(NIMMessage *)message
{
    CGFloat msgBubbleMaxWidth    = (cellWidth - 130);
    if ([self isFromRobot:message])
    {
        self.robotModel.message = message;
        self.robotContentView.nim_width = msgBubbleMaxWidth;
        [self.robotContentView setupRobot:self.robotModel];
        [self.robotContentView layoutIfNeeded];
        
        CGSize size = [self.robotContentView sizeThatFits:CGSizeMake(msgBubbleMaxWidth, CGFLOAT_MAX)];
        return size;
    }
    else
    {
        NSString *text = message.text;
        [self.label nim_setText:text];
        
        CGFloat bubbleLeftToContent  = 14;
        CGFloat contentRightToBubble = 14;
        CGFloat msgContentMaxWidth = (msgBubbleMaxWidth - contentRightToBubble - bubbleLeftToContent);
        return [self.label sizeThatFits:CGSizeMake(msgContentMaxWidth, CGFLOAT_MAX)];
    }
}

- (NSString *)cellContent:(NIMMessage *)message
{
    if ([self isFromRobot:message])
    {
        return @"NTESSessionRobotContentView";
    }
    else
    {
        return @"NTESChatroomTextContentView";
    }
}

- (UIEdgeInsets)contentViewInsets:(NIMMessage *)message
{
    if ([self isFromRobot:message])
    {
        return UIEdgeInsetsMake(9,15,10,0);
    }
    else
    {
        return UIEdgeInsetsMake(20,15,10,0);
    }
}


#pragma mark - Private
- (BOOL)isFromRobot:(NIMMessage *)message
{
    NIMRobotObject *object = (NIMRobotObject *)message.messageObject;
    return object.isFromRobot;
}

- (M80AttributedLabel *)label
{
    if (_label)
    {
        return _label;
    }
    _label = [[M80AttributedLabel alloc] initWithFrame:CGRectZero];
    _label.font = [UIFont systemFontOfSize:Chatroom_Message_Font_Size];
    return _label;
}

- (NTESSessionRobotContentView *)robotContentView
{
    if (_robotContentView)
    {
        return _robotContentView;
    }
    _robotContentView = [[NTESSessionRobotContentView alloc] initSessionMessageContentView];
    return _robotContentView;
}

- (NIMMessageModel *)robotModel
{
    if (_robotModel)
    {
        return _robotModel;
    }
    _robotModel = [[NIMMessageModel alloc] init];
    return _robotModel;
}

@end
