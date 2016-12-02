//
//  NTESGenderSettingViewController.m
//  NIM
//
//  Created by chris on 15/9/17.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESGenderSettingViewController.h"
#import "NIMCommonTableDelegate.h"
#import "NIMCommonTableData.h"
#import "SVProgressHUD.h"
#import "UIView+Toast.h"

@interface NTESGenderSettingViewController ()

@property (nonatomic,strong) NIMCommonTableDelegate *delegator;

@property (nonatomic,copy  ) NSArray                 *data;

@property (nonatomic,assign) NIMUserGender           selectedGender;

@end

@implementation NTESGenderSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpNav];
    NSString *userId = [[NIMSDK sharedSDK].loginManager currentAccount];
    self.selectedGender = [[NIMSDK sharedSDK].userManager userInfo:userId].userInfo.gender;
    [self buildData];
    __weak typeof(self) wself = self;
    self.delegator = [[NIMCommonTableDelegate alloc] initWithTableData:^NSArray *{
        return wself.data;
    }];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
    self.tableView.backgroundColor = UIColorFromRGB(0xe3e6ea);
    self.tableView.separatorStyle  = UITableViewCellSeparatorStyleNone;
    self.tableView.delegate   = self.delegator;
    self.tableView.dataSource = self.delegator;
}

- (void)setUpNav{
    self.navigationItem.title = @"性别";
}


- (void)buildData{
    NSArray *data = @[
                      @{
                          HeaderTitle:@"",
                          RowContent :@[
                                  @{
                                      Title         : @"男",
                                      CellClass     : @"NTESSettingCheckCell",
                                      RowHeight     : @(50),
                                      CellAction    : @"onTouchMaleCell:",
                                      ExtraInfo     : @(self.selectedGender == NIMUserGenderMale),
                                      ForbidSelect  : @(YES),
                                      },
                                  @{
                                      Title         : @"女",
                                      CellClass     : @"NTESSettingCheckCell",
                                      RowHeight     : @(50),
                                      CellAction    : @"onTouchFemaleCell:",
                                      ExtraInfo     : @(self.selectedGender == NIMUserGenderFemale),
                                      ForbidSelect  : @(YES),
                                      },
                                  @{
                                      Title         : @"其他",
                                      CellClass     : @"NTESSettingCheckCell",
                                      CellAction    : @"onTouchUnkownGenderCell:",
                                      RowHeight     : @(50),
                                      ExtraInfo     : @(self.selectedGender == NIMUserGenderUnknown),
                                      ForbidSelect  : @(YES),
                                      },
                                  ],
                          },
                      ];
    self.data = [NIMCommonTableSection sectionsWithData:data];
}

- (void)refresh{
    [self buildData];
    [self.tableView reloadData];
}

- (void)onTouchMaleCell:(id)sender{
    self.selectedGender = NIMUserGenderMale;
    [self remoteUpdateGender];
    [self refresh];
}

- (void)onTouchFemaleCell:(id)sender{
    self.selectedGender = NIMUserGenderFemale;
    [self remoteUpdateGender];
    [self refresh];
}

- (void)onTouchUnkownGenderCell:(id)sender{
    self.selectedGender = NIMUserGenderUnknown;
    [self remoteUpdateGender];
    [self refresh];
}

- (void)remoteUpdateGender{
    [SVProgressHUD show];
    __weak typeof(self) wself = self;
    [[NIMSDK sharedSDK].userManager updateMyUserInfo:@{@(NIMUserInfoUpdateTagGender) : @(self.selectedGender)} completion:^(NSError *error) {
        [SVProgressHUD dismiss];
        if (!error) {
            UINavigationController *nav = wself.navigationController;
            [nav.view makeToast:@"性别设置成功"
                       duration:2
                       position:CSToastPositionCenter];
            [nav popViewControllerAnimated:YES];

        }else{
            NSString *userId = [[NIMSDK sharedSDK].loginManager currentAccount];
            wself.selectedGender = [[NIMSDK sharedSDK].userManager userInfo:userId].userInfo.gender;
            [wself.view makeToast:@"性别设置失败，请重试"
                         duration:2
                         position:CSToastPositionCenter];
            [wself refresh];
        }
    }];
}

#pragma mark - 旋转处理 (iOS7)
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.tableView reloadData];
}

@end
