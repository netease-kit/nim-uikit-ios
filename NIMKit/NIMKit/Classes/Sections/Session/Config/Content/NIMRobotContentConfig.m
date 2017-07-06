//
//  NIMRobotContentConfig.m
//  NIMKit
//
//  Created by chris on 2017/6/27.
//  Copyright © 2017年 NetEase. All rights reserved.
//

#import "NIMRobotContentConfig.h"
#import "M80AttributedLabel+NIMKit.h"
#import "NIMKitUIConfig.h"
#import "NIMSessionRobotContentView.h"
#import "UIView+NIM.h"

@interface NIMRobotContentConfig()

@property (nonatomic,strong) M80AttributedLabel *label;

@property (nonatomic,strong) NIMSessionRobotContentView *robotContentView;

@property (nonatomic,strong) NIMMessageModel *robotModel;

@end

@implementation NIMRobotContentConfig

- (CGSize)contentSize:(CGFloat)cellWidth message:(NIMMessage *)message
{
    CGFloat msgBubbleMaxWidth    = (cellWidth - 130);
    if ([self isFromRobot:message])
    {
        self.robotModel.message = message;
        self.robotContentView.nim_width = msgBubbleMaxWidth;
        [self.robotContentView setupRobot:self.robotModel];
        
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
         return @"NIMSessionRobotContentView";
    }
    else
    {
        return @"NIMSessionTextContentView";
    }
}

- (UIEdgeInsets)contentViewInsets:(NIMMessage *)message
{
    NIMKitBubbleConfig *config = [[NIMKitUIConfig sharedConfig] bubbleConfig:message];
    return config.contentInset;
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
    _label.font = [UIFont systemFontOfSize:NIMKit_Message_Font_Size];
    return _label;
}

- (NIMSessionRobotContentView *)robotContentView
{
    if (_robotContentView)
    {
        return _robotContentView;
    }
    _robotContentView = [[NIMSessionRobotContentView alloc] initSessionMessageContentView];
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
