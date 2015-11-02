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

@implementation NIMBaseSessionContentConfig
@end


@interface NIMSessionContentConfigFactory ()
@property (nonatomic,strong)    NSDictionary                *dict;
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
                  @(NIMMessageTypeNotification) :       [NIMNotificationContentConfig new]};
    }
    return self;
}

- (id<NIMSessionContentConfig>)configBy:(NIMMessage *)message
{
    NIMMessageType type = message.messageType;
    id<NIMSessionContentConfig>config = [_dict objectForKey:@(type)];
    if (config == nil)
    {
        config = [NIMUnsupportContentConfig sharedConfig];
    }
    if ([config isKindOfClass:[NIMBaseSessionContentConfig class]])
    {
        [(NIMBaseSessionContentConfig *)config setMessage:message];
    }
    return config;
}

@end