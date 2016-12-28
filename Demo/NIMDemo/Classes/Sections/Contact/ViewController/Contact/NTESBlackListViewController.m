//
//  NTESBlackListViewController.m
//  NIM
//
//  Created by chris on 15/8/18.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESBlackListViewController.h"
#import "NTESUserListCell.h"
#import "UIView+Toast.h"
#import "NIMContactSelectViewController.h"
#import "NTESListHeader.h"
#import "UIView+NTES.h"
#import "NTESPersonalCardViewController.h"
#import "NTESContactDataMember.h"
#import "SVProgressHUD.h"

@interface NTESBlackListViewController ()<UITableViewDataSource,UITableViewDelegate,NIMContactSelectDelegate,NTESListHeaderDelegate,NTESUserListCellDelegate>

@property (nonatomic,strong) NSMutableArray *data;

@property (nonatomic,strong) NTESListHeader *header;

@end

@implementation NTESBlackListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpNavItem];
    self.data = self.myBlackListUser;
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.header = [[NTESListHeader alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 0)];
    self.header.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.header.delegate = self;
    [self.header refreshWithType:ListHeaderTypeCommonText value:@"你不会接收到列表中联系人的任何消息"];
    [self.view addSubview:self.header];
}


- (void)setUpNavItem{
    self.navigationItem.title = @"黑名单";
    UIButton *teamBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [teamBtn addTarget:self action:@selector(onOpera:) forControlEvents:UIControlEventTouchUpInside];
    [teamBtn setImage:[UIImage imageNamed:@"icon_tinfo_normal"] forState:UIControlStateNormal];
    [teamBtn setImage:[UIImage imageNamed:@"icon_tinfo_pressed"] forState:UIControlStateHighlighted];
    [teamBtn sizeToFit];
    UIBarButtonItem *teamItem = [[UIBarButtonItem alloc] initWithCustomView:teamBtn];
    self.navigationItem.rightBarButtonItem = teamItem;
}


- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    [self refreshSubviews];
}



- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 60.f;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identity = @"cell";
    NTESUserListCell *cell = [tableView dequeueReusableCellWithIdentifier:identity];
    if (!cell) {
        cell = [[NTESUserListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identity];
        cell.delegate = self;
    }
    ContactDataMember *member = self.data[indexPath.row];
    [cell refreshWithMember:member];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    //修正ios7下可以连续点两下 indexPath可能为Nil...这里规避一下
    if (![SVProgressHUD isVisible] && editingStyle == UITableViewCellEditingStyleDelete && indexPath) {
        NSInteger index = indexPath.row;
        if (self.data.count > index) {
            NTESContactDataMember *member = self.data[indexPath.row];
            __weak typeof(self) wself = self;
            [SVProgressHUD show];
            [[NIMSDK sharedSDK].userManager removeFromBlackBlackList:member.info.infoId completion:^(NSError *error) {
                [SVProgressHUD dismiss];
                if (!error) {
                    [wself.data removeObjectAtIndex:indexPath.row];
                    [wself.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                }else{
                    [wself.view makeToast:@"删除失败"duration:2.0f position:CSToastPositionCenter];
                }
            }];
        }
    }
}


- (void)onOpera:(id)sender{
    NSMutableArray *users = [[NSMutableArray alloc] init];
    for (NTESContactDataMember *member in self.data) {
        [users addObject:member.info.infoId];
    }
    NIMContactFriendSelectConfig *config = [[NIMContactFriendSelectConfig alloc] init];
    config.filterIds = users;
    NIMContactSelectViewController *vc = [[NIMContactSelectViewController alloc] initWithConfig:config];
    vc.delegate = self;
    [vc show];
}


#pragma mark - NTESContactSelectDelegate
- (void)didFinishedSelect:(NSArray *)selectedContacts{
    if (selectedContacts.count) {
        __weak typeof(self) wself = self;
        [[NIMSDK sharedSDK].userManager addToBlackList:selectedContacts.firstObject completion:^(NSError *error) {
            if (!error) {
                [wself.view makeToast:@"操作成功！" duration:2.0 position:CSToastPositionCenter];
                wself.data = wself.myBlackListUser;
                [wself.tableView reloadData];
            }else{
                [wself.view makeToast:@"操作失败！" duration:2.0 position:CSToastPositionCenter];
            }
        }];
    }
}

#pragma mark - NTESUserListCellDelegate
- (void)didTouchUserListAvatar:(NSString *)userId{
    NTESPersonalCardViewController *vc = [[NTESPersonalCardViewController alloc] initWithUserId:userId];
    [self.navigationController pushViewController:vc animated:YES];
}


#pragma mark - Private
- (void)refreshSubviews{
    self.tableView.top = self.header.height;
    self.tableView.height = self.view.height - self.tableView.top;
    self.header.bottom    = self.tableView.top + self.tableView.contentInset.top;
}

- (NSMutableArray *)myBlackListUser{
    NSMutableArray *list = [[NSMutableArray alloc] init];
    for (NIMUser *user in [NIMSDK sharedSDK].userManager.myBlackList) {
        NTESContactDataMember *member = [[NTESContactDataMember alloc] init];
        NIMKitInfo *info = [[NIMKit sharedKit] infoByUser:user.userId option:nil];
        member.info = info;
        [list addObject:member];
    }
    return list;
}

@end
