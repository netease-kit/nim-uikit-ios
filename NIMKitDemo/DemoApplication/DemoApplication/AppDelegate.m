//
//  AppDelegate.m
//  DemoApplication
//
//  Created by chris on 15/10/7.
//  Copyright © 2015年 chris. All rights reserved.
//

#import "AppDelegate.h"
#import "NIMSDK.h"
#import "DataProvider.h"

#define NIMSDKAppKey @"8fc95f505b6cbaedf613677c8e08fc0b"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //注册APP，请将 NIMSDKAppKey 换成您自己申请的App Key
    [[NIMSDK sharedSDK] registerWithAppID:NIMSDKAppKey cerName:nil];
    //注入 NIMKit 内容提供者
    [[NIMKit sharedKit] setProvider:[DataProvider new]];
    return YES;
}


@end
