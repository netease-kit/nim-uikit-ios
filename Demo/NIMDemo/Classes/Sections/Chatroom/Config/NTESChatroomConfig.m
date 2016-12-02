//
//  NTESChatroomConfig.m
//  NIM
//
//  Created by chris on 15/12/14.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import "NTESChatroomConfig.h"
#import "NTESChatroomMessageDataProvider.h"

@interface NTESChatroomConfig()

@property (nonatomic,strong) NTESChatroomMessageDataProvider *provider;

@end

@implementation NTESChatroomConfig

- (instancetype)initWithChatroom:(NSString *)roomId{
    self = [super init];
    if (self) {
        self.provider = [[NTESChatroomMessageDataProvider alloc] initWithChatroom:roomId];
    }
    return self;
}

- (id<NIMKitMessageProvider>)messageDataProvider{
    return self.provider;
}


- (NSArray<NSNumber *> *)inputBarItemTypes{
    return @[
               @(NIMInputBarItemTypeTextAndRecord),
               @(NIMInputBarItemTypeEmoticon),
               @(NIMInputBarItemTypeMore)
            ];
}


- (NSArray *)mediaItems
{
    return @[
             [NIMMediaItem item:@"onTapMediaItemJanKenPon:"
                    normalImage:[UIImage imageNamed:@"icon_jankenpon_normal"]
                  selectedImage:[UIImage imageNamed:@"icon_jankenpon_pressed"]
                          title:@"石头剪刀布"]];
}


- (BOOL)disableCharlet{
    return YES;
}

- (BOOL)autoFetchWhenOpenSession
{
    return NO;
}

- (BOOL)shouldHandleReceipt
{
    return NO;
}


@end
