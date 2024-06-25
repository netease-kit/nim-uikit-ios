
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
#import <NETeamUIKit/NETeamUIKit-Swift.h>
#import <NECoreIM2Kit/NECoreIM2Kit-Swift.h>
#import <NECoreKit/NECoreKit-Swift.h>
// #import <NEQChatUIKit/NEQChatUIKit-Swift.h>
#import "CustomRouterViewController.h"
#import "IMUIKitOCExample-Swift.h"

@import NIMSDK;

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  self.window = [[UIWindow alloc] init];
  self.window.frame = [[UIScreen mainScreen] bounds];
  [self.window makeKeyAndVisible];
  [self.window makeKeyWindow];
  UIViewController *root = [[UIViewController alloc] init];
  root.view.backgroundColor = [UIColor whiteColor];
  self.window.backgroundColor = [UIColor clearColor];
  self.window.rootViewController = root;
  [self setupInit];
  return YES;
}

- (void)setupInit {
  // 初始化NIMSDK
  NIMSDKOption *option = [NIMSDKOption optionWithAppKey:AppKey];
  option.v2 = YES;
  [[IMKitClient instance] setupIM:option];

  // 统一登录组件
  YXConfig *config = [[YXConfig alloc] init];
  config.appKey = AppKey;
  config.parentScope = @2;
  config.scope = @7;
  config.supportInternationalize = false;
  config.type = YXLoginPhone;

#ifdef DEBUG
  config.isOnline = NO;
#else
  config.isOnline = YES;
#endif
  [[AuthorManager shareInstance] initAuthorWithConfig:config];
  if ([AuthorManager shareInstance].canAutologin) {
    [[AuthorManager shareInstance]
        autoLoginWithCompletion:^(YXUserInfo *_Nullable userinfo, NSError *_Nullable error) {
          if (error) {
            NSLog(@"auto login failed,error = %@", error);
          } else {
            [self setupXKit:userinfo];
          }
        }];
  } else {
    [self loginWithUI];
  }
}

- (void)loginWithUI {
  [[AuthorManager shareInstance]
      startLoginWithCompletion:^(YXUserInfo *_Nullable userinfo, NSError *_Nullable error) {
        if (!error) {
          [self setupXKit:userinfo];
        } else {
          NSLog(@"login failed,error = %@", error);
        }
      }];
}

- (void)setupXKit:(YXUserInfo *)user {
  // 登录云信IM
  if (user.imToken && user.imAccid) {
    [[IMKitClient instance] login:user.imAccid :user.imToken : nil :^(NSError * _Nullable error) {
            if (!error) {
                [ChatRouter setupInit];
                [self setupTabbar];
                //登录圈组模块，如不需要圈组功能则不用登录
//                QChatLoginParam *parama = [[QChatLoginParam alloc]init:user.imAccid :user.imToken];
//                [[IMKitClient instance] loginQchat:parama completion:^(NSError * _Nullable error, QChatLoginResult * _Nullable result) {
//                    if (!error) {
//                        [self setupTabbar];
//                    }else {
//                        NSLog(@"qchat login failed,error = %@",error);
//                    }
//                }];
                
            }else {
                NSLog(@"loginIM failed,error = %@",error);
            }
        }];
  } else {
    NSLog(@"parameter is nil");
  }
}

- (void)setupTabbar {
  self.window.backgroundColor = [UIColor whiteColor];
  self.window.rootViewController = [[NETabbarController alloc] init];
  [self registerRouter];
}

- (void)customClick {
  NSLog(@"custom more action click");
}

// 注册路由
- (void)registerRouter {
  [ChatRouter register];
  [ConversationRouter register];
  [ContactRouter register];
  [TeamRouter register];

  // 聊天页面自定义面板示例
  /*
  NEMoreItemModel *item = [[NEMoreItemModel alloc] init];
  item.title = @"自定义";
  item.customDelegate = self;
  item.action = @selector(customClick);
  item.image = [UIImage imageNamed:@"chatSelect"];
  NSMutableArray *muta = [[NSMutableArray alloc] initWithArray:
  NEChatUIKitClient.instance.moreAction];
  [muta addObject:item];
  NEChatUIKitClient.instance.moreAction = muta;
  */

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
