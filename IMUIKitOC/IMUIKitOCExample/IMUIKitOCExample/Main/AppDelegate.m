
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "AppDelegate.h"
#import <YXLogin/AuthorManager.h>
#import "AppKey.h"
#import "NETabbarController.h"

#import <NEChatUIKit/NEChatUIKit-Swift.h>
#import <NEContactUIKit/NEContactUIKit-Swift.h>
#import <NEConversationUIKit/NEConversationUIKit-Swift.h>
#import <NECoreIMKit/NECoreIMKit-Swift.h>
#import <NECoreKit/NECoreKit-Swift.h>
//#import <NEQChatUIKit/NEQChatUIKit-Swift.h>
#import "CustomRouterViewController.h"

@import NIMSDK;

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  self.window = [[UIWindow alloc] init];
  self.window.backgroundColor = [UIColor whiteColor];
  self.window.frame = UIScreen.mainScreen.bounds;
  [self.window makeKeyAndVisible];
  UIViewController *controller = [[UIViewController alloc] init];
  self.window.rootViewController = controller;
  [self setupInit];
  return YES;
}

- (void)setupInit {
    // 初始化NIMSDK
    NIMSDKOption *option = [NIMSDKOption optionWithAppKey:AppKey];
    option.apnsCername = @"";
    option.pkCername = @"";
    [[IMKitClient instance] setupCoreKitIM:option];
    
    // 登录IM之前先初始化 @ 消息监听mananger
    NEAtMessageManager * _ = [NEAtMessageManager instance];
    
    [[IMKitClient instance] loginIM:@"imaccid" :@"imToken" :^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"NEKitCore login error : %@", [error description]);
        } else {
            [self setupTabbar];
        }
    }];
}

- (void)setupTabbar {
  self.window.rootViewController = [[NETabbarController alloc] init];
  [self registerRouter];
}

// 注册路由
- (void)registerRouter {
  [ChatRouter register];
  [ConversationRouter register];
  [ContactRouter register];

  [[Router shared] register:@"imkit://chat/p2pChat.page"
                    closure:^(NSDictionary<NSString *, id> *_Nonnull param) {
                      NSObject *param1 = [param objectForKey:@"nav"];
                      if ([param1 isKindOfClass:[UINavigationController class]]) {
                        UINavigationController *nav = (UINavigationController *)param1;
                        CustomRouterViewController *controller =
                            [[CustomRouterViewController alloc] init];

                        [nav pushViewController:controller animated:YES];
                      }
                    }];
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application
    supportedInterfaceOrientationsForWindow:(UIWindow *)window {
  return UIInterfaceOrientationMaskPortrait;
}

@end
