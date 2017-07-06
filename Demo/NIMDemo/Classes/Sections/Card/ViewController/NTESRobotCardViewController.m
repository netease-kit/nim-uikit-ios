//
//  NTESRobotCardViewController.m
//  NIM
//
//  Created by chrisRay on 2017/7/1.
//  Copyright © 2017年 Netease. All rights reserved.
//

#import "NTESRobotCardViewController.h"
#import "NTESColorButtonCell.h"
#import "UIView+NTES.h"
#import "NTESSessionViewController.h"

@interface NTESRobotCardViewController ()

@property (nonatomic,strong) NSString *userId;

@property (nonatomic,strong) NTESColorButton *chatButton;

@end

@implementation NTESRobotCardViewController

- (instancetype)initWithUserId:(NSString *)userId
{
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        _userId = userId;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self refresh];
    self.chatButton = [[NTESColorButton alloc] initWithFrame:CGRectZero];
    self.chatButton.style = ColorButtonCellStyleBlue;
    [self.chatButton addTarget:self action:@selector(chat:) forControlEvents:UIControlEventTouchUpInside];
    [self.chatButton setTitle:@"开始对话" forState:UIControlStateNormal];
    [self.chatButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.view addSubview:self.chatButton];
}

- (void)chat:(id)sender
{
    NIMSession *session = [NIMSession session:self.userId type:NIMSessionTypeP2P];
    NTESSessionViewController *vc = [[NTESSessionViewController alloc] initWithSession:session];
    [self.navigationController pushViewController:vc animated:YES];
}


- (void)refresh
{
    NIMKitInfo *info = [[NIMKit sharedKit].provider infoByUser:self.userId option:nil];
    NSURL *url = [NSURL URLWithString:info.avatarUrlString];
    [self.avatarImageView nim_setImageWithURL:url placeholderImage:info.avatarImage];
    self.nickLabel.text = info.showName;
    self.navigationItem.title = info.showName;
    self.userIdLabel.text = [NSString stringWithFormat:@"@%@",info.infoId];
    
    NIMRobot *robot = [[NIMSDK sharedSDK].robotManager robotInfo:self.userId];
    self.introLabel.text = robot.intro;
    CGSize size = [self.introLabel sizeThatFits:CGSizeMake(self.introLabel.width, CGFLOAT_MAX)];
    self.introLabel.size = size;
}


- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    CGSize size = [self.chatButton sizeThatFits:CGSizeMake(self.view.width, CGFLOAT_MAX)];
    self.chatButton.size = size;
    self.chatButton.centerX = self.view.width * .5f;
    self.chatButton.bottom  = self.view.height - 30.f;
    
    self.introLabel.centerX = self.view.width * .5f;
}

@end
