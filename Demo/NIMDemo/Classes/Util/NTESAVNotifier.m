//
//  NTESAVNotifier.m
//  NIM
//
//  Created by amao on 2017/5/4.
//  Copyright © 2017年 Netease. All rights reserved.
//

#import "NTESAVNotifier.h"
#import "NTESGlobalMacro.h"

@import AudioToolbox;


static void VibrateCompletion(SystemSoundID soundID, void *data)
{
    id notifier = (__bridge id)data;
    if([notifier isKindOfClass:[NTESAVNotifier class]])
    {
        SEL selector = NSSelectorFromString(@"vibrate");
        SuppressPerformSelectorLeakWarning([(NTESAVNotifier *)notifier performSelector:selector withObject:nil afterDelay:1.0]);
    }
}

@interface NTESAVNotifier ()
@property (nonatomic,strong)    UILocalNotification *currentNotification;
@property (nonatomic,assign)    BOOL shouldStopVibrate;
@property (nonatomic,assign)    NSInteger vibrateCount;

@end

@implementation NTESAVNotifier
- (instancetype)init
{
    if (self = [super init])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willEnterForeground:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)start:(NSString *)text
{
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground)
    {
        return;
    }
    [self stop];     
    _vibrateCount = 0;
    _shouldStopVibrate = NO;
    [self raiseNotification:text];
    [self vibrate];
    
}

- (void)stop
{
    if (_currentNotification)
    {
        [[UIApplication sharedApplication] cancelLocalNotification:_currentNotification];
        _currentNotification = nil;
    }
    _shouldStopVibrate = YES;
}

- (void)willEnterForeground:(NSNotification *)notification
{
    [self stop];
}

- (void)vibrate
{
    if (!_shouldStopVibrate)
    {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        AudioServicesAddSystemSoundCompletion(kSystemSoundID_Vibrate, NULL, NULL, VibrateCompletion, (__bridge void *)self);
        
        _vibrateCount++;
        if (_vibrateCount >= 15)
        {
            _shouldStopVibrate = YES;
        }
    }
}

- (void)raiseNotification:(NSString *)text
{
    _currentNotification = [[UILocalNotification alloc] init];
    _currentNotification.soundName = @"video_chat_push.mp3";
    _currentNotification.alertBody = text;
    
    [[UIApplication sharedApplication] presentLocalNotificationNow:_currentNotification];
}
@end
