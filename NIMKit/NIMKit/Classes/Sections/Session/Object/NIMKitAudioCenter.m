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

@property (nonatomic,assign) NSInteger retryCount;

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
        [self resetRetryCount];
    }
    return self;
}

- (void)resetRetryCount
{
    _retryCount = 3;
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
    if (error)
    {
        if (_retryCount > 0)
        {
            _retryCount--;
            // iPhone4 和 iPhone 4S 上连播会由于设备释放过慢导致 AudioQueue 启动不了的问题，这里做个延迟重试，最多重试 3 次 ( code -66681 )
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[NIMSDK sharedSDK].mediaManager play:filePath];
            });
        }
        else
        {
            self.currentPlayingMessage = nil;
            [self resetRetryCount];
        }

    }
    else
    {
        [self resetRetryCount];
    }
}

- (void)stopPlayAudio:(NSString *)filePath didCompletedWithError:(nullable NSError *)error
{
    self.currentPlayingMessage = nil;
}


- (void)playAudio:(NSString *)filePath didCompletedWithError:(nullable NSError *)error
{
    self.currentPlayingMessage = nil;
}


@end
