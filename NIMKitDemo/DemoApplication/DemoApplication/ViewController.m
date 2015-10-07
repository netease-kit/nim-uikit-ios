//
//  ViewController.m
//  DemoApplication
//
//  Created by chris on 15/10/7.
//  Copyright © 2015年 chris. All rights reserved.
//

#import "ViewController.h"
#import "NIMKit.h"
#import "SessionViewController.h"

#define NIMMyAccount   @"lilei"
#define NIMMyToken     @"123456"
#define NIMChatTarget  @"hanmeimei"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"登录";
}


- (IBAction)login:(id)sender{
    //请将 NIMMyAccount 以及 NIMMyToken 替换成您自己提交到此App下的账号和密码
    [[NIMSDK sharedSDK].loginManager login:NIMMyAccount token:NIMMyToken completion:^(NSError *error) {
        if (!error) {
            NSLog(@"登录成功");
            //创建session,这里聊天对象预设为韩梅梅，此账号也是事先提交到此App下的
            NIMSession *session = [NIMSession session:NIMChatTarget type:NIMSessionTypeP2P];
            //创建聊天页，这个页面继承自 NIMKit 中的组件 NIMSessionViewController
            SessionViewController *vc = [[SessionViewController alloc] initWithSession:session];
            [self.navigationController pushViewController:vc animated:YES];
        }else{
            NSLog(@"登录失败");
        }
    }];
}

@end
