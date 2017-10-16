//
//  NTESViewController.m
//  DemoApplication
//
//  Created by chris on 15/10/7.
//  Copyright © 2015年 chris. All rights reserved.
//

#import "NTESViewController.h"
#import "NIMKit.h"
#import "NTESSessionListViewController.h"

#define NIMMyAccount   @"lilei"
#define NIMMyToken     @"123456"
@interface NTESViewController ()

@end

@implementation NTESViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = @"登录";
}


- (IBAction)login:(id)sender{
    //请将 NIMMyAccount 以及 NIMMyToken 替换成您自己提交到此App下的账号和密码
    [[NIMSDK sharedSDK].loginManager login:NIMMyAccount token:NIMMyToken completion:^(NSError *error) {
        if (!error) {
            NSLog(@"登录成功");
            //创建会话列表页
            NTESSessionListViewController *vc = [[NTESSessionListViewController alloc] initWithNibName:nil bundle:nil];
            [self.navigationController pushViewController:vc animated:YES];
        }else{
            NSLog(@"登录失败");
        }
    }];
}

@end
