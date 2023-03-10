
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NETabbarController.h"
#import "NENavigationController.h"

#import <NEChatUIKit/NEChatUIKit-Swift.h>
#import <NEContactUIKit/NEContactUIKit-Swift.h>
#import <NEConversationUIKit/NEConversationUIKit-Swift.h>
#import <NECoreIMKit/NECoreIMKit-Swift.h>
#import <NECoreKit/NECoreKit-Swift.h>
#import <NEQChatUIKit/NEQChatUIKit-Swift.h>

@interface NETabbarController ()

@end

@implementation NETabbarController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  [self setUpControllers];
}

- (void)setUpControllers {
  // 会话列表页
  ConversationController *sessionCtrl = [[ConversationController alloc] init];
  sessionCtrl.view.backgroundColor = [UIColor whiteColor];
  sessionCtrl.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"message", @"")
                                                         image:[UIImage imageNamed:@"chat"]
                                                 selectedImage:[UIImage imageNamed:@"chatSelect"]];
  NENavigationController *sessionNav =
      [[NENavigationController alloc] initWithRootViewController:sessionCtrl];

  // 通讯录
  ContactsViewController *contactCtrl = [[ContactsViewController alloc] init];
  contactCtrl.tabBarItem =
      [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"contact", @"")
                                    image:[UIImage imageNamed:@"contact"]
                            selectedImage:[UIImage imageNamed:@"contactSelect"]];
  NENavigationController *contactNav =
      [[NENavigationController alloc] initWithRootViewController:contactCtrl];

  // 圈组

  QChatHomeViewController *qchatCtrl = [[QChatHomeViewController alloc] init];
  qchatCtrl.tabBarItem =
      [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"qchat", @"")
                                    image:[UIImage imageNamed:@"qchat_tabbar_icon"]
                            selectedImage:[UIImage imageNamed:@"qchat_tabbar_icon"]];
  NENavigationController *qchatNav =
      [[NENavigationController alloc] initWithRootViewController:qchatCtrl];

  self.tabBar.backgroundColor = [UIColor whiteColor];
  self.viewControllers = @[ sessionNav, contactNav, qchatNav ];
  self.selectedIndex = 0;
}

@end
