//
//  NTESLogManager.m
//  NIM
//
//  Created by Xuhui on 15/4/1.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESLogManager.h"
#import "NTESLogViewController.h"
#import "NTESBundleSetting.h"

@interface NTESLogManager () {
    DDFileLogger *_fileLogger;
}

@end

@implementation NTESLogManager

+ (instancetype)sharedManager
{
    static NTESLogManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NTESLogManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if(self) {
        [DDLog addLogger:[DDASLLogger sharedInstance]];
        [DDLog addLogger:[DDTTYLogger sharedInstance]];
        [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
        [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor greenColor] backgroundColor:nil forFlag:DDLogFlagDebug];
        _fileLogger = [[DDFileLogger alloc] init];
        _fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
        _fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
        [DDLog addLogger:_fileLogger];
    }
    return self;
}

- (void)start
{
    DDLogInfo(@"App Started SDK Version %@\nBundle Setting: %@",[[NIMSDK sharedSDK] sdkVersion],[NTESBundleSetting sharedConfig]);
}

- (UIViewController *)demoLogViewController {
    NSString *filepath = _fileLogger.currentLogFileInfo.filePath;
    NTESLogViewController *vc = [[NTESLogViewController alloc] initWithFilepath:filepath];
    vc.title = @"Demo Log";
    return vc;
}

- (UIViewController *)sdkLogViewController
{
    NSString *filepath = [[NIMSDK sharedSDK] currentLogFilepath];
    NTESLogViewController *vc = [[NTESLogViewController alloc] initWithFilepath:filepath];
    vc.title = @"SDK Log";
    return vc;
}

- (UIViewController *)sdkNetCallLogViewController
{
    NSString *filepath = [[NIMAVChatSDK sharedSDK].netCallManager netCallLogFilepath];
    NTESLogViewController *vc = [[NTESLogViewController alloc] initWithFilepath:filepath];
    vc.title = @"NetCall Log";
    return vc;
}

- (UIViewController *)sdkNetDetectLogViewController
{
    NSString *filepath = [[NIMAVChatSDK sharedSDK].avchatNetDetectManager logFilepath];
    NTESLogViewController *vc = [[NTESLogViewController alloc] initWithFilepath:filepath];
    vc.title = @"Net Detect Log";
    return vc;
}



- (UIViewController *)demoConfigViewController
{
    NSString *content = [NSString stringWithFormat:@"SDK Config:\n%@\nDemo Config:\n%@\n",[NIMSDKConfig sharedConfig],[NTESBundleSetting sharedConfig]];
    NTESLogViewController *vc = [[NTESLogViewController alloc] initWithContent:content];
    vc.title = @"Demo Config";
    return vc;
}

@end
