//
//  NIMKitAudioCenter.m
//  NIMKit
//
//  Created by chris on 2017/1/13.
//  Copyright © 2017年 NetEase. All rights reserved.
//

#import "NIMKitAudioCenter.h"
#import <NIMSDK/NIMSDK.h>

@interface NIMKitAudioCenter()<NIMMediaManagerDelegate>

@end

@implementation NIMKitAudioCenter

+ (instancetype)instance
{
    static NIMKitAudioCenter *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NIMKitAudioCenter alloc] init];
    });
    return instance;
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NIMSDK sharedSDK].mediaManager addDelegate:self];
    }
    return self;
}

- (void)play:(NIMMessage *)message
{
    NIMAudioObject *audioObject = (NIMAudioObject *)message.messageObject;
    if ([audioObject isKindOfClass:[NIMAudioObject class]]) {
        self.currentPlayingMessage = message;
        message.isPlayed = YES;
        
        [[NIMSDK sharedSDK].mediaManager play:audioObject.path];
    }
}


#pragma mark - NIMMediaManagerDelegate

- (void)playAudio:(NSString *)filePath didBeganWithError:(NSError *)error
{
    if (error) {
        self.currentPlayingMessage = nil;
    }
}


- (void)playAudio:(NSString *)filePath didCompletedWithError:(nullable NSError *)error
{
    self.currentPlayingMessage = nil;
}


@end
