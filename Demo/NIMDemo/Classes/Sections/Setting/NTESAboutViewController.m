//
//  NTESAboutViewController.m
//  NIM
//
//  Created by chris on 15/7/30.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESAboutViewController.h"

@interface NTESAboutViewController ()

@end

@implementation NTESAboutViewController

- (void)viewDidLoad {
   [super viewDidLoad];
    self.navigationItem.title = @"关于";
    NSString *version = [NIMSDK sharedSDK].sdkVersion;
   self.versionLabel.text = [NSString stringWithFormat:@"版本号：%@",version];
}


@end
