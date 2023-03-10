// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "CustomRouterViewController.h"

@interface CustomRouterViewController ()

@end

@implementation CustomRouterViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  UILabel *tipLabel = [[UILabel alloc] init];
  tipLabel.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:tipLabel];
  tipLabel.text = @"自定义路由测试页面";
  tipLabel.textAlignment = NSTextAlignmentCenter;
  tipLabel.textColor = [UIColor blackColor];
  [NSLayoutConstraint activateConstraints:@[
    [tipLabel.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
    [tipLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
  ]];
  self.navigationController.navigationBarHidden = NO;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before
navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
