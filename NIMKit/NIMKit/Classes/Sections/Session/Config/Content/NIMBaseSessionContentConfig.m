//
//  NIMBaseSessionContentConfig.m
//  NIMKit
//
//  Created by amao on 9/15/15.
//  Copyright (c) 2015 NetEase. All rights reserved.
//

#import "NIMBaseSessionContentConfig.h"
#import "NIMTextContentConfig.h"
#import "NIMImageContentConfig.h"
#import "NIMAudioContentConfig.h"
#import "NIMVideoContentConfig.h"
#import "NIMFileContentConfig.h"
#import "NIMNotificationContentConfig.h"
#import "NIMLocationContentConfig.h"
#import "NIMUnsupportContentConfig.h"
#import "NIMTipContentConfig.h"
#import "NIMReplyedTextContentConfig.h"

@interface NIMSessionContentConfigFactory ()
@property (nonatomic,strong)    NSDictionary                *dict;
@property (nonatomic,strong)    NSDictionary                *replyDict;
@property (nonatomic,strong)    NIMUnsupportContentConfig   *unsupportConfig;
@end

@implementation NIMSessionContentConfigFactory

+ (instancetype)sharedFacotry
{
    static NIMSessionContentConfigFactory *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NIMSessionContentConfigFactory alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    if (self = [super init])
    {
        _dict = @{@(NIMMessageTypeText)         :       [NIMTextContentConfig new],
                  @(NIMMessageTypeImage)        :       [NIMImageContentConfig new],
                  @(NIMMessageTypeAudio)        :       [NIMAudioContentConfig new],
                  @(NIMMessageTypeVideo)        :       [NIMVideoContentConfig new],
                  @(NIMMessageTypeFile)         :       [NIMFileContentConfig new],
                  @(NIMMessageTypeLocation)     :       [NIMLocationContentConfig new],
                  @(NIMMessageTypeNotification) :       [NIMNotificationContentConfig new],
                  @(NIMMessageTypeTip)          :       [NIMTipContentConfig new]};
        
        NIMReplyedTextContentConfig *replyedTextConfig = [NIMReplyedTextContentConfig new];
        _replyDict = @{
                        @(NIMMessageTypeText)       : replyedTextConfig,
                        @(NIMMessageTypeAudio)      : replyedTextConfig,
                        @(NIMMessageTypeVideo)      : replyedTextConfig,
                        @(NIMMessageTypeFile)       : replyedTextConfig,
                        @(NIMMessageTypeTip)        : replyedTextConfig,
                        @(NIMMessageTypeRobot)      : replyedTextConfig,
                        @(NIMMessageTypeNotification)   : replyedTextConfig,
                        @(NIMMessageTypeLocation)   : replyedTextConfig,
                        @(NIMMessageTypeCustom)     : replyedTextConfig,
                        @(NIMMessageTypeImage)      : replyedTextConfig,
                        };
        _unsupportConfig = [[NIMUnsupportContentConfig alloc] init];
    }
    return self;
}

- (id<NIMSessionContentConfig>)replyConfigBy:(NIMMessage *)message
{
    NIMMessageType type = message.messageType;
    id<NIMSessionContentConfig>config = [_replyDict objectForKey:@(type)];
    if (config == nil)
    {
        config = _unsupportConfig;
    }
    return config;
}

- (id<NIMSessionContentConfig>)configBy:(NIMMessage *)message
{
    NIMMessageType type = message.messageType;
    id<NIMSessionContentConfig>config = [_dict objectForKey:@(type)];
    if (config == nil)
    {
        config = _unsupportConfig;
    }
    return config;
}

@end
