
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NENavigationController.h"

@interface NENavigationController ()

@end

@implementation NENavigationController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setUpNavigation];
}

- (void)setUpNavigation {
  if (@available(iOS 13.0, *)) {
    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    appearance.backgroundImage = [UIImage new];
    appearance.backgroundColor = [UIColor whiteColor];
    appearance.shadowColor = [UIColor whiteColor];
    self.navigationBar.standardAppearance = appearance;
    self.navigationBar.scrollEdgeAppearance = appearance;
  }
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
  if (self.childViewControllers.count > 0) {
    viewController.hidesBottomBarWhenPushed = YES;
    if (self.childViewControllers.count > 1) {
      viewController.hidesBottomBarWhenPushed = NO;
    }
  }
  [super pushViewController:viewController animated:animated];
}

@end
