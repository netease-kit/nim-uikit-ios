//
//  NTESPersonCardViewController.m
//  NIM
//
//  Created by chris on 15/8/18.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESPersonalCardViewController.h"
#import "NIMCommonTableDelegate.h"
#import "NIMCommonTableData.h"
#import "UIView+Toast.h"
#import "SVProgressHUD.h"
#import "NTESColorButtonCell.h"
#import "UIView+NTES.h"
#import "NTESSessionViewController.h"
#import "NTESBundleSetting.h"
#import "UIAlertView+NTESBlock.h"
#import "NTESUserUtil.h"
#import "NTESUserInfoSettingViewController.h"
#import "NTESAliasSettingViewController.h"

@interface NTESPersonalCardViewController ()<NIMUserManagerDelegate>

@property (nonatomic,strong) NIMCommonTableDelegate *delegator;

@property (nonatomic,copy  ) NSArray                 *data;

@property (nonatomic,copy  ) NSString                *userId;

@property (nonatomic,strong) NIMUser                 *user;

@property (nonatomic,strong) UILongPressGestureRecognizer *longPressGesture;

@end

@implementation NTESPersonalCardViewController

- (instancetype)initWithUserId:(NSString *)userId{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _userId = userId;
    }
    return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NIMSDK sharedSDK].userManager removeDelegate:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpNav];
    
    [[NIMSDK sharedSDK].userManager addDelegate:self];
    

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
    [self refresh];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPressNavbar:)];
    [self.navigationController.navigationBar addGestureRecognizer:self.longPressGesture];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar removeGestureRecognizer:self.longPressGesture];
}

- (void)setUpNav{
    self.navigationItem.title = @"个人名片";
    if ([self.userId isEqualToString:[[NIMSDK sharedSDK].loginManager currentAccount]]) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"编辑" style:UIBarButtonItemStyleDone target:self action:@selector(onActionEditMyInfo:)];
        self.navigationItem.rightBarButtonItem.tintColor = [UIColor blackColor];
    }
}

- (void)refresh{
    self.user = [[NIMSDK sharedSDK].userManager userInfo:self.userId];
    [self buildData];
    [self.tableView reloadData];
}


- (void)buildData{
    BOOL isMe          = [self.userId isEqualToString:[NIMSDK sharedSDK].loginManager.currentAccount];
    BOOL isMyFriend    = [[NIMSDK sharedSDK].userManager isMyFriend:self.userId];
    BOOL isInBlackList = [[NIMSDK sharedSDK].userManager isUserInBlackList:self.userId];
    BOOL needNotify    = [[NIMSDK sharedSDK].userManager notifyForNewMsg:self.userId];
    NSArray *data = @[
                        @{
                          HeaderTitle:@"",
                          RowContent :@[
                                           @{
                                              ExtraInfo     : self.userId.length ? self.user.userId : [NSNull null],
                                              CellClass     : @"NTESCardPortraitCell",
                                              RowHeight     : @(100),
                                            },
                                       ],
                          FooterTitle:@""
                          },
                        @{
                            HeaderTitle:@"",
                            RowContent :@[
                                           @{
                                                Title        : @"备注名",
                                                DetailTitle  : self.user.alias.length ? self.user.alias : @"",
                                                CellAction   : @"onActionEditAlias:",
                                                ShowAccessory: @(YES),
                                                Disable      : @(!isMyFriend),
                                            },
                                            @{
                                                Title        : @"生日",
                                                DetailTitle  : self.user.userInfo.birth.length ? self.user.userInfo.birth : @"",
                                                Disable      : @(!self.user.userInfo.birth.length),
                                             },
                                            @{
                                                Title        : @"手机",
                                                DetailTitle  : self.user.userInfo.mobile.length ? self.user.userInfo.mobile : @"",
                                                Disable      : @(!self.user.userInfo.mobile.length),
                                             },
                                            @{
                                                Title        : @"邮箱",
                                                DetailTitle  : self.user.userInfo.email.length ? self.user.userInfo.email : @"",
                                                Disable      : @(!self.user.userInfo.email.length),
                                             },
                                            @{
                                                Title        : @"签名",
                                                DetailTitle  : self.user.userInfo.sign.length ? self.user.userInfo.sign : @"",
                                                Disable      : @(!self.user.userInfo.sign.length),
                                             },
                                          ],
                            FooterTitle:@""
                            },
                         @{
                            HeaderTitle:@"",
                            RowContent :@[
                                    @{
                                        Title        : @"消息提醒",
                                        CellClass    : @"NTESSettingSwitcherCell",
                                        CellAction   : @"onActionNeedNotifyValueChange:",
                                        ExtraInfo    : @(needNotify),
                                        Disable      : @(isMe),
                                        ForbidSelect : @(YES)
                                        },
                                    ],
                            FooterTitle:@""
                            },
                          @{
                            HeaderTitle:@"",
                            RowContent :@[
                                           @{
                                                Title        : @"黑名单",
                                                CellClass    : @"NTESSettingSwitcherCell",
                                                CellAction   : @"onActionBlackListValueChange:",
                                                ExtraInfo    : @(isInBlackList),
                                                Disable      : @(isMe),
                                                ForbidSelect : @(YES)
                                            },
                                    ],
                            FooterTitle:@""
                            },
                          @{
                            HeaderTitle:@"",
                            RowContent :@[
                                    @{
                                        Title        : @"聊天",
                                        CellClass    : @"NTESColorButtonCell",
                                        CellAction   : @"chat",
                                        ExtraInfo    : @(ColorButtonCellStyleBlue),
                                        Disable      : @(isMe),
                                        RowHeight    : @(60),
                                        ForbidSelect : @(YES),
                                        SepLeftEdge  : @(self.view.width),
                                        },
                                    @{
                                        Title        : @"删除好友",
                                        CellClass    : @"NTESColorButtonCell",
                                        CellAction   : @"deleteFriend",
                                        ExtraInfo    : @(ColorButtonCellStyleRed),
                                        Disable      : @(!isMyFriend || isMe),
                                        RowHeight    : @(60),
                                        ForbidSelect : @(YES),
                                        SepLeftEdge  : @(self.view.width),
                                        },
                                    @{
                                        Title        : @"添加好友",
                                        CellClass    : @"NTESColorButtonCell",
                                        CellAction   : @"addFriend",
                                        ExtraInfo    : @(ColorButtonCellStyleBlue),
                                        Disable      : @(isMyFriend  || isMe),
                                        RowHeight    : @(60),
                                        ForbidSelect : @(YES),
                                        SepLeftEdge  : @(self.view.width),
                                        },
                                    ],
                            FooterTitle:@"",
                            },
                      ];
    self.data = [NIMCommonTableSection sectionsWithData:data];
}

#pragma mark - Action
- (void)onActionEditAlias:(id)sender{
    NTESAliasSettingViewController *vc = [[NTESAliasSettingViewController alloc] initWithUserId:self.userId];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onActionEditMyInfo:(id)sender{
    NTESUserInfoSettingViewController *vc = [[NTESUserInfoSettingViewController alloc] initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onActionBlackListValueChange:(id)sender{
    UISwitch *switcher = sender;
    [SVProgressHUD show];
    __weak typeof(self) wself = self;
    if (switcher.on) {
        [[NIMSDK sharedSDK].userManager addToBlackList:self.userId completion:^(NSError *error) {
            [SVProgressHUD dismiss];
            if (!error) {
                [wself.view makeToast:@"拉黑成功"duration:2.0f position:CSToastPositionCenter];
            }else{
                [wself.view makeToast:@"拉黑失败"duration:2.0f position:CSToastPositionCenter];
                [wself refresh];
            }
        }];
    }else{
        [[NIMSDK sharedSDK].userManager removeFromBlackBlackList:self.userId completion:^(NSError *error) {
            [SVProgressHUD dismiss];
            if (!error) {
                [wself.view makeToast:@"移除黑名单成功"duration:2.0f position:CSToastPositionCenter];
            }else{
                [wself.view makeToast:@"移除黑名单失败"duration:2.0f position:CSToastPositionCenter];
                [wself refresh];
            }
        }];
    }
}

- (void)onActionNeedNotifyValueChange:(id)sender{
    UISwitch *switcher = sender;
    [SVProgressHUD show];
    __weak typeof(self) wself = self;
    [[NIMSDK sharedSDK].userManager updateNotifyState:switcher.on forUser:self.userId completion:^(NSError *error) {            [SVProgressHUD dismiss];
        if (error) {
            [wself.view makeToast:@"操作失败"duration:2.0f position:CSToastPositionCenter];
            [wself refresh];
        }
    }];
}


- (void)chat{
    UINavigationController *nav = self.navigationController;
    NIMSession *session = [NIMSession session:self.userId type:NIMSessionTypeP2P];
    NTESSessionViewController *vc = [[NTESSessionViewController alloc] initWithSession:session];
    [nav pushViewController:vc animated:YES];
    UIViewController *root = nav.viewControllers[0];
    nav.viewControllers = @[root,vc];
}

- (void)addFriend{
    NIMUserRequest *request = [[NIMUserRequest alloc] init];
    request.userId = self.userId;
    request.operation = NIMUserOperationAdd;
    if ([[NTESBundleSetting sharedConfig] needVerifyForFriend]) {
        request.operation = NIMUserOperationRequest;
        request.message = @"跪求通过";
    }
    NSString *successText = request.operation == NIMUserOperationAdd ? @"添加成功" : @"请求成功";
    NSString *failedText =  request.operation == NIMUserOperationAdd ? @"添加失败" : @"请求失败";
    
    __weak typeof(self) wself = self;
    [SVProgressHUD show];
    [[NIMSDK sharedSDK].userManager requestFriend:request completion:^(NSError *error) {
        [SVProgressHUD dismiss];
        if (!error) {
            [wself.view makeToast:successText
                         duration:2.0f
                         position:CSToastPositionCenter];
            [wself refresh];
        }else{
            [wself.view makeToast:failedText
                         duration:2.0f
                         position:CSToastPositionCenter];
        }
    }];
}

- (void)deleteFriend{
    __weak typeof(self) wself = self;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"删除好友" message:@"删除好友后，将同时解除双方的好友关系" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    [alert showAlertWithCompletionHandler:^(NSInteger index) {
        if (index == 1) {
            [SVProgressHUD show];
            [[NIMSDK sharedSDK].userManager deleteFriend:wself.userId completion:^(NSError *error) {
                [SVProgressHUD dismiss];
                if (!error) {
                    [wself.view makeToast:@"删除成功"duration:2.0f position:CSToastPositionCenter];
                    [wself refresh];
                }else{
                    [wself.view makeToast:@"删除失败"duration:2.0f position:CSToastPositionCenter];
                }
            }];
        }
    }];
}


#pragma mark - NIMUserManagerDelegate

- (void)onUserInfoChanged:(NIMUser *)user
{
    if ([user.userId isEqualToString:self.userId]) {
        [self refresh];
    }
}

- (void)onFriendChanged:(NIMUser *)user{
    if ([user.userId isEqualToString:self.userId]) {
        [self refresh];
    }
}

- (void)onBlackListChanged{
    [self refresh];
}

- (void)onMuteListChanged
{
    [self refresh];
}


#pragma mark - Private 
- (void)onLongPressNavbar:(UIGestureRecognizer *)gesture{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        NSString *title = self.user.description;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"个人信息" message:title delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
    }
}

#pragma mark - 旋转处理 (iOS7)
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.tableView reloadData];
}

@end
