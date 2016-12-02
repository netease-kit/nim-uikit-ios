//
//  NTESSessionCustomContentConfig.m
//  NIM
//
//  Created by chris on 16/1/14.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESSessionCustomContentConfig.h"
#import "NTESCustomAttachmentDefines.h"

@interface NTESSessionCustomContentConfig()

@end

@implementation NTESSessionCustomContentConfig

- (CGSize)contentSize:(CGFloat)cellWidth message:(NIMMessage *)message
{
    NIMCustomObject *object = message.messageObject;
    NSAssert([object isKindOfClass:[NIMCustomObject class]], @"message must be custom");
    id<NTESCustomAttachmentInfo> info = (id<NTESCustomAttachmentInfo>)object.attachment;
    return [info contentSize:message cellWidth:cellWidth];
}

- (NSString *)cellContent:(NIMMessage *)message
{
    NIMCustomObject *object = message.messageObject;
    NSAssert([object isKindOfClass:[NIMCustomObject class]], @"message must be custom");
    id<NTESCustomAttachmentInfo> info = (id<NTESCustomAttachmentInfo>)object.attachment;
    return [info cellContent:message];
}

- (UIEdgeInsets)contentViewInsets:(NIMMessage *)message
{
    NIMCustomObject *object = message.messageObject;
    NSAssert([object isKindOfClass:[NIMCustomObject class]], @"message must be custom");
    id<NTESCustomAttachmentInfo> info = (id<NTESCustomAttachmentInfo>)object.attachment;
    return [info contentViewInsets:message];
}


@end
